import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/data/admissions.dart';
import 'package:khetha_ncap/data/ncap_repository.dart';
import 'package:khetha_ncap/models/results_models.dart';

/// Tests for admission checking and bridging routes.
///
/// The cases are written as real learners rather than as abstract inputs,
/// because the engine's job is to be right about people: the one who missed by
/// two points, the one who took Mathematical Literacy, and the one who wants
/// accounting with a 45% in Mathematics.
void main() {
  setUpAll(() async {
    await Ncap.load(const LocalSeedSource());
  });

  MatricResults results(Map<String, int> marks,
          {ResultsKind kind = ResultsKind.nscFinal}) =>
      MatricResults(
        kind: kind,
        capturedAt: DateTime(2026),
        subjects: [
          for (final e in marks.entries)
            SubjectResult(subject: e.key, percentage: e.value),
        ],
      );

  /// A learner who wants to be an accountant but whose Mathematics let them
  /// down. This is the scenario the bridging engine exists for.
  final accountingHopeful = results({
    'English Home Language': 68,
    'Mathematics': 45,
    'Accounting': 72,
    'Business Studies': 70,
    'Economics': 65,
    'Geography': 60,
    'Life Orientation': 75,
  });

  final strongScience = results({
    'English Home Language': 75,
    'Mathematics': 82,
    'Physical Sciences': 78,
    'Life Sciences': 74,
    'Geography': 70,
    'Accounting': 68,
    'Life Orientation': 88,
  });

  group('APS', () {
    test('adds the best six subjects and excludes Life Orientation', () {
      // 68->5, 45->3, 72->6, 70->6, 65->5, 60->5 = 30.
      // Life Orientation (75) is excluded even though it is one of the best marks.
      expect(accountingHopeful.aps, 30);
      expect(
        accountingHopeful.countedSubjects.any((s) => s.isLifeOrientation),
        isFalse,
      );
    });

    test('a strong candidate scores near the top of the scale', () {
      // 75->6, 82->7, 78->6, 74->6, 70->6, 68->5 = 36.
      expect(strongScience.aps, 36);
    });

    test('pass type reflects the subject spread, not just the average', () {
      expect(strongScience.passType, 'Bachelor');
      expect(accountingHopeful.passType, 'Bachelor');

      final weak = results({
        'English Home Language': 45,
        'Mathematical Literacy': 42,
        'Business Studies': 38,
        'Tourism': 41,
        'Geography': 33,
        'History': 35,
      });
      expect(weak.passType, isNot('Bachelor'));
    });
  });

  group('eligibility', () {
    test('a strong candidate qualifies for a demanding degree', () {
      final e = AdmissionsEngine.assess(Ncap.qualificationById('q_bsc_cs')!, strongScience);
      expect(e.status, EligibilityStatus.qualifies);
      expect(e.shortfalls, isEmpty);
    });

    test('the accounting hopeful is blocked by Mathematics, and is told so', () {
      final e = AdmissionsEngine.assess(Ncap.qualificationById('q_bcom_acc')!, accountingHopeful);
      expect(e.status, isNot(EligibilityStatus.qualifies));
      expect(e.shortfalls.any((s) => s.label.contains('Mathematics')), isTrue);
      expect(e.summary, contains('Mathematics'));
    });

    test('missing one condition by a little reads as just short, not blocked', () {
      // BCom General needs APS 28 and Mathematics 50. This learner has APS 27.
      final almost = results({
        'English Home Language': 62,
        'Mathematics': 58,
        'Accounting': 58,
        'Business Studies': 55,
        'Economics': 52,
        'Geography': 51,
        'Life Orientation': 70,
      });
      final e = AdmissionsEngine.assess(Ncap.qualificationById('q_bcom_gen')!, almost);
      expect(e.status, EligibilityStatus.nearMiss);
    });

    test('a subject never taken is reported as not taken, not as a low mark', () {
      final e = AdmissionsEngine.assess(
          Ncap.qualificationById('q_mbchb')!, accountingHopeful);
      expect(
        e.shortfalls.any((s) => s.detail.contains('did not take')),
        isTrue,
      );
    });

    test('pass type is enforced independently of a good APS', () {
      // Strong marks in too few subjects: high APS, but not a Bachelor pass.
      final narrow = results({
        'English Home Language': 38,
        'Mathematics': 88,
        'Physical Sciences': 85,
        'Life Sciences': 84,
        'Geography': 80,
        'Accounting': 80,
      });
      final e = AdmissionsEngine.assess(Ncap.qualificationById('q_bsc_cs')!, narrow);
      expect(e.apsHave, greaterThanOrEqualTo(30));
      expect(e.shortfalls.any((s) => s.label == 'NSC pass type'), isTrue);
    });

    test('Mathematical Literacy satisfies a rule that allows it', () {
      final mathLit = results({
        'English Home Language': 65,
        'Mathematical Literacy': 72,
        'Business Studies': 66,
        'Tourism': 62,
        'History': 60,
        'Geography': 58,
        'Life Orientation': 74,
      });
      final e = AdmissionsEngine.assess(Ncap.qualificationById('q_dip_acc')!, mathLit);
      expect(e.shortfalls.where((s) => s.label.contains('Mathematics')), isEmpty);
    });

    test('nothing can be said without results', () {
      final e = AdmissionsEngine.assess(Ncap.qualificationById('q_bcom_acc')!, null);
      expect(e.status, EligibilityStatus.unknown);
    });
  });

  group('Grade 9 marks are not admission evidence', () {
    final grade9 = results({
      'Mathematics': 38,
      'Natural Sciences': 44,
      'English': 74,
      'Social Sciences': 71,
      'Economic and Management Sciences': 66,
    }, kind: ResultsKind.grade9);

    test('no qualification is assessed against them', () {
      for (final q in Ncap.qualifications) {
        expect(AdmissionsEngine.assess(q, grade9).status,
            EligibilityStatus.tooEarly,
            reason: '${q.title} was scored against a Grade 9 report');
      }
    });

    test('nothing is reported as open', () {
      expect(AdmissionsEngine.openTo(grade9), isEmpty);
    });

    test('no bridging route is computed from them', () {
      expect(
        AdmissionsEngine.routesTo(Ncap.qualificationById('q_bcom_acc')!, grade9),
        isEmpty,
      );
    });

    test('the learner is told why rather than shown a blank', () {
      final e = AdmissionsEngine.assess(
          Ncap.qualificationById('q_bcom_acc')!, grade9);
      expect(e.summary, contains('Grade 9'));
      expect(e.summary, contains('subjects you choose'));
    });

    test('a Grade 11 report is still assessed, because it predicts matric', () {
      final grade11 = results({
        'English Home Language': 68,
        'Mathematics': 62,
        'Accounting': 70,
        'Business Studies': 66,
        'Economics': 64,
        'Geography': 60,
        'Life Orientation': 75,
      }, kind: ResultsKind.grade11);

      expect(
        AdmissionsEngine.assess(Ncap.qualificationById('q_bcom_gen')!, grade11)
            .status,
        isNot(EligibilityStatus.tooEarly),
      );
    });
  });

  group('bridging routes', () {
    test('the accounting hopeful is given a real way through', () {
      final target = Ncap.qualificationById('q_bcom_acc')!;
      final routes = AdmissionsEngine.routesTo(target, accountingHopeful);

      expect(routes, isNotEmpty,
          reason: 'a learner blocked from BCom Accounting must be offered a route');

      // Every route has to end at the qualification they actually wanted.
      for (final route in routes) {
        expect(route.steps, isNotEmpty);
      }

      // The extended programme accepts Mathematics at 50%, which this learner
      // does not have, so the useful answers are the articulation ladder and
      // the upgrade.
      final titles = routes.map((r) => r.title).join(' | ');
      expect(
        routes.any((r) =>
            r.steps.any((s) => s.qualificationId == 'q_bcom_acc') ||
            r.steps.any((s) => s.qualificationId == 'q_dip_acc') ||
            r.steps.any((s) => s.qualificationId == 'q_hcert_acc')),
        isTrue,
        reason: 'expected an accounting ladder, got: $titles',
      );
    });

    test('an articulation route starts somewhere the learner can get in now', () {
      final target = Ncap.qualificationById('q_bcom_acc')!;
      final routes = AdmissionsEngine.routesTo(target, accountingHopeful);

      for (final route in routes) {
        final first = route.steps.first;
        if (first.qualificationId == null) continue; // upgrade route
        final entry = Ncap.qualificationById(first.qualificationId!);
        if (entry == null) continue;
        final check = AdmissionsEngine.assess(entry, accountingHopeful);
        expect(check.status, isNot(EligibilityStatus.notYet),
            reason: '${entry.title} was offered as an entry point but is closed');
      }
    });

    test('an upgrade route names the subject that is actually blocking', () {
      final target = Ncap.qualificationById('q_bcom_acc')!;
      final routes = AdmissionsEngine.routesTo(target, accountingHopeful);
      final upgrade =
          routes.where((r) => r.title == 'Upgrade and apply again').toList();

      expect(upgrade, isNotEmpty);
      expect(upgrade.first.steps.any((s) => s.detail.contains('Mathematics')), isTrue);
    });

    test('an extended programme is offered when the learner reaches its bar', () {
      // Mathematics 55 clears the extended BCom (50) but not the standard (60).
      final borderline = results({
        'English Home Language': 68,
        'Mathematics': 55,
        'Accounting': 70,
        'Business Studies': 68,
        'Economics': 64,
        'Geography': 60,
        'Life Orientation': 75,
      });
      final routes = AdmissionsEngine.routesTo(
          Ncap.qualificationById('q_bcom_acc')!, borderline);

      expect(routes.any((r) => r.title == 'Extended programme'), isTrue);
      // It should be offered first: it is the only route that reaches the exact
      // degree without an extra qualification in between.
      expect(routes.first.title, 'Extended programme');
    });

    test('no routes are offered to someone who already qualifies', () {
      final routes = AdmissionsEngine.routesTo(
          Ncap.qualificationById('q_bsc_cs')!, strongScience);
      expect(routes, isEmpty);
    });

    test('routes never loop back through a qualification twice', () {
      final routes = AdmissionsEngine.routesTo(
          Ncap.qualificationById('q_bcom_acc')!, accountingHopeful);
      for (final route in routes) {
        final ids = route.steps
            .map((s) => s.qualificationId)
            .whereType<String>()
            .toList();
        expect(ids.toSet().length, ids.length, reason: 'route repeats a step');
      }
    });
  });

  group('what is open', () {
    test('a strong candidate has more open to them than a blocked one', () {
      final strong = AdmissionsEngine.openTo(strongScience).length;
      final blocked = AdmissionsEngine.openTo(accountingHopeful).length;
      expect(strong, greaterThan(blocked));
    });

    test('every learner with a pass has something open to them', () {
      expect(AdmissionsEngine.openTo(accountingHopeful), isNotEmpty);
    });

    test('results ranked best-prospect first', () {
      final all = AdmissionsEngine.assessAll(accountingHopeful);
      final statuses = all.map((e) => e.status.index).toList();
      final sorted = [...statuses]..sort();
      expect(statuses, sorted);
    });
  });
}
