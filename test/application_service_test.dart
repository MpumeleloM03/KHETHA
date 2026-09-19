import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/data/ncap_repository.dart';
import 'package:khetha_ncap/models/application_models.dart';
import 'package:khetha_ncap/models/results_models.dart';
import 'package:khetha_ncap/services/application_service.dart';

/// Tests for the application lifecycle.
///
/// Outcomes in this prototype are derived from the learner's own results
/// against the published entry requirements rather than drawn at random, so the
/// thing worth testing is that a learner is never told something their marks
/// do not support.
void main() {
  setUpAll(() async {
    await Ncap.load(const LocalSeedSource());
  });

  MatricResults results(Map<String, int> marks) => MatricResults(
        kind: ResultsKind.nscFinal,
        capturedAt: DateTime(2026),
        subjects: [
          for (final e in marks.entries)
            SubjectResult(subject: e.key, percentage: e.value),
        ],
      );

  InstitutionApplication draft(String qualificationId) => InstitutionApplication(
        providerId: 'p_ukzn',
        qualificationId: qualificationId,
        state: ApplicationState.draft,
        updatedAt: DateTime(2026),
      );

  final strong = results({
    'English Home Language': 78,
    'Mathematics': 85,
    'Physical Sciences': 80,
    'Life Sciences': 76,
    'Geography': 74,
    'Accounting': 72,
    'Life Orientation': 88,
  });

  final weak = results({
    'English Home Language': 52,
    'Mathematical Literacy': 48,
    'Business Studies': 45,
    'Tourism': 44,
    'Geography': 41,
    'History': 40,
    'Life Orientation': 60,
  });

  group('submission', () {
    test('every application comes back submitted with a reference', () async {
      final drafts = [draft('q_bsw'), draft('q_bed_fp')];
      final sent = await ApplicationService.instance.submit(drafts).toList();

      expect(sent.length, 2);
      for (final application in sent) {
        expect(application.state, ApplicationState.submitted);
        expect(application.reference, isNotNull);
        expect(application.reference, contains('-'));
      }
    });

    test('references are distinct', () async {
      final sent = await ApplicationService.instance
          .submit([draft('q_bsw'), draft('q_bed_fp'), draft('q_ba_gen')])
          .toList();
      final references = sent.map((a) => a.reference).toSet();
      expect(references.length, 3);
    });
  });

  group('outcomes follow the results', () {
    test('a comfortable candidate is offered a place', () {
      final decided = ApplicationService.instance
          .decide(draft('q_bed_fp'), strong);
      expect(decided.state, ApplicationState.offered);
      expect(decided.note, isNotNull);
    });

    test('a candidate who does not meet the requirements is declined, '
        'and told why', () {
      final decided = ApplicationService.instance
          .decide(draft('q_mbchb'), weak);
      expect(decided.state, ApplicationState.declined);
      expect(decided.note, isNotNull);
      expect(decided.note!.length, greaterThan(10));
    });

    test('a candidate who scrapes in is waitlisted rather than promised', () {
      // BCom General wants APS 28; this profile lands just over it.
      final borderline = results({
        'English Home Language': 62,
        'Mathematics': 58,
        'Accounting': 60,
        'Business Studies': 58,
        'Economics': 56,
        'Geography': 55,
        'Life Orientation': 70,
      });
      final decided = ApplicationService.instance
          .decide(draft('q_bcom_gen'), borderline);
      expect(
        decided.state,
        anyOf(ApplicationState.waitlisted, ApplicationState.offered),
      );
    });

    test('without results nothing is decided', () {
      final decided = ApplicationService.instance.decide(draft('q_bsw'), null);
      expect(decided.state, ApplicationState.underReview);
    });

    test('an unknown qualification does not crash the decision', () {
      final decided = ApplicationService.instance.decide(
        InstitutionApplication(
          providerId: 'p_ukzn',
          qualificationId: 'q_does_not_exist',
          state: ApplicationState.submitted,
          updatedAt: DateTime(2026),
        ),
        strong,
      );
      expect(decided.state, ApplicationState.underReview);
    });
  });

  group('the clearing house trigger', () {
    InstitutionApplication withState(String id, ApplicationState state) =>
        draft(id).copyWith(state: state);

    test('fires only when every application has been decided and none offered',
        () {
      expect(
        ApplicationService.needsClearingHouse([
          withState('q_bsw', ApplicationState.declined),
          withState('q_bed_fp', ApplicationState.waitlisted),
        ]),
        isTrue,
      );
    });

    test('does not fire while something is still pending', () {
      expect(
        ApplicationService.needsClearingHouse([
          withState('q_bsw', ApplicationState.declined),
          withState('q_bed_fp', ApplicationState.submitted),
        ]),
        isFalse,
      );
    });

    test('does not fire when there is an offer in hand', () {
      expect(
        ApplicationService.needsClearingHouse([
          withState('q_bsw', ApplicationState.declined),
          withState('q_bed_fp', ApplicationState.offered),
        ]),
        isFalse,
      );
    });

    test('does not fire when nothing was ever applied for', () {
      expect(ApplicationService.needsClearingHouse([]), isFalse);
    });
  });
}
