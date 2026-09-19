import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/data/interest_scoring.dart';
import 'package:khetha_ncap/data/seed_interest_profiler.dart';
import 'package:khetha_ncap/models/career_models.dart';

/// Tests for Interest Profiler scoring.
///
/// The cases that matter are the degenerate ones. A learner who taps the same
/// answer thirty times, or who likes everything equally, must not come out the
/// other side with a confident-looking career ranking — that is the specific
/// way an instrument like this lies to people.
void main() {
  const anchors = [0.0, 0.25, 0.5, 0.75, 1.0];

  /// Builds a balanced 30-item instrument, 5 per dimension, interleaved.
  List<QuizQuestion> instrument() {
    final questions = <QuizQuestion>[];
    for (var block = 0; block < 5; block++) {
      for (final dim in Riasec.values) {
        questions.add(QuizQuestion(
          id: '${dim.name}$block',
          question: 'activity',
          dimension: dim,
          section: block ~/ 2,
          options: [
            for (final w in anchors)
              QuizOption(
                label: 'a',
                weight: w,
                riasec: {dim: w},
                traits: w >= 0.75 ? ['tag-${dim.name}'] : const [],
              ),
          ],
        ));
      }
    }
    return questions;
  }

  /// Answers every item at [weight], or per-dimension when [byDimension] given.
  List<QuizOption> answerAll(
    List<QuizQuestion> qs, {
    double weight = 0.5,
    Map<Riasec, double>? byDimension,
  }) =>
      [
        for (final q in qs)
          q.options.firstWhere((o) =>
              o.weight == (byDimension?[q.dimension] ?? weight)),
      ];

  group('a differentiated learner', () {
    test('scores highest on the dimension they endorsed', () {
      final qs = instrument();
      final answers = answerAll(qs, byDimension: {
        Riasec.realistic: 1.0,
        Riasec.investigative: 0.75,
        Riasec.artistic: 0.25,
        Riasec.social: 0.0,
        Riasec.enterprising: 0.25,
        Riasec.conventional: 0.5,
      });

      final r = scoreInterestProfiler(qs, answers);

      expect(r.riasec[Riasec.realistic], 1.0);
      expect(r.riasec[Riasec.social], 0.0);
      expect(r.topThree.first, Riasec.realistic);
      expect(r.answered, 30);
      expect(r.isDiscriminating, isTrue);
    });

    test('dimension scores are means, so every dimension is comparable', () {
      final qs = instrument();
      final r = scoreInterestProfiler(qs, answerAll(qs, weight: 0.75));
      for (final d in Riasec.values) {
        expect(r.riasec[d], closeTo(0.75, 1e-9),
            reason: '$d was summed rather than averaged');
      }
    });

    test('every score stays inside 0..1', () {
      final qs = instrument();
      final r = scoreInterestProfiler(qs, answerAll(qs, weight: 1.0));
      for (final v in r.riasec.values) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('degenerate response sets are caught', () {
    test('answering the same thing throughout is flagged', () {
      final qs = instrument();
      for (final w in anchors) {
        final r = scoreInterestProfiler(qs, answerAll(qs, weight: w));
        expect(r.straightLined, isTrue, reason: 'anchor $w not detected');
        expect(r.isDiscriminating, isFalse);
      }
    });

    test('liking everything produces no usable ranking', () {
      final qs = instrument();
      final r = scoreInterestProfiler(qs, answerAll(qs, weight: 1.0));
      expect(r.spread, 0.0);
      expect(r.isDiscriminating, isFalse,
          reason: 'a flat maximum profile must not read as a strong result');
    });

    test('a barely-separated profile is not treated as a result', () {
      final qs = instrument();
      final r = scoreInterestProfiler(qs, answerAll(qs, byDimension: {
        Riasec.realistic: 0.75,
        Riasec.investigative: 0.75,
        Riasec.artistic: 0.75,
        Riasec.social: 0.75,
        Riasec.enterprising: 0.75,
        Riasec.conventional: 0.5,
      }));
      expect(r.spread, closeTo(0.25, 1e-9));
      expect(r.straightLined, isFalse, reason: 'not actually straight-lined');
      expect(r.isDiscriminating, isTrue);
    });
  });

  group('trait points', () {
    test('are awarded only at the top two anchors', () {
      final qs = instrument();
      expect(scoreInterestProfiler(qs, answerAll(qs, weight: 0.5)).traits,
          isEmpty,
          reason: '"it\'s okay" must not build a work-style profile');
      expect(scoreInterestProfiler(qs, answerAll(qs, weight: 0.75)).traits,
          isNotEmpty);
    });

    test('"would love it" is worth double "would like it"', () {
      final qs = instrument();
      final liked = scoreInterestProfiler(qs, answerAll(qs, weight: 0.75));
      final loved = scoreInterestProfiler(qs, answerAll(qs, weight: 1.0));
      for (final key in liked.traits.keys) {
        expect(loved.traits[key], liked.traits[key]! * 2);
      }
    });
  });

  group('partial and malformed runs', () {
    test('a learner who quits halfway still gets a scored profile', () {
      final qs = instrument();
      final answers = answerAll(qs, weight: 1.0).take(12).toList();
      final r = scoreInterestProfiler(qs, answers);

      expect(r.answered, 12);
      // The interleaving guarantees two of every dimension by item 12.
      for (final d in Riasec.values) {
        expect(r.riasec[d], 1.0, reason: '$d was missed by item 12');
      }
    });

    test('no answers does not divide by zero', () {
      final r = scoreInterestProfiler(instrument(), const []);
      expect(r.answered, 0);
      expect(r.mean, 0.0);
      expect(r.spread, 0.0);
      expect(r.straightLined, isFalse);
    });

    test('non-Likert questions are skipped rather than miscounted', () {
      final qs = [
        const QuizQuestion(
          id: 'legacy',
          question: 'old categorical item',
          options: [QuizOption(label: 'a')],
        ),
        ...instrument(),
      ];
      final answers = [
        const QuizOption(label: 'a'),
        ...answerAll(instrument(), weight: 1.0),
      ];
      final r = scoreInterestProfiler(qs, answers);
      expect(r.answered, 30, reason: 'the legacy item was counted');
    });
  });

  group('the real instrument', () {
    test('is 30 items, balanced five per dimension', () {
      expect(interestProfilerQuestions.length, 30);

      final perDimension = <Riasec, int>{};
      for (final q in interestProfilerQuestions) {
        expect(q.dimension, isNotNull, reason: '${q.id} has no dimension');
        perDimension[q.dimension!] = (perDimension[q.dimension!] ?? 0) + 1;
      }
      for (final d in Riasec.values) {
        expect(perDimension[d], 5, reason: '$d is not balanced');
      }
    });

    test('is interleaved, so quitting early still covers every dimension', () {
      // The design promise: two of each dimension by item 12.
      final seen = <Riasec, int>{};
      for (final q in interestProfilerQuestions.take(12)) {
        seen[q.dimension!] = (seen[q.dimension!] ?? 0) + 1;
      }
      for (final d in Riasec.values) {
        expect(seen[d], greaterThanOrEqualTo(2),
            reason: '$d is under-covered in the first 12 items');
      }
    });

    test('every item offers the five anchors, weighted 0 to 1', () {
      for (final q in interestProfilerQuestions) {
        expect(q.options.length, 5, reason: '${q.id}');
        expect(q.options.map((o) => o.weight).toList(),
            [0.0, 0.25, 0.5, 0.75, 1.0],
            reason: '${q.id} anchors are wrong');
        // The item loads on exactly one dimension.
        for (final o in q.options) {
          expect(o.riasec.keys.toList(), [q.dimension], reason: '${q.id}');
        }
      }
    });

    test('traits tag only the top two anchors', () {
      for (final q in interestProfilerQuestions) {
        for (final o in q.options) {
          if (o.weight >= 0.75) {
            expect(o.traits, isNotEmpty, reason: '${q.id} @ ${o.weight}');
          } else {
            expect(o.traits, isEmpty, reason: '${q.id} @ ${o.weight}');
          }
        }
      }
    });

    test('items only use traits the career dataset actually scores on', () {
      // A trait tag that no career carries is dead weight in the match engine.
      const known = {
        'analytical', 'problem-solver', 'hands-on', 'organised',
        'people-person', 'caring', 'creative', 'outdoors',
      };
      for (final q in interestProfilerQuestions) {
        for (final o in q.options) {
          for (final t in o.traits) {
            expect(known, contains(t), reason: '${q.id} uses unknown trait "$t"');
          }
        }
      }
    });

    test('items are short enough to read on a phone', () {
      for (final q in interestProfilerQuestions) {
        final words = q.question.trim().split(RegExp(r'\s+')).length;
        expect(words, lessThanOrEqualTo(14),
            reason: '${q.id} is $words words: "${q.question}"');
      }
    });

    test('items are unique', () {
      final texts = interestProfilerQuestions.map((q) => q.question).toSet();
      expect(texts.length, 30, reason: 'a duplicate item slipped in');
      final ids = interestProfilerQuestions.map((q) => q.id).toSet();
      expect(ids.length, 30);
    });

    test('sections are three blocks of ten', () {
      expect(sectionTitles.length, 3);
      expect(sectionSize, 10);
      final perSection = <int, int>{};
      for (final q in interestProfilerQuestions) {
        perSection[q.section ?? 0] = (perSection[q.section ?? 0] ?? 0) + 1;
      }
      expect(perSection, {0: 10, 1: 10, 2: 10});
    });

    test('scores end to end against the real items', () {
      final answers = [
        for (final q in interestProfilerQuestions)
          q.options.firstWhere(
            (o) => o.weight == (q.dimension == Riasec.realistic ? 1.0 : 0.25),
          ),
      ];
      final r = scoreInterestProfiler(interestProfilerQuestions, answers);
      expect(r.topThree.first, Riasec.realistic);
      expect(r.isDiscriminating, isTrue);
      expect(r.traits, isNotEmpty);
    });
  });
}
