import '../models/results_models.dart';

/// Turns the lines a recogniser returned into subjects and marks.
///
/// Kept as pure Dart, separate from the platform channel, so the hard part —
/// reading a badly photographed results slip - can be tested without a camera.
class ResultsParser {
  /// National Senior Certificate subjects, in the spelling DBE uses.
  ///
  /// The canonical list does the heavy lifting: OCR mangles characters, so
  /// matching against a known vocabulary recovers far more rows than trying to
  /// interpret whatever text came back on its own.
  static const canonicalSubjects = <String>[
    'English Home Language',
    'English First Additional Language',
    'Afrikaans Home Language',
    'Afrikaans First Additional Language',
    'isiZulu Home Language',
    'isiZulu First Additional Language',
    'isiXhosa Home Language',
    'isiXhosa First Additional Language',
    'Sesotho Home Language',
    'Setswana Home Language',
    'Sepedi Home Language',
    'Xitsonga Home Language',
    'Tshivenda Home Language',
    'siSwati Home Language',
    'isiNdebele Home Language',
    'Mathematics',
    'Mathematical Literacy',
    'Technical Mathematics',
    'Physical Sciences',
    'Technical Sciences',
    'Life Sciences',
    'Agricultural Sciences',
    'Geography',
    'History',
    'Accounting',
    'Business Studies',
    'Economics',
    'Information Technology',
    'Computer Applications Technology',
    'Engineering Graphics and Design',
    'Electrical Technology',
    'Mechanical Technology',
    'Civil Technology',
    'Visual Arts',
    'Design',
    'Dramatic Arts',
    'Music',
    'Consumer Studies',
    'Hospitality Studies',
    'Tourism',
    'Life Orientation',
  ];

  /// Subjects a Grade 9 learner is reported on, for the subject-choice flow.
  static const grade9Subjects = <String>[
    'English',
    'Mathematics',
    'Natural Sciences',
    'Social Sciences',
    'Economic and Management Sciences',
    'Technology',
    'Life Orientation',
    'Creative Arts',
    'Second Language',
  ];

  static ScanOutcome parse(List<String> lines, {required String engine, required double confidence}) {
    final found = <String, SubjectResult>{};
    final unparsed = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final subject = _matchSubject(line);

      if (subject == null) {
        if (_looksMeaningful(line)) unparsed.add(line);
        continue;
      }

      // Marks usually sit on the same row as the subject. When the layout puts
      // them in a separate column that Vision reads as its own line, the next
      // line is checked before the row is given up on.
      var mark = _extractMark(line);
      if (mark == null && i + 1 < lines.length) {
        mark = _extractMark(lines[i + 1], numbersOnly: true);
      }

      if (mark == null) {
        unparsed.add(line);
        continue;
      }

      // A results statement can list the same subject twice (for example a
      // supplementary result). The later row wins, which is the corrected one.
      found[subject] = SubjectResult(
        subject: subject,
        percentage: mark,
        fromScan: true,
        confidence: confidence,
      );
    }

    return ScanOutcome(
      subjects: found.values.toList(),
      confidence: confidence,
      engine: engine,
      unparsedLines: unparsed,
    );
  }

  /// Finds which canonical subject a line is naming, tolerating OCR damage.
  static String? _matchSubject(String line) {
    final cleaned = _normalise(line);
    if (cleaned.length < 4) return null;

    String? best;
    var bestScore = 0.0;

    for (final subject in canonicalSubjects) {
      final target = _normalise(subject);

      // A clean substring hit is the common case and is trusted immediately,
      // with the longest match winning so "English Home Language" is not
      // beaten by a bare "English".
      if (cleaned.contains(target)) {
        final score = 1 + target.length / 100;
        if (score > bestScore) {
          bestScore = score;
          best = subject;
        }
        continue;
      }

      final score = _similarity(cleaned, target);
      if (score > bestScore && score >= 0.78) {
        bestScore = score;
        best = subject;
      }
    }

    return best;
  }

  /// Pulls the percentage out of a row.
  ///
  /// A results row typically carries both a percentage and a 1–7 achievement
  /// level, so a lone number under 8 is treated as the level and ignored when
  /// a larger candidate exists.
  static int? _extractMark(String line, {bool numbersOnly = false}) {
    final matches = RegExp(r'\d{1,3}').allMatches(line).toList();
    if (matches.isEmpty) return null;

    if (numbersOnly) {
      // Only accept a follow-on line if it is essentially just numbers,
      // otherwise a subject code on the next row gets read as a mark.
      final withoutDigits = line.replaceAll(RegExp(r'[\d\s%|]'), '');
      if (withoutDigits.length > 2) return null;
    }

    final candidates = matches
        .map((m) => int.tryParse(m.group(0)!))
        .whereType<int>()
        .where((n) => n >= 0 && n <= 100)
        .toList();

    if (candidates.isEmpty) return null;

    // Prefer a plausible percentage over an achievement level.
    final percentages = candidates.where((n) => n > 7).toList();
    if (percentages.isNotEmpty) {
      return percentages.reduce((a, b) => a > b ? a : b);
    }

    // Everything is 7 or under: the row may genuinely be a low mark, or it may
    // be only a level. Levels are far more common in that position, so the
    // level is converted to the middle of its percentage band.
    final level = candidates.reduce((a, b) => a > b ? a : b);
    return _levelToPercentage(level);
  }

  static int _levelToPercentage(int level) => switch (level) {
        7 => 85,
        6 => 75,
        5 => 65,
        4 => 55,
        3 => 45,
        2 => 35,
        _ => 20,
      };

  static String _normalise(String value) {
    return value
        .toUpperCase()
        // OCR routinely swaps these; folding them removes most of the noise.
        .replaceAll('0', 'O')
        .replaceAll('1', 'I')
        .replaceAll('5', 'S')
        .replaceAll(RegExp(r'[^A-Z ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Similarity on a 0..1 scale, from normalised Levenshtein distance.
  static double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;

    // Compare against the window of `a` closest in length to `b`, so a long
    // row with extra columns still matches the subject inside it.
    final haystack = a.length > b.length + 6 ? a.substring(0, b.length + 6) : a;

    final distance = _levenshtein(haystack, b);
    final longest = haystack.length > b.length ? haystack.length : b.length;
    return 1 - (distance / longest);
  }

  static int _levenshtein(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    var current = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        final deletion = previous[j + 1] + 1;
        final insertion = current[j] + 1;
        final substitution = previous[j] + cost;
        var best = deletion < insertion ? deletion : insertion;
        if (substitution < best) best = substitution;
        current[j + 1] = best;
      }
      final swap = previous;
      previous = current;
      current = swap;
    }

    return previous[b.length];
  }

  /// Filters out page furniture so the "could not read" list stays short and
  /// actually points at rows worth correcting.
  static bool _looksMeaningful(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 6) return false;
    if (RegExp(r'^[\d\s\-/.:]+$').hasMatch(trimmed)) return false;

    const furniture = [
      'national senior certificate',
      'department of basic education',
      'umalusi',
      'republic of south africa',
      'statement of results',
      'candidate',
      'examination',
      'subject',
      'achievement',
      'percentage',
      'level',
      'issued',
      'school',
      'centre',
    ];
    final lower = trimmed.toLowerCase();
    return !furniture.any(lower.contains);
  }
}
