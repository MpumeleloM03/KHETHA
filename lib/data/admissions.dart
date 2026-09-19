import '../models/career_models.dart';
import '../models/results_models.dart';
import 'ncap_repository.dart';

enum EligibilityStatus {
  /// Meets every published minimum.
  qualifies,

  /// Short by a little - within reach if marks improve, or worth applying to
  /// anyway because institutions admit above the minimum in practice.
  nearMiss,

  /// Does not meet the minimums as things stand.
  notYet,

  /// No results captured, so nothing can be said.
  unknown,

  /// Results captured, but they are school marks from before the FET phase.
  /// Admission cannot be assessed against them.
  tooEarly,
}

extension EligibilityStatusMeta on EligibilityStatus {
  String get label => switch (this) {
        EligibilityStatus.qualifies => 'You qualify',
        EligibilityStatus.nearMiss => 'Just short',
        EligibilityStatus.notYet => 'Not yet',
        EligibilityStatus.unknown => 'Add your results',
        EligibilityStatus.tooEarly => 'Too early to tell',
      };
}

/// One unmet condition, phrased so a learner knows exactly what is missing.
class Shortfall {
  final String label;
  final String detail;

  /// How far short, in the unit of the condition. Used to rank what to fix.
  final int gap;

  const Shortfall(this.label, this.detail, this.gap);
}

/// The result of checking one qualification against one set of results.
class Eligibility {
  final Qualification qualification;
  final EligibilityStatus status;
  final int apsHave;
  final int apsNeed;
  final List<Shortfall> shortfalls;

  const Eligibility({
    required this.qualification,
    required this.status,
    required this.apsHave,
    required this.apsNeed,
    required this.shortfalls,
  });

  int get apsGap => (apsNeed - apsHave).clamp(0, 42);

  /// The single most useful sentence about this qualification.
  String get summary {
    switch (status) {
      case EligibilityStatus.unknown:
        return 'Scan or enter your results to see whether you meet the requirements.';
      case EligibilityStatus.tooEarly:
        return 'These are Grade 9 marks. Entry requirements are set against matric results, so nothing can be said yet \u2014 but the subjects you choose now decide whether this stays open.';
      case EligibilityStatus.qualifies:
        return 'You meet the published minimum requirements. Applying does not guarantee a place, because institutions admit above the minimum when demand is high.';
      case EligibilityStatus.nearMiss:
        final first = shortfalls.first;
        return 'You are close. ${first.detail}';
      case EligibilityStatus.notYet:
        if (shortfalls.isEmpty) return 'You do not meet the requirements yet.';
        return shortfalls.map((s) => s.detail).join(' ');
    }
  }
}

/// A single move in a route towards a qualification.
enum RouteStepKind { study, upgrade, apply, work }

class RouteStep {
  final RouteStepKind kind;
  final String title;
  final String detail;
  final String duration;
  final String? qualificationId;

  const RouteStep({
    required this.kind,
    required this.title,
    required this.detail,
    required this.duration,
    this.qualificationId,
  });
}

/// An alternative way to reach a qualification a learner cannot enter directly.
class BridgingRoute {
  final String title;
  final String summary;
  final List<RouteStep> steps;
  final String totalDuration;

  /// Lower sorts first. Routes that start this year beat routes that need a
  /// year of upgrading before anything begins.
  final int priority;

  const BridgingRoute({
    required this.title,
    required this.summary,
    required this.steps,
    required this.totalDuration,
    required this.priority,
  });
}

/// Works out what a learner can get into, and what to do when they cannot get
/// into what they want.
///
/// This is the part of the app that answers the question a results slip
/// actually raises. "You do not qualify" is not guidance; "you do not qualify
/// this year, and here are three routes that still end where you want to be"
/// is.
class AdmissionsEngine {
  /// Check one qualification against one set of results.
  static Eligibility assess(Qualification q, MatricResults? results) {
    if (results == null) {
      return Eligibility(
        qualification: q,
        status: EligibilityStatus.unknown,
        apsHave: 0,
        apsNeed: q.apsRequired,
        shortfalls: const [],
      );
    }

    // Grade 9 marks are not admission evidence. Scoring them would produce an
    // APS and a pass type that look authoritative and mean nothing.
    if (!results.kind.countsTowardsAdmission) {
      return Eligibility(
        qualification: q,
        status: EligibilityStatus.tooEarly,
        apsHave: 0,
        apsNeed: q.apsRequired,
        shortfalls: const [],
      );
    }

    final shortfalls = <Shortfall>[];
    final aps = results.aps;

    // Pass type is the first gate, and failing it cannot be offset by a good
    // APS - which is exactly the misunderstanding that costs learners a place.
    final have = _passRank(results.passType);
    if (have < q.passRequired.rank) {
      shortfalls.add(Shortfall(
        'NSC pass type',
        'This needs a ${q.passRequired.label}, and your results give a ${results.passType} pass.',
        q.passRequired.rank - have,
      ));
    }

    if (q.apsRequired > 0 && aps < q.apsRequired) {
      shortfalls.add(Shortfall(
        'APS',
        'You need ${q.apsRequired} APS points and you have $aps.',
        q.apsRequired - aps,
      ));
    }

    for (final req in q.requirements) {
      if (!req.mandatory) continue;
      final best = _bestMarkFor(results, req.anyOf);
      if (best == null) {
        shortfalls.add(Shortfall(
          req.label,
          'You did not take ${req.label}, which this requires at ${req.minPercent}%.',
          req.minPercent,
        ));
      } else if (best < req.minPercent) {
        shortfalls.add(Shortfall(
          req.label,
          'You need ${req.minPercent}% in ${req.label} and you have $best%.',
          req.minPercent - best,
        ));
      }
    }

    final status = _status(shortfalls);

    // Show the biggest obstacle first; that is what the learner has to solve.
    shortfalls.sort((a, b) => b.gap.compareTo(a.gap));

    return Eligibility(
      qualification: q,
      status: status,
      apsHave: aps,
      apsNeed: q.apsRequired,
      shortfalls: shortfalls,
    );
  }

  /// A near miss is one condition, missed by a little. Two problems, or one big
  /// one, is not "close" - telling a learner otherwise wastes an application
  /// fee and a year.
  static EligibilityStatus _status(List<Shortfall> shortfalls) {
    if (shortfalls.isEmpty) return EligibilityStatus.qualifies;
    if (shortfalls.length == 1 && shortfalls.first.gap <= 5) {
      return EligibilityStatus.nearMiss;
    }
    return EligibilityStatus.notYet;
  }

  static int _passRank(String passType) => switch (passType) {
        'Bachelor' => 3,
        'Diploma' => 2,
        'Higher Certificate' => 1,
        _ => 0,
      };

  static int? _bestMarkFor(MatricResults results, List<String> anyOf) {
    int? best;
    for (final name in anyOf) {
      final mark = results.markFor(name);
      if (mark != null && (best == null || mark > best)) best = mark;
    }
    return best;
  }

  /// Every qualification, assessed, best prospects first.
  static List<Eligibility> assessAll(MatricResults? results, {String? field}) {
    final list = Ncap.qualifications
        .where((q) => field == null || q.field == field)
        .map((q) => assess(q, results))
        .toList();

    list.sort((a, b) {
      final byStatus = a.status.index.compareTo(b.status.index);
      if (byStatus != 0) return byStatus;
      // Within a status, the harder qualification first - a learner who
      // qualifies for a degree should see the degree above the certificate.
      return b.qualification.apsRequired.compareTo(a.qualification.apsRequired);
    });
    return list;
  }

  static List<Eligibility> openTo(MatricResults? results) => assessAll(results)
      .where((e) => e.status == EligibilityStatus.qualifies)
      .toList();

  // ---- Bridging ----------------------------------------------------------

  /// Routes to [target] for a learner who cannot enter it directly.
  ///
  /// Three kinds of answer, in the order they are worth to a learner sitting
  /// with a results slip in January:
  ///   1. Start something this year that articulates into the target.
  ///   2. Start the target itself in its extended form.
  ///   3. Upgrade the marks that are blocking it and apply again next year.
  static List<BridgingRoute> routesTo(Qualification target, MatricResults? results) {
    if (results == null) return const [];
    if (!results.kind.countsTowardsAdmission) return const [];

    final direct = assess(target, results);
    if (direct.status == EligibilityStatus.qualifies) return const [];

    final routes = <BridgingRoute>[];

    final extended = _extendedRoute(target, results);
    if (extended != null) routes.add(extended);

    routes.addAll(_articulationRoutes(target, results));

    final upgrade = _upgradeRoute(target, direct);
    if (upgrade != null) routes.add(upgrade);

    routes.sort((a, b) => a.priority.compareTo(b.priority));
    return routes;
  }

  /// The same qualification, delivered over an extra year with a lower bar.
  static BridgingRoute? _extendedRoute(Qualification target, MatricResults results) {
    if (target.isExtendedProgramme) return null;

    for (final q in Ncap.qualifications) {
      if (!q.isExtendedProgramme) continue;
      if (q.field != target.field) continue;
      // Matched on SAQA id: the extended version registers the same
      // qualification, which is the whole point of it.
      if (q.saqaId != target.saqaId) continue;
      final check = assess(q, results);
      if (check.status == EligibilityStatus.notYet) continue;

      // A near miss is still a miss. Offering this route without saying what is
      // outstanding would send a learner to an application they cannot make.
      final caveat = check.shortfalls.isEmpty
          ? 'You meet the requirements for this now.'
          : 'You are still short on one thing: ${check.shortfalls.first.detail} '
              'Institutions do admit near the minimum, so this is worth '
              'applying for, but keep a second option open.';

      return BridgingRoute(
        title: 'Extended programme',
        summary:
            'The same qualification, one year longer, with a lower entry bar. You graduate with exactly the degree you wanted - nothing on the certificate says "extended".',
        totalDuration: q.duration,
        priority: 0,
        steps: [
          RouteStep(
            kind: RouteStepKind.apply,
            title: q.title,
            detail:
                'Needs ${q.apsRequired} APS against ${target.apsRequired} for the standard programme. DHET-funded, and NSFAS covers it. $caveat',
            duration: q.duration,
            qualificationId: q.id,
          ),
        ],
      );
    }
    return null;
  }

  /// Searches the articulation graph backwards from the target for an entry
  /// point the learner can actually get into now.
  ///
  /// Breadth-first, so the shortest ladder is found first: one extra year beats
  /// two, and a learner deciding in January cares about that more than about
  /// which qualification is prettier.
  static List<BridgingRoute> _articulationRoutes(
    Qualification target,
    MatricResults results,
  ) {
    // Reverse edges: for each qualification, which ones articulate into it.
    final incoming = <String, List<Qualification>>{};
    for (final q in Ncap.qualifications) {
      for (final next in q.articulatesTo) {
        incoming.putIfAbsent(next, () => []).add(q);
      }
    }

    final routes = <BridgingRoute>[];
    final visited = <String>{target.id};
    // Each entry is a chain running backwards from the target.
    var frontier = <List<Qualification>>[
      [target]
    ];

    // Three hops is the practical limit; beyond that the route is longer than
    // simply upgrading and reapplying.
    for (var depth = 0; depth < 3 && routes.length < 3; depth++) {
      final next = <List<Qualification>>[];

      for (final chain in frontier) {
        for (final predecessor in incoming[chain.last.id] ?? const <Qualification>[]) {
          if (!visited.add(predecessor.id)) continue;

          final extended = [...chain, predecessor];

          if (assess(predecessor, results).status != EligibilityStatus.notYet) {
            // Reverse into forward order for presentation.
            routes.add(_routeFromChain(extended.reversed.toList(), depth));
            if (routes.length >= 3) break;
          } else {
            next.add(extended);
          }
        }
        if (routes.length >= 3) break;
      }

      frontier = next;
      if (frontier.isEmpty) break;
    }

    return routes;
  }

  static BridgingRoute _routeFromChain(List<Qualification> forward, int depth) {
    final steps = <RouteStep>[];

    for (var i = 0; i < forward.length; i++) {
      final q = forward[i];
      final isEntry = i == 0;
      final isTarget = i == forward.length - 1;

      steps.add(RouteStep(
        kind: isEntry ? RouteStepKind.apply : RouteStepKind.study,
        title: q.title,
        detail: isEntry
            ? 'Start here. You meet the requirements for this now: ${q.minimumRequirements}'
            : isTarget
                ? 'Where you wanted to be. Entry by articulation from the previous step, with credits carried across.'
                : 'Articulates from the step before it, carrying credits.',
        duration: q.duration,
        qualificationId: q.id,
      ));
    }

    final years = forward.fold<int>(0, (sum, q) {
      final match = RegExp(r'(\d+)').firstMatch(q.duration);
      return sum + (match == null ? 1 : int.parse(match.group(1)!));
    });

    return BridgingRoute(
      title: forward.map((q) => _shortTitle(q.title)).join(' → '),
      summary:
          'Start at ${forward.first.title} this year and articulate up. Credits carry across at each step, so the real total is usually shorter than the sum of the parts. The institution decides how much it recognises.',
      // Stated as an upper bound: adding the durations together and calling it
      // "the total" overstates it, because articulation carries credits.
      totalDuration: 'Up to $years years',
      priority: 1 + depth,
      steps: steps,
    );
  }

  static String _shortTitle(String title) {
    if (title.startsWith('Higher Certificate')) return 'Higher Certificate';
    if (title.startsWith('National Certificate') || title.startsWith('NC(V)')) {
      return 'NC(V)';
    }
    if (title.startsWith('Diploma') || title.startsWith('National Diploma')) {
      return 'Diploma';
    }
    if (title.startsWith('Bachelor of Commerce')) return 'BCom';
    if (title.startsWith('Bachelor of Science')) return 'BSc';
    if (title.startsWith('Bachelor of Engineering')) return 'BEng';
    if (title.startsWith('Bachelor of Arts')) return 'BA';
    if (title.startsWith('Bachelor')) return 'Degree';
    return title;
  }

  /// Fix the marks and apply again next year.
  static BridgingRoute? _upgradeRoute(Qualification target, Eligibility direct) {
    final subjectGaps = direct.shortfalls
        .where((s) => s.label != 'APS' && s.label != 'NSC pass type')
        .toList();
    if (direct.shortfalls.isEmpty) return null;

    final what = subjectGaps.isEmpty
        ? 'your overall results'
        : subjectGaps.map((s) => s.label).join(' and ');

    return BridgingRoute(
      title: 'Upgrade and apply again',
      summary:
          'Rewrite $what through the DHET Second Chance Matric Support Programme. It is free, it runs at centres countrywide, and an improved mark replaces the old one on your certificate.',
      totalDuration: 'One year',
      priority: 5,
      steps: [
        const RouteStep(
          kind: RouteStepKind.upgrade,
          title: 'Register for Second Chance',
          detail:
              'Free DHET programme for rewriting matric subjects. Register at your district office or through the Khetha advice line.',
          duration: 'Registration opens early in the year',
        ),
        RouteStep(
          kind: RouteStepKind.work,
          title: 'Rewrite $what',
          detail: direct.shortfalls.map((s) => s.detail).join(' '),
          duration: 'Exams in May/June or October/November',
        ),
        RouteStep(
          kind: RouteStepKind.apply,
          title: target.title,
          detail: 'Apply again with the improved result.',
          duration: target.duration,
          qualificationId: target.id,
        ),
      ],
    );
  }
}
