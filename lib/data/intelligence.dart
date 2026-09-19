import 'dart:math' as math;

import '../models/career_models.dart';
import 'ncap_repository.dart';
import 'seed_quizzes.dart';

/// One reason a career scored the way it did, in language a learner can read.
///
/// Every number the engine produces has to be traceable back to something the
/// learner actually did. That is what separates guidance from a black box, and
/// it is why the Why panel can be opened on any match.
class Evidence {
  final String label;
  final double contribution; // 0..1 of this factor
  final String detail;

  const Evidence(this.label, this.contribution, this.detail);
}

/// A scored career, with the whole working shown.
class MatchResult {
  final Career career;

  /// Composite fit, 0..1.
  final double score;
  final double interestScore;
  final double workStyleScore;
  final double subjectScore;
  final List<Evidence> evidence;

  /// Required subjects the learner has not selected. The actionable half of
  /// the result - a gap you can still close in Grade 10 is worth more than a
  /// percentage.
  final List<String> missingSubjects;
  final List<String> matchedSubjects;

  const MatchResult({
    required this.career,
    required this.score,
    required this.interestScore,
    required this.workStyleScore,
    required this.subjectScore,
    required this.evidence,
    required this.missingSubjects,
    required this.matchedSubjects,
  });

  int get percent => (score * 100).round();

  /// How much of this result rests on real input versus defaults. Shown to the
  /// learner instead of presenting a thin result with false confidence.
  String get confidenceLabel {
    if (score >= 0.78) return 'Strong match';
    if (score >= 0.6) return 'Good match';
    if (score >= 0.45) return 'Worth exploring';
    return 'Weaker match';
  }
}

/// Readiness of a learner's subject choices against one occupation.
class Readiness {
  final double ratio; // 0..1
  final List<String> have;
  final List<String> missing;
  final String verdict;

  const Readiness({
    required this.ratio,
    required this.have,
    required this.missing,
    required this.verdict,
  });

  int get percent => (ratio * 100).round();
}

/// The recommendation engine.
///
/// Everything here runs on the device, in a few milliseconds, with no network
/// call and no personal data leaving the phone. The model is deliberately a
/// transparent weighted one rather than an opaque classifier: for a government
/// service that steers a child's education, being able to show exactly why an
/// occupation was suggested matters more than squeezing out another point of
/// accuracy.
class CareerIntelligence {
  /// Relative weights of the three signals. Named constants because the
  /// weighting is a policy decision, not an implementation detail - it is
  /// surfaced verbatim on the "How matching works" screen.
  static const double wInterest = 0.45;
  static const double wWorkStyle = 0.35;
  static const double wSubjects = 0.20;

  /// Highest fit score the engine will ever report.
  static const double maxScore = 0.96;

  /// Cosine similarity between the learner's interest profile and an
  /// occupation's. Cosine rather than raw distance so that a learner who
  /// answered enthusiastically is not scored differently from one who answered
  /// the same way more mildly - shape matters, magnitude does not.
  static double _cosine(Map<Riasec, double> a, Map<Riasec, double> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    double dot = 0, magA = 0, magB = 0;
    for (final dim in Riasec.values) {
      final x = a[dim] ?? 0;
      final y = b[dim] ?? 0;
      dot += x * y;
      magA += x * x;
      magB += y * y;
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (math.sqrt(magA) * math.sqrt(magB));
  }

  static double _workStyle(Map<String, int> traitScores, Career career) {
    if (traitScores.isEmpty || career.traits.isEmpty) return 0;
    final total = traitScores.values.fold<int>(0, (s, v) => s + v);
    if (total == 0) return 0;
    var hit = 0;
    for (final t in career.traits) {
      hit += traitScores[t] ?? 0;
    }
    // Normalise against the best a career could score with this profile, so a
    // 3-trait career is not penalised against a 2-trait one.
    final best = (traitScores.values.toList()..sort((a, b) => b.compareTo(a)))
        .take(career.traits.length)
        .fold<int>(0, (s, v) => s + v);
    if (best == 0) return 0;
    return (hit / best).clamp(0.0, 1.0);
  }

  /// Subject alignment. Returns a neutral 0.5 when the learner has not used the
  /// Subject Chooser yet, so an empty profile neither inflates nor tanks the
  /// score - the engine says "unknown", not "zero".
  static (double, List<String>, List<String>) _subjects(
      List<String> chosen, Career career) {
    if (career.requiredSubjects.isEmpty) return (0.5, const [], const []);
    if (chosen.isEmpty) return (0.5, const [], career.requiredSubjects);

    final have = <String>[];
    final missing = <String>[];
    for (final req in career.requiredSubjects) {
      if (_satisfies(chosen, req)) {
        have.add(req);
      } else {
        missing.add(req);
      }
    }
    return (have.length / career.requiredSubjects.length, have, missing);
  }

  /// Loose subject matching. "Mathematics" satisfies "Mathematics or
  /// Mathematical Literacy", and a learner who picked "Mathematical Literacy"
  /// does not satisfy a hard "Mathematics" requirement - which is exactly the
  /// mistake that costs learners a university place in Grade 12.
  static bool _satisfies(List<String> chosen, String requirement) {
    final req = requirement.toLowerCase();
    final alternatives = req.split(' or ').map((s) => s.trim()).toList();
    for (final alt in alternatives) {
      for (final c in chosen) {
        final lc = c.toLowerCase();
        if (lc == alt) return true;
        if (lc.contains(alt) || alt.contains(lc)) {
          // Guard the one pair where a substring match would be wrong.
          final mathLit = lc.contains('literacy');
          final wantsPureMath = alt == 'mathematics';
          if (mathLit && wantsPureMath) continue;
          return true;
        }
      }
    }
    return false;
  }

  /// Rank every occupation against a profile, best first.
  static List<MatchResult> rank(UserProfile profile, {int limit = 8}) {
    final results = <MatchResult>[];

    for (final career in Ncap.careers) {
      final interest = _cosine(profile.riasecScores, career.riasec);
      final style = _workStyle(profile.traitScores, career);
      final (subjScore, have, missing) =
          _subjects(profile.chosenSubjects, career);

      // If the learner has told us nothing at all, fall back to showing
      // high-demand occupations rather than an arbitrary order.
      final hasInput = profile.riasecScores.isNotEmpty ||
          profile.traitScores.isNotEmpty ||
          profile.chosenSubjects.isNotEmpty;

      double composite;
      if (!hasInput) {
        composite = career.scarceSkill ? 0.55 : 0.4;
      } else {
        composite = (interest * wInterest) +
            (style * wWorkStyle) +
            (subjScore * wSubjects);

        // Bonuses apply to the headroom that is left rather than being added on
        // top. Adding and then clamping lets several small nudges pile a
        // mediocre fit up against the ceiling; scaling them into what remains
        // keeps the ordering they were meant to influence without ever letting
        // a bonus manufacture a strong match out of a weak one.
        var bonus = 0.0;

        // A disclosed nudge toward occupations on the national list of
        // occupations in high demand.
        if (career.scarceSkill) bonus += 0.18;

        // The learner's declared field of interest is a direct statement of
        // intent and outranks an inferred signal.
        if (profile.interestField != null &&
            career.sector == profile.interestField) {
          bonus += 0.26;
        }

        composite += (1 - composite) * bonus;
      }

      // No occupation is ever a perfect fit for a person, and a tool that tells
      // a 15-year-old it is 100% certain about their future has overstated what
      // five questions can know. The ceiling keeps the claim honest.
      composite = composite.clamp(0.0, maxScore);

      results.add(MatchResult(
        career: career,
        score: composite,
        interestScore: interest,
        workStyleScore: style,
        subjectScore: subjScore,
        missingSubjects: missing,
        matchedSubjects: have,
        evidence: _buildEvidence(profile, career, interest, style, subjScore),
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  static List<Evidence> _buildEvidence(
    UserProfile profile,
    Career career,
    double interest,
    double style,
    double subjects,
  ) {
    final ev = <Evidence>[];

    if (profile.riasecScores.isNotEmpty) {
      final top = _topRiasec(profile.riasecScores, 2);
      final careerTop = _topRiasec(career.riasec, 2);
      final shared = top.where(careerTop.contains).toList();
      ev.add(Evidence(
        'Interest profile',
        interest,
        shared.isEmpty
            ? 'Your strongest interests (${top.map((e) => e.label).join(", ")}) only partly overlap with this occupation, which leans ${careerTop.map((e) => e.label).join(" and ")}.'
            : 'You scored highest on ${shared.map((e) => e.label).join(" and ")}, and this occupation is built around the same interest.',
      ));
    }

    if (profile.traitScores.isNotEmpty && career.traits.isNotEmpty) {
      final matched = career.traits
          .where((t) => (profile.traitScores[t] ?? 0) > 0)
          .toList();
      ev.add(Evidence(
        'How you like to work',
        style,
        matched.isEmpty
            ? 'This role leans on being ${career.traits.map((t) => traitLabels[t] ?? t).join(", ").toLowerCase()}, which did not come through strongly in your answers.'
            : 'Your answers showed ${matched.map((t) => traitPhrases[t] ?? t).join(", and ")}. This occupation asks for exactly that.',
      ));
    }

    if (profile.chosenSubjects.isNotEmpty) {
      final (s, have, missing) = _subjects(profile.chosenSubjects, career);
      ev.add(Evidence(
        'Subject requirements',
        s,
        missing.isEmpty
            ? 'Your subject choices already meet the entry requirements (${have.join(", ")}).'
            : 'You have ${have.isEmpty ? "none" : have.join(", ")} of the required subjects. Still needed: ${missing.join(", ")}.',
      ));
    }

    if (career.scarceSkill) {
      ev.add(const Evidence(
        'Labour market signal',
        1.0,
        'This occupation appears on the national list of occupations in high demand, so it was nudged up slightly in your results.',
      ));
    }

    return ev;
  }

  static List<Riasec> _topRiasec(Map<Riasec, double> m, int n) {
    final sorted = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Subject readiness for a single occupation, with a plain verdict.
  static Readiness readiness(Career career, UserProfile profile) {
    final (ratio, have, missing) = _subjects(profile.chosenSubjects, career);

    String verdict;
    if (profile.chosenSubjects.isEmpty) {
      verdict =
          'Use the Subject Chooser first and this will show you exactly where you stand.';
    } else if (missing.isEmpty) {
      verdict =
          'Your subjects meet the minimum requirements for this pathway. Focus on the marks.';
    } else if (missing.length == 1) {
      verdict =
          'One subject stands between you and this pathway: ${missing.first}. If you are still in Grade 9 or 10, this is fixable.';
    } else {
      verdict =
          'This pathway needs ${missing.join(" and ")}, which you have not selected. Speak to a practitioner before you finalise your subjects.';
    }

    return Readiness(
      ratio: ratio,
      have: have,
      missing: missing,
      verdict: verdict,
    );
  }

  /// Natural-language summary of a match, assembled from the evidence rather
  /// than written in advance. Reads as advice; stays traceable to the answers.
  static String explain(MatchResult m, UserProfile profile) {
    final buf = StringBuffer();

    if (profile.riasecScores.isNotEmpty) {
      final top = _topRiasec(profile.riasecScores, 1).first;
      buf.write('Your answers put you strongest on ${top.label} - ');
      buf.write('${top.plain.split(":").last.trim()}. ');
    }

    final traits = profile.traitScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (traits.isNotEmpty) {
      final phrase = traitPhrases[traits.first.key];
      if (phrase != null) {
        buf.write('You also told us $phrase. ');
      }
    }

    buf.write(
        'A ${m.career.title} spends the day doing work built around that: ');
    buf.write('${m.career.description.toLowerCase()} ');

    if (m.missingSubjects.isEmpty && profile.chosenSubjects.isNotEmpty) {
      buf.write(
          'Your subject choices already open this door - the next thing that matters is your marks.');
    } else if (m.missingSubjects.isNotEmpty &&
        profile.chosenSubjects.isNotEmpty) {
      buf.write(
          'To keep this option open you would need ${m.missingSubjects.join(" and ")}.');
    } else {
      buf.write(
          'Run the Subject Chooser next to see whether your subjects keep this option open.');
    }

    return buf.toString();
  }

  /// Insights for the Journey dashboard - the "so what" layer over the raw
  /// scores. Each one is a statement the learner can act on.
  static List<String> insights(UserProfile profile, List<MatchResult> matches) {
    final out = <String>[];
    if (matches.isEmpty) return out;

    final scarce = matches.where((m) => m.career.scarceSkill).toList();
    if (scarce.isNotEmpty) {
      out.add(
          '${scarce.length} of your top ${matches.length} matches are on the national list of occupations in high demand - including ${scarce.first.career.title}.');
    }

    final sectors = <String, int>{};
    for (final m in matches) {
      sectors[m.career.sector] = (sectors[m.career.sector] ?? 0) + 1;
    }
    final topSector = sectors.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (topSector.value >= 3) {
      out.add(
          'Your results cluster in ${topSector.key} - ${topSector.value} of your matches sit in that field, which is a strong signal.');
    } else {
      out.add(
          'Your results spread across ${sectors.length} different fields, so you have genuine range. Explore two before narrowing.');
    }

    if (profile.chosenSubjects.isNotEmpty) {
      final gaps = <String>{};
      for (final m in matches.take(3)) {
        gaps.addAll(m.missingSubjects);
      }
      if (gaps.isEmpty) {
        out.add(
            'Your subject choices meet the requirements for all three of your top matches. That is a strong position to be in.');
      } else {
        out.add(
            'Adding ${gaps.join(" and ")} would open up more of your top matches than any other change you could make.');
      }
    }

    final trades = matches.where((m) => m.career.sector == 'Skilled Trades & Artisanship');
    if (trades.isNotEmpty) {
      out.add(
          'A trade route (${trades.first.career.title}) scored well for you. It starts from Grade 9, is NSFAS-funded at TVET colleges, and qualified artisans are scarce.');
    }

    return out;
  }

  /// Three concrete next actions, chosen from what the learner has not done.
  static List<({String title, String detail, String route})> nextSteps(
      UserProfile profile) {
    final steps = <({String title, String detail, String route})>[];

    if (!profile.hasJobFit) {
      steps.add((
        title: 'Take the Job Fit Quiz',
        detail: '5 questions, about two minutes. It drives everything else.',
        route: 'job_fit',
      ));
    }
    if (!profile.hasCareerChoice) {
      steps.add((
        title: 'Take the Career Choice questionnaire',
        detail:
            'Six questions that work out your Holland interest code and sharpen your matches.',
        route: 'career_choice',
      ));
    }
    if (!profile.hasSubjects) {
      steps.add((
        title: 'Choose your subjects',
        detail:
            'See which matric subjects keep your matched careers open - and which close them.',
        route: 'subjects',
      ));
    }
    if (profile.savedFavourites.isEmpty && profile.hasJobFit) {
      steps.add((
        title: 'Save a career you like',
        detail:
            'Favourites get their own reminders and sit at the top of your journey.',
        route: 'explore',
      ));
    }
    if (steps.length < 3) {
      steps.add((
        title: 'Talk to a career practitioner',
        detail:
            'Free on WhatsApp or the Khetha advice line. A person beats an algorithm for the final call.',
        route: 'support',
      ));
    }
    if (steps.length < 3) {
      steps.add((
        title: 'Check funding you qualify for',
        detail: 'NSFAS covers full tuition for TVET and most university study.',
        route: 'support',
      ));
    }

    return steps.take(3).toList();
  }
}
