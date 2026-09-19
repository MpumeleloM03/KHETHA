import '../models/career_models.dart';

/// The outcome of a completed Interest Profiler run.
///
/// Carries the two vectors the matching engine needs plus three diagnostics
/// about the *quality* of the response set. Those diagnostics exist so the app
/// can tell a learner when their own answers do not support a confident
/// result, instead of dressing up noise as insight.
class InterestProfileResult {
  /// Mean response per dimension, already 0..1.
  final Map<Riasec, double> riasec;

  /// Work-style tags, counted from the top two anchors only.
  final Map<String, int> traits;

  /// Distance between the strongest and weakest dimension.
  ///
  /// A flat profile means the instrument did not separate anything. Below
  /// about 0.20 the ranking that follows is close to arbitrary.
  final double spread;

  /// Mean response across every item. Near the extremes it suggests the
  /// learner agreed, or disagreed, with almost everything.
  final double mean;

  /// True when almost every answer was the same anchor.
  final bool straightLined;

  /// How many items were actually answered.
  final int answered;

  const InterestProfileResult({
    required this.riasec,
    required this.traits,
    required this.spread,
    required this.mean,
    required this.straightLined,
    required this.answered,
  });

  /// Whether the result is separated enough to rank careers on.
  ///
  /// Not a pass mark for the learner - a statement about whether this
  /// particular set of answers carries usable signal.
  bool get isDiscriminating => !straightLined && spread >= 0.20;

  /// The three strongest dimensions, highest first - the Holland code.
  List<Riasec> get topThree {
    final sorted = riasec.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }
}

/// Scores a completed Interest Profiler run.
///
/// [answers] is the selected option per question, in question order - the shape
/// the quiz runner already produces.
///
/// Two deliberate choices, both of which change the result:
///
/// Dimension scores are the *mean* response on that dimension's items, not the
/// sum. Cosine similarity does not care, being scale-invariant, but the profile
/// is also averaged against other questionnaires and rendered directly as a
/// chart. A 0..1 mean is the only form that is correct for all three uses.
///
/// Trait points are awarded only at the top two anchors. The work-style part of
/// the matching engine normalises against the learner's own strongest traits,
/// so a learner who answers "it's okay" to all thirty items would otherwise end
/// up with a flat trait map that scores ~1.0 against every career in the
/// dataset - a confident-looking match built on no preference at all.
InterestProfileResult scoreInterestProfiler(
  List<QuizQuestion> questions,
  List<QuizOption> answers,
) {
  final sums = <Riasec, double>{for (final d in Riasec.values) d: 0.0};
  final counts = <Riasec, int>{for (final d in Riasec.values) d: 0};
  final traits = <String, int>{};
  final anchorTally = <double, int>{};
  var grandTotal = 0.0;
  var answered = 0;

  final limit = answers.length < questions.length
      ? answers.length
      : questions.length;

  for (var i = 0; i < limit; i++) {
    final dimension = questions[i].dimension;
    if (dimension == null) continue; // not a Likert item

    final answer = answers[i];
    sums[dimension] = sums[dimension]! + answer.weight;
    counts[dimension] = counts[dimension]! + 1;
    grandTotal += answer.weight;
    anchorTally[answer.weight] = (anchorTally[answer.weight] ?? 0) + 1;
    answered++;

    final points = answer.weight >= 1.0
        ? 2
        : answer.weight >= 0.75
            ? 1
            : 0;
    if (points > 0) {
      for (final trait in answer.traits) {
        traits[trait] = (traits[trait] ?? 0) + points;
      }
    }
  }

  final riasec = <Riasec, double>{};
  for (final d in Riasec.values) {
    final n = counts[d]!;
    riasec[d] = n == 0 ? 0.0 : sums[d]! / n;
  }

  final values = riasec.values.toList()..sort();
  final spread = values.isEmpty ? 0.0 : values.last - values.first;
  final mean = answered == 0 ? 0.0 : grandTotal / answered;

  // Straight-lining: the same anchor for nearly everything. Scaled to the
  // number actually answered so a partial run is judged on its own length.
  final longestRun = anchorTally.values.isEmpty
      ? 0
      : anchorTally.values.reduce((a, b) => a > b ? a : b);
  final straightLined = answered >= 10 && longestRun >= (answered * 0.85);

  return InterestProfileResult(
    riasec: riasec,
    traits: traits,
    spread: spread,
    mean: mean,
    straightLined: straightLined,
    answered: answered,
  );
}
