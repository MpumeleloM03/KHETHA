// Models for school results, the APS they produce, and what a scan returned.

/// Which certificate a set of results belongs to. The rules that matter —
/// which subjects count, what a pass means - differ between them.
enum ResultsKind { grade9, grade11, nscFinal, nscTerm }

extension ResultsKindMeta on ResultsKind {
  String get label => switch (this) {
        ResultsKind.grade9 => 'Grade 9 report',
        ResultsKind.grade11 => 'Grade 11 report',
        ResultsKind.nscFinal => 'Final NSC (matric) certificate',
        ResultsKind.nscTerm => 'Grade 12 term report',
      };

  /// Only the final NSC decides admission. Everything else is an estimate, and
  /// the app says so rather than letting a learner bank on a term mark.
  bool get isProvisional => this != ResultsKind.nscFinal;

  /// Whether these marks can be scored against entry requirements at all.
  ///
  /// A Grade 9 report cannot: APS is built from the 1-7 NSC achievement levels
  /// over matric subjects, and a Grade 9 learner has not taken any. Running the
  /// calculation anyway would hand a fourteen-year-old an APS and a pass type
  /// that mean nothing, which is worse than showing them nothing.
  bool get countsTowardsAdmission => this != ResultsKind.grade9;
}

/// One subject and the mark achieved in it.
class SubjectResult {
  final String subject;
  final int percentage;

  /// True when this row came from OCR rather than being typed by the learner.
  /// Used to show what still needs checking.
  final bool fromScan;

  /// OCR confidence for the row, 0..1. Null for manually entered rows.
  final double? confidence;

  const SubjectResult({
    required this.subject,
    required this.percentage,
    this.fromScan = false,
    this.confidence,
  });

  /// The National Senior Certificate achievement level, 1–7.
  int get level => switch (percentage) {
        >= 80 => 7,
        >= 70 => 6,
        >= 60 => 5,
        >= 50 => 4,
        >= 40 => 3,
        >= 30 => 2,
        _ => 1,
      };

  String get levelDescription => switch (level) {
        7 => 'Outstanding',
        6 => 'Meritorious',
        5 => 'Substantial',
        4 => 'Adequate',
        3 => 'Moderate',
        2 => 'Elementary',
        _ => 'Not achieved',
      };

  /// Life Orientation is excluded from the APS at most institutions, so it is
  /// flagged on the record rather than being special-cased at every call site.
  bool get isLifeOrientation =>
      subject.toLowerCase().contains('life orientation');

  /// Rows the learner should look at before relying on the result.
  bool get needsChecking => fromScan && (confidence ?? 1) < 0.7;

  SubjectResult copyWith({String? subject, int? percentage}) => SubjectResult(
        subject: subject ?? this.subject,
        percentage: percentage ?? this.percentage,
        fromScan: fromScan,
        confidence: confidence,
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'percentage': percentage,
        'fromScan': fromScan,
        'confidence': confidence,
      };

  static SubjectResult? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final subject = raw['subject'];
    final percentage = raw['percentage'];
    if (subject is! String || percentage is! num) return null;
    final confidence = raw['confidence'];
    return SubjectResult(
      subject: subject,
      percentage: percentage.toInt().clamp(0, 100),
      fromScan: raw['fromScan'] == true,
      confidence: confidence is num ? confidence.toDouble() : null,
    );
  }
}

/// A complete set of results plus the APS they produce.
class MatricResults {
  final ResultsKind kind;
  final List<SubjectResult> subjects;
  final DateTime capturedAt;

  /// How the results got into the app - used on screen so a learner knows
  /// whether the app read them or they typed them.
  final String source;

  const MatricResults({
    required this.kind,
    required this.subjects,
    required this.capturedAt,
    this.source = 'Entered by hand',
  });

  /// Admission Point Score.
  ///
  /// The common South African rule: convert each subject to its 1–7
  /// achievement level and add the best six, excluding Life Orientation.
  /// Institutions vary - UCT and Wits run their own scales - so the app
  /// presents this as the standard estimate, not as a guarantee.
  int get aps {
    final counted = subjects.where((s) => !s.isLifeOrientation).toList()
      ..sort((a, b) => b.level.compareTo(a.level));
    return counted.take(6).fold<int>(0, (sum, s) => sum + s.level);
  }

  /// The six subjects that actually produced the APS.
  List<SubjectResult> get countedSubjects {
    final counted = subjects.where((s) => !s.isLifeOrientation).toList()
      ..sort((a, b) => b.level.compareTo(a.level));
    return counted.take(6).toList();
  }

  int get maxPossibleAps => 42;

  /// Whether the learner meets the minimum for each NSC pass type. These
  /// thresholds are what decide the door, far more than the APS does.
  bool get hasBachelorPass => _passType == 'Bachelor';
  String get passType => _passType;

  String get _passType {
    if (subjects.length < 6) return 'Incomplete';

    final home = _mark('English') ?? _mark('Afrikaans') ?? _mark('isiZulu');
    if (home == null || home < 40) return 'Not achieved';

    final nonLo = subjects.where((s) => !s.isLifeOrientation).toList();
    final at40 = nonLo.where((s) => s.percentage >= 40).length;
    final at30 = nonLo.where((s) => s.percentage >= 30).length;
    final at50 = nonLo.where((s) => s.percentage >= 50).length;

    // Bachelor: 50%+ in four subjects from the designated list, 40% in the
    // home language, 30% in two others.
    if (at50 >= 4 && at30 >= 6) return 'Bachelor';
    if (at40 >= 4 && at30 >= 6) return 'Diploma';
    if (at40 >= 2 && at30 >= 5) return 'Higher Certificate';
    return 'Not achieved';
  }

  int? _mark(String subject) {
    for (final s in subjects) {
      if (s.subject.toLowerCase().contains(subject.toLowerCase())) {
        return s.percentage;
      }
    }
    return null;
  }

  /// The mark for a named subject, honouring "X or Y" alternatives.
  int? markFor(String subject) => _mark(subject);

  List<SubjectResult> get needsChecking =>
      subjects.where((s) => s.needsChecking).toList();

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'capturedAt': capturedAt.toIso8601String(),
        'source': source,
      };

  static MatricResults? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kindName = raw['kind'];
    final kind = ResultsKind.values.where((k) => k.name == kindName);
    final subjectsRaw = raw['subjects'];
    if (subjectsRaw is! List) return null;

    final subjects = subjectsRaw
        .map(SubjectResult.fromJson)
        .whereType<SubjectResult>()
        .toList();
    if (subjects.isEmpty) return null;

    final captured = raw['capturedAt'];
    return MatricResults(
      kind: kind.isEmpty ? ResultsKind.nscFinal : kind.first,
      subjects: subjects,
      capturedAt:
          captured is String ? (DateTime.tryParse(captured) ?? DateTime.now()) : DateTime.now(),
      source: raw['source'] is String ? raw['source'] as String : 'Entered by hand',
    );
  }
}

/// What came back from a scan, before the learner has confirmed it.
class ScanOutcome {
  final List<SubjectResult> subjects;
  final double confidence;
  final String engine;

  /// Lines the parser could not turn into a subject. Shown so a learner can
  /// see the app is not silently dropping half their results.
  final List<String> unparsedLines;

  const ScanOutcome({
    required this.subjects,
    required this.confidence,
    required this.engine,
    this.unparsedLines = const [],
  });

  bool get isUsable => subjects.length >= 4;
}
