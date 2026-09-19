import '../models/career_models.dart';
import '../models/results_models.dart';
import 'ncap_repository.dart';

/// How ready a learner is for an FET-phase subject, from their Grade 9 marks.
///
/// Named distinctly from the career-side `Readiness` in `intelligence.dart`:
/// that one measures subjects against an occupation, this one measures a
/// learner against a subject they have not taken yet.
enum SubjectReadiness { strong, viable, risky, notAdvised }

extension SubjectReadinessMeta on SubjectReadiness {
  String get label => switch (this) {
        SubjectReadiness.strong => 'Strong choice',
        SubjectReadiness.viable => 'Doable',
        SubjectReadiness.risky => 'Risky',
        SubjectReadiness.notAdvised => 'Not advised',
      };
}

/// A recommendation about one Grade 10 subject.
class SubjectAdvice {
  final String subject;
  final SubjectReadiness readiness;
  final String reason;

  /// The Grade 9 subject the judgement rests on, so the learner can see why.
  final String basedOn;
  final int? basedOnMark;

  /// True when this subject is required by the career the learner is aiming at.
  final bool neededForGoal;

  const SubjectAdvice({
    required this.subject,
    required this.readiness,
    required this.reason,
    required this.basedOn,
    this.basedOnMark,
    this.neededForGoal = false,
  });
}

/// Subject choice advice for a Grade 9 learner.
///
/// Grade 9 is where the real decision happens. A learner who takes Mathematical
/// Literacy in Grade 10 has closed engineering, medicine, actuarial science and
/// accounting before they have heard of any of them, and nobody tells them that
/// at the time. This is the part of the app that tells them.
class SubjectAdvisor {
  /// Which Grade 9 subject predicts readiness for each FET subject, and the
  /// mark at which it becomes a sensible bet.
  static const _prerequisites = <String, (String, int)>{
    'Mathematics': ('Mathematics', 60),
    'Mathematical Literacy': ('Mathematics', 0),
    'Physical Sciences': ('Natural Sciences', 55),
    'Life Sciences': ('Natural Sciences', 50),
    'Agricultural Sciences': ('Natural Sciences', 45),
    'Accounting': ('Economic and Management Sciences', 55),
    'Business Studies': ('Economic and Management Sciences', 45),
    'Economics': ('Economic and Management Sciences', 55),
    'Geography': ('Social Sciences', 45),
    'History': ('Social Sciences', 45),
    'Information Technology': ('Mathematics', 60),
    'Computer Applications Technology': ('Technology', 45),
    'Engineering Graphics and Design': ('Technology', 50),
    'Electrical Technology': ('Technology', 55),
    'Civil Technology': ('Technology', 50),
    'Mechanical Technology': ('Technology', 55),
    'Visual Arts': ('Creative Arts', 50),
    'Design': ('Creative Arts', 50),
    'Dramatic Arts': ('Creative Arts', 45),
    'Music': ('Creative Arts', 55),
    'Consumer Studies': ('Technology', 40),
    'Tourism': ('Social Sciences', 40),
    'Hospitality Studies': ('Technology', 40),
  };

  /// Every learner takes these, so they are stated rather than recommended.
  static const compulsory = <String>[
    'A home language',
    'A first additional language',
    'Life Orientation',
    'Mathematics or Mathematical Literacy',
  ];

  /// Advice on each elective, given Grade 9 marks and where the learner wants
  /// to end up.
  static List<SubjectAdvice> advise({
    required MatricResults grade9,
    Career? goal,
  }) {
    final needed = <String>{};
    if (goal != null) {
      needed
        ..addAll(goal.requiredSubjects)
        ..addAll(goal.helpfulSubjects);
    }

    final advice = <SubjectAdvice>[];

    for (final entry in _prerequisites.entries) {
      final subject = entry.key;
      final (basis, threshold) = entry.value;
      final mark = grade9.markFor(basis);

      final isNeeded = needed.any((n) =>
          n.toLowerCase().contains(subject.toLowerCase()) ||
          subject.toLowerCase().contains(n.toLowerCase()));

      if (subject == 'Mathematical Literacy') {
        final maths = grade9.markFor('Mathematics');
        advice.add(SubjectAdvice(
          subject: subject,
          readiness: maths == null
              ? SubjectReadiness.viable
              : maths >= 60
                  ? SubjectReadiness.notAdvised
                  : maths >= 45
                      ? SubjectReadiness.risky
                      : SubjectReadiness.viable,
          reason: maths == null
              ? 'Add your Mathematics mark to get a view on this.'
              : maths >= 60
                  ? 'You are getting $maths% in Mathematics. Taking Mathematical Literacy instead would close engineering, health sciences, accounting and IT for no reason.'
                  : maths >= 45
                      ? 'At $maths% pure Mathematics is still within reach with support, and it keeps far more doors open. Mathematical Literacy is the safer pass but the narrower future.'
                      : 'At $maths% this is the realistic choice. Be aware it closes engineering, health sciences and most finance degrees.',
          basedOn: 'Mathematics',
          basedOnMark: maths,
          neededForGoal: isNeeded,
        ));
        continue;
      }

      final readiness = mark == null
          ? SubjectReadiness.viable
          : mark >= threshold + 12
              ? SubjectReadiness.strong
              : mark >= threshold
                  ? SubjectReadiness.viable
                  : mark >= threshold - 10
                      ? SubjectReadiness.risky
                      : SubjectReadiness.notAdvised;

      advice.add(SubjectAdvice(
        subject: subject,
        readiness: readiness,
        reason: mark == null
            ? 'No $basis mark yet, so this is a guess.'
            : switch (readiness) {
                SubjectReadiness.strong =>
                  'Your $basis mark of $mark% is well clear of what this subject asks for.',
                SubjectReadiness.viable =>
                  'Your $basis mark of $mark% is enough to take this on.',
                SubjectReadiness.risky =>
                  'At $mark% in $basis this would be hard work. Possible with help, difficult without.',
                SubjectReadiness.notAdvised =>
                  'At $mark% in $basis this would likely pull your whole matric down.',
              },
        basedOn: basis,
        basedOnMark: mark,
        neededForGoal: isNeeded,
      ));
    }

    // Subjects the goal needs come first, then the strongest bets.
    advice.sort((a, b) {
      if (a.neededForGoal != b.neededForGoal) return a.neededForGoal ? -1 : 1;
      return a.readiness.index.compareTo(b.readiness.index);
    });

    return advice;
  }

  /// A concrete three-elective package, which is what the learner actually has
  /// to choose. Advice on twenty subjects is not a decision.
  static List<SubjectAdvice> recommendPackage({
    required MatricResults grade9,
    Career? goal,
    String? field,
  }) {
    final all = advise(grade9: grade9, goal: goal);

    // Anything the goal requires and the learner can carry goes in first.
    final package = <SubjectAdvice>[];
    for (final a in all) {
      if (package.length >= 3) break;
      if (!a.neededForGoal) continue;
      if (a.readiness == SubjectReadiness.notAdvised) continue;
      if (a.subject == 'Mathematical Literacy') continue;
      package.add(a);
    }

    // Fill the rest from the field the learner picked, then from raw strength.
    final fieldSubjects = field == null ? const <String>[] : Ncap.subjects[field] ?? const [];
    for (final a in all) {
      if (package.length >= 3) break;
      if (package.contains(a)) continue;
      if (a.readiness == SubjectReadiness.notAdvised || a.readiness == SubjectReadiness.risky) {
        continue;
      }
      if (a.subject == 'Mathematical Literacy') continue;
      if (!fieldSubjects.any((s) => s.contains(a.subject))) continue;
      package.add(a);
    }

    for (final a in all) {
      if (package.length >= 3) break;
      if (package.contains(a)) continue;
      if (a.readiness != SubjectReadiness.strong && a.readiness != SubjectReadiness.viable) {
        continue;
      }
      if (a.subject == 'Mathematical Literacy') continue;
      package.add(a);
    }

    return package;
  }

  /// Subjects a goal needs that the learner's marks do not currently support.
  /// These are the ones worth getting a tutor for.
  static List<SubjectAdvice> blockers({
    required MatricResults grade9,
    required Career goal,
  }) =>
      advise(grade9: grade9, goal: goal)
          .where((a) =>
              a.neededForGoal &&
              (a.readiness == SubjectReadiness.risky ||
                  a.readiness == SubjectReadiness.notAdvised))
          .toList();

  /// The learner's strongest Grade 9 subjects, which is usually the first
  /// genuinely useful thing anyone has told them about themselves.
  static List<SubjectResult> strengths(MatricResults grade9) {
    final sorted = grade9.subjects
        .where((s) => !s.isLifeOrientation)
        .toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    return sorted.take(3).toList();
  }
}
