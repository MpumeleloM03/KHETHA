import 'dart:async';
import 'dart:math';

import '../data/admissions.dart';
import '../data/ncap_repository.dart';
import '../models/application_models.dart';
import '../models/results_models.dart';

/// Drives the application lifecycle.
///
/// PROTOTYPE BEHAVIOUR: no South African university or TVET college exposes a
/// public application API, so this build demonstrates submission rather than
/// transmitting anything. Outcomes are derived from the learner's own results
/// against the published entry requirements, so what the demo shows is at least
/// consistent with what the institution would decide - but no institution has
/// received anything, and every screen that shows a status says so.
class ApplicationService {
  ApplicationService._();
  static final instance = ApplicationService._();

  final _random = Random();

  /// Reference numbers follow the shape institutions actually issue, so the
  /// demo reads as real without inventing a real one.
  String _reference(String providerId) {
    final year = DateTime.now().year;
    final serial = _random.nextInt(900000) + 100000;
    final prefix = providerId.replaceAll('p_', '').toUpperCase();
    return '$prefix-$year-$serial';
  }

  /// Submits a batch, reporting progress as each institution is reached.
  ///
  /// The delay is deliberate and visible: an application going somewhere should
  /// feel like it takes a moment, and the per-institution callback is what lets
  /// the screen show a real queue rather than a spinner.
  Stream<InstitutionApplication> submit(
    List<InstitutionApplication> applications,
  ) async* {
    for (final application in applications) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      yield application.copyWith(
        state: ApplicationState.submitted,
        reference: _reference(application.providerId),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// The outcome an institution would reach on these results.
  ///
  /// Derived, not random: a learner who comfortably meets the requirements sees
  /// an offer, one who scrapes in sees a waiting list, and one who does not
  /// meet them is declined with the reason. Anything else would teach a learner
  /// the wrong lesson about their own marks.
  InstitutionApplication decide(
    InstitutionApplication application,
    MatricResults? results,
  ) {
    final qualification = Ncap.qualificationById(application.qualificationId);
    if (qualification == null || results == null) {
      return application.copyWith(
        state: ApplicationState.underReview,
        note: 'Waiting for final results.',
        updatedAt: DateTime.now(),
      );
    }

    final eligibility = AdmissionsEngine.assess(qualification, results);
    final headroom = eligibility.apsHave - eligibility.apsNeed;

    switch (eligibility.status) {
      case EligibilityStatus.qualifies:
        if (headroom >= 3) {
          return application.copyWith(
            state: ApplicationState.offered,
            note:
                'You are $headroom APS points above the minimum. Accept before the closing date to secure the place.',
            updatedAt: DateTime.now(),
          );
        }
        return application.copyWith(
          state: ApplicationState.waitlisted,
          note:
              'You meet the minimum, but only just. Places go to the strongest applicants first, so keep your other applications open.',
          updatedAt: DateTime.now(),
        );

      case EligibilityStatus.nearMiss:
        return application.copyWith(
          state: ApplicationState.waitlisted,
          note: eligibility.shortfalls.first.detail,
          updatedAt: DateTime.now(),
        );

      case EligibilityStatus.tooEarly:
        return application.copyWith(
          state: ApplicationState.underReview,
          note: 'Waiting for matric results.',
          updatedAt: DateTime.now(),
        );

      case EligibilityStatus.notYet:
      case EligibilityStatus.unknown:
        return application.copyWith(
          state: ApplicationState.declined,
          note: eligibility.shortfalls.isEmpty
              ? 'The entry requirements were not met.'
              : eligibility.shortfalls.first.detail,
          updatedAt: DateTime.now(),
        );
    }
  }

  /// Whether the learner ended up with nowhere to go, which is the trigger for
  /// the Central Applications Clearing House.
  static bool needsClearingHouse(List<InstitutionApplication> applications) {
    if (applications.isEmpty) return false;
    final decided = applications.where((a) => a.state.isFinal).toList();
    if (decided.length != applications.length) return false;
    return !decided.any((a) => a.state == ApplicationState.offered);
  }
}
