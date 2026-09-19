import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/data/ncap_repository.dart';
import 'package:khetha_ncap/data/subject_advisor.dart';
import 'package:khetha_ncap/models/results_models.dart';

/// Tests for Grade 9 subject advice.
///
/// The decision this engine informs is the one that quietly closes doors three
/// years later, so the cases below are the ones that actually matter: a learner
/// strong at Mathematics being told not to drop it, a learner weak at it being
/// told the truth about what that costs, and a learner whose goal does not fit
/// their marks being offered help rather than a refusal.
void main() {
  setUpAll(() async {
    await Ncap.load(const LocalSeedSource());
  });

  MatricResults grade9(Map<String, int> marks) => MatricResults(
        kind: ResultsKind.grade9,
        capturedAt: DateTime(2026),
        subjects: [
          for (final e in marks.entries)
            SubjectResult(subject: e.key, percentage: e.value),
        ],
      );

  final strongAtMaths = grade9({
    'Mathematics': 78,
    'Natural Sciences': 72,
    'English': 68,
    'Social Sciences': 60,
    'Economic and Management Sciences': 65,
    'Technology': 58,
  });

  final weakAtMaths = grade9({
    'Mathematics': 34,
    'Natural Sciences': 41,
    'English': 72,
    'Social Sciences': 70,
    'Economic and Management Sciences': 58,
    'Creative Arts': 75,
  });

  SubjectAdvice adviceFor(MatricResults results, String subject) =>
      SubjectAdvisor.advise(grade9: results)
          .firstWhere((a) => a.subject == subject);

  group('the Mathematics decision', () {
    test('a strong learner is warned off Mathematical Literacy', () {
      final advice = adviceFor(strongAtMaths, 'Mathematical Literacy');
      expect(advice.readiness, SubjectReadiness.notAdvised);
      expect(advice.reason, contains('close'));
    });

    test('a weak learner is told plainly what it costs', () {
      final advice = adviceFor(weakAtMaths, 'Mathematical Literacy');
      expect(advice.readiness, SubjectReadiness.viable);
      expect(advice.reason.toLowerCase(), contains('closes'));
    });

    test('a borderline learner is told it is still within reach', () {
      final borderline = grade9({'Mathematics': 52, 'English': 60});
      final advice = adviceFor(borderline, 'Mathematical Literacy');
      expect(advice.readiness, SubjectReadiness.risky);
      expect(advice.reason, contains('within reach'));
    });
  });

  group('subject readiness follows the marks', () {
    test('Physical Sciences is a strong bet for a strong scientist', () {
      expect(adviceFor(strongAtMaths, 'Physical Sciences').readiness,
          SubjectReadiness.strong);
    });

    test('Physical Sciences is not advised for a weak one', () {
      expect(adviceFor(weakAtMaths, 'Physical Sciences').readiness,
          anyOf(SubjectReadiness.risky, SubjectReadiness.notAdvised));
    });

    test('every judgement names the mark it rests on', () {
      for (final advice in SubjectAdvisor.advise(grade9: strongAtMaths)) {
        expect(advice.basedOn, isNotEmpty);
        expect(advice.reason, isNotEmpty);
      }
    });
  });

  group('the recommended package', () {
    test('is exactly three electives', () {
      final package = SubjectAdvisor.recommendPackage(grade9: strongAtMaths);
      expect(package.length, 3);
    });

    test('never recommends a subject the marks do not support', () {
      final package = SubjectAdvisor.recommendPackage(grade9: weakAtMaths);
      for (final advice in package) {
        expect(advice.readiness, isNot(SubjectReadiness.notAdvised));
      }
    });

    test('never puts Mathematical Literacy in the elective package', () {
      // It is a compulsory-slot choice, not one of the three electives.
      for (final results in [strongAtMaths, weakAtMaths]) {
        final package = SubjectAdvisor.recommendPackage(grade9: results);
        expect(package.any((a) => a.subject == 'Mathematical Literacy'), isFalse);
      }
    });

    test('prioritises what the chosen career requires', () {
      final engineer = Ncap.careerById('c_eleceng')!;
      final package = SubjectAdvisor.recommendPackage(
        grade9: strongAtMaths,
        goal: engineer,
      );
      expect(package.any((a) => a.subject == 'Physical Sciences'), isTrue,
          reason: 'an aspiring electrical engineer must be told to take '
              'Physical Sciences');
    });
  });

  group('when the goal does not fit the marks', () {
    test('blockers name the subjects standing in the way', () {
      final doctor = Ncap.careerById('c_doctor')!;
      final blockers = SubjectAdvisor.blockers(grade9: weakAtMaths, goal: doctor);

      expect(blockers, isNotEmpty,
          reason: 'a learner at 34% in Mathematics aiming at medicine has '
              'something standing in the way');
      for (final b in blockers) {
        expect(b.neededForGoal, isTrue);
        expect(b.readiness,
            anyOf(SubjectReadiness.risky, SubjectReadiness.notAdvised));
      }
    });

    test('a learner whose marks fit their goal has no blockers', () {
      final engineer = Ncap.careerById('c_eleceng')!;
      expect(SubjectAdvisor.blockers(grade9: strongAtMaths, goal: engineer),
          isEmpty);
    });
  });

  group('strengths', () {
    test('reports the three best subjects, excluding Life Orientation', () {
      final withLo = grade9({
        'Mathematics': 55,
        'English': 80,
        'Natural Sciences': 75,
        'Social Sciences': 70,
        'Life Orientation': 95,
      });
      final strengths = SubjectAdvisor.strengths(withLo);

      expect(strengths.length, 3);
      expect(strengths.any((s) => s.isLifeOrientation), isFalse);
      expect(strengths.first.subject, 'English');
    });
  });
}
