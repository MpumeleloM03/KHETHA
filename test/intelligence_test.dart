import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/data/intelligence.dart';
import 'package:khetha_ncap/data/ncap_repository.dart';
import 'package:khetha_ncap/models/career_models.dart';

/// Tests for the matching engine.
///
/// The engine decides what a learner is told to study, so the properties that
/// matter are behavioural, not cosmetic: does a stated interest actually move
/// the ranking, is a hard subject requirement enforced, and does an empty
/// profile degrade sensibly instead of producing confident nonsense.
void main() {
  setUpAll(() async {
    await Ncap.load(const LocalSeedSource());
  });

  group('dataset integrity', () {
    test('every career referenced as related actually exists', () {
      for (final career in Ncap.careers) {
        for (final id in career.relatedCareerIds) {
          expect(Ncap.careerById(id), isNotNull,
              reason: '${career.id} points at missing career $id');
        }
      }
    });

    test('every qualification leads to careers that exist', () {
      for (final qual in Ncap.qualifications) {
        for (final id in qual.leadsToCareerIds) {
          expect(Ncap.careerById(id), isNotNull,
              reason: '${qual.id} points at missing career $id');
        }
      }
    });

    test('every career sector has at least one provider offering it', () {
      for (final sector in Ncap.allSectors) {
        expect(Ncap.providersFor(sector), isNotEmpty,
            reason: 'no institution offers $sector');
      }
    });

    test('a province filter returns only institutions in that province', () {
      for (final province in ['KwaZulu-Natal', 'Limpopo', 'Northern Cape']) {
        final matches =
            Ncap.providersFor('Skilled Trades & Artisanship', province: province);
        expect(matches, isNotEmpty, reason: 'no trade provider in $province');
        for (final p in matches) {
          expect(p.province, province);
        }
      }
    });

    test('every province has at least one institution', () {
      final covered = Ncap.providers.map((p) => p.province).toSet();
      expect(covered.length, 9,
          reason: 'expected all nine provinces, found ${covered.length}');
    });

    test('every career carries an OFO code and an NQF level', () {
      for (final career in Ncap.careers) {
        expect(career.ofoCode, isNotEmpty);
        expect(career.nqfLevel, isNotEmpty);
      }
    });
  });

  group('ranking', () {
    test('an empty profile still returns results, led by scarce skills', () {
      final results = CareerIntelligence.rank(UserProfile());
      expect(results, isNotEmpty);
      expect(results.first.career.scarceSkill, isTrue);
    });

    test('a social interest profile ranks a caring occupation above a trade',
        () {
      final profile = UserProfile(
        riasecScores: {Riasec.social: 1.0, Riasec.realistic: 0.1},
        traitScores: {'caring': 3, 'people-person': 2},
      );

      final ranked = CareerIntelligence.rank(profile, limit: Ncap.careers.length);
      final nurse = ranked.indexWhere((m) => m.career.id == 'c_nurse');
      final boilermaker =
          ranked.indexWhere((m) => m.career.id == 'c_boilermaker');

      expect(nurse, lessThan(boilermaker));
    });

    test('a realistic profile ranks a trade above a desk occupation', () {
      final profile = UserProfile(
        riasecScores: {Riasec.realistic: 1.0, Riasec.social: 0.1},
        traitScores: {'hands-on': 3, 'problem-solver': 2},
      );

      final ranked = CareerIntelligence.rank(profile, limit: Ncap.careers.length);
      final electrician =
          ranked.indexWhere((m) => m.career.id == 'c_electrician');
      final accountant = ranked.indexWhere((m) => m.career.id == 'c_ca');

      expect(electrician, lessThan(accountant));
    });

    test('no career is ever reported as a perfect fit', () {
      // Deliberately maximal profile: every interest, every trait, the right
      // subjects and the declared field. It must still not read as certainty.
      final profile = UserProfile(
        riasecScores: {for (final r in Riasec.values) r: 1.0},
        traitScores: {
          'analytical': 9,
          'hands-on': 9,
          'problem-solver': 9,
          'organised': 9,
        },
        chosenSubjects: ['Mathematics', 'Physical Sciences', 'Information Technology'],
        interestField: 'Engineering & Technology',
      );
      for (final m in CareerIntelligence.rank(profile)) {
        expect(m.score, lessThanOrEqualTo(CareerIntelligence.maxScore));
        expect(m.percent, lessThan(100));
      }
    });

    test('scores stay within 0 and 1', () {
      final profile = UserProfile(
        riasecScores: {for (final r in Riasec.values) r: 1.0},
        traitScores: {'analytical': 9, 'hands-on': 9},
        chosenSubjects: ['Mathematics', 'Physical Sciences'],
        interestField: 'Engineering & Technology',
      );
      for (final m in CareerIntelligence.rank(profile)) {
        expect(m.score, inInclusiveRange(0.0, 1.0));
      }
    });

    test('every result carries evidence when the profile has input', () {
      final profile = UserProfile(
        riasecScores: {Riasec.investigative: 1.0},
        traitScores: {'analytical': 2},
      );
      for (final m in CareerIntelligence.rank(profile)) {
        expect(m.evidence, isNotEmpty);
      }
    });
  });

  group('subject requirements', () {
    test('Mathematical Literacy does not satisfy a pure Mathematics entry', () {
      final profile = UserProfile(chosenSubjects: ['Mathematical Literacy']);
      final doctor = Ncap.careerById('c_doctor')!;
      final readiness = CareerIntelligence.readiness(doctor, profile);

      expect(readiness.missing, contains('Mathematics'));
    });

    test('Mathematics satisfies an "or Mathematical Literacy" requirement', () {
      final profile = UserProfile(chosenSubjects: ['Mathematics']);
      final electrician = Ncap.careerById('c_electrician')!;
      final readiness = CareerIntelligence.readiness(electrician, profile);

      expect(readiness.missing, isEmpty);
    });

    test('meeting every required subject reports full readiness', () {
      final nurse = Ncap.careerById('c_nurse')!;
      final profile = UserProfile(chosenSubjects: nurse.requiredSubjects);
      final readiness = CareerIntelligence.readiness(nurse, profile);

      expect(readiness.percent, 100);
      expect(readiness.missing, isEmpty);
    });

    test('a learner who has chosen nothing is told to start, not failed', () {
      final readiness = CareerIntelligence.readiness(
        Ncap.careerById('c_softdev')!,
        UserProfile(),
      );
      expect(readiness.verdict, contains('Subject Chooser'));
    });
  });

  group('explanations and insights', () {
    test('an explanation names the career and is a real sentence', () {
      final profile = UserProfile(
        riasecScores: {Riasec.artistic: 1.0},
        traitScores: {'creative': 3},
        chosenSubjects: ['English', 'Visual Arts'],
      );
      final match = CareerIntelligence.rank(profile).first;
      final text = CareerIntelligence.explain(match, profile);

      expect(text, contains(match.career.title));
      expect(text.length, greaterThan(80));
    });

    test('next steps never exceed three and always offer something', () {
      expect(CareerIntelligence.nextSteps(UserProfile()).length, 3);

      final complete = UserProfile(
        chosenSubjects: ['Mathematics'],
        traitScores: {'analytical': 2},
        riasecScores: {Riasec.investigative: 1.0},
        savedFavourites: ['c_softdev'],
        completedTools: ['job_fit', 'career_choice', 'subjects'],
      );
      final steps = CareerIntelligence.nextSteps(complete);
      expect(steps, isNotEmpty);
      expect(steps.length, lessThanOrEqualTo(3));
    });
  });

  group('profile serialisation', () {
    test('a profile survives a round trip through JSON', () {
      final original = UserProfile(
        displayName: 'Thandi',
        grade: 'Grade 10',
        province: 'KwaZulu-Natal',
        interestField: 'Health Sciences',
        chosenSubjects: ['Life Sciences', 'English'],
        traitScores: {'caring': 3},
        riasecScores: {Riasec.social: 0.9},
        savedFavourites: ['c_nurse'],
        completedTools: ['job_fit'],
      );

      final restored = UserProfile.fromJson(original.toJson());

      expect(restored.displayName, 'Thandi');
      expect(restored.province, 'KwaZulu-Natal');
      expect(restored.chosenSubjects, ['Life Sciences', 'English']);
      expect(restored.riasecScores[Riasec.social], 0.9);
      expect(restored.savedFavourites, ['c_nurse']);
      expect(restored.hollandCode, 'S');
    });

    test('malformed stored data does not crash the restore', () {
      final restored = UserProfile.fromJson({
        'riasecScores': {'not_a_dimension': 1.0},
        'chosenSubjects': <String>[],
      });
      expect(restored.riasecScores, isEmpty);
      expect(restored.journeyProgress, 0);
    });
  });
}
