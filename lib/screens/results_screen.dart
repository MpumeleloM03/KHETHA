import 'package:flutter/cupertino.dart';

import '../data/intelligence.dart';
import '../data/seed_quizzes.dart';
import '../models/career_models.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';
import 'career_detail_screen.dart';

/// Shown straight after a questionnaire.
///
/// The point of this screen is that it does not just hand over a ranked list.
/// Every match carries its reasoning, and the Why panel breaks the score into
/// the three signals that produced it. A learner is being asked to make a
/// decision about their life - they are owed the working, not just the answer.
class ResultsScreen extends StatelessWidget {
  final String source;
  const ResultsScreen({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = Palette.of(context);
    final profile = app.profile;
    final matches = CareerIntelligence.rank(profile, limit: 6);
    final insights = CareerIntelligence.insights(profile, matches);

    return KhethaDetailPage(
      title: 'Your results',
      slivers: [
        SliverSection(children: [
          Text('From your $source', style: KhethaText.secondary(p)),
          const SizedBox(height: 16),

          if (profile.riasecScores.isNotEmpty) _InterestCard(profile: profile),
          const SizedBox(height: 16),

          if (profile.traitScores.isNotEmpty) ...[
            _TraitCard(traits: profile.traitScores),
            const SizedBox(height: 16),
          ],

          if (insights.isNotEmpty) ...[
            Text('What this tells us', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < insights.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(CupertinoIcons.sparkles,
                              size: 15, color: p.warm),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(insights[i], style: KhethaText.body(p)),
                        ),
                      ],
                    ),
                    if (i != insights.length - 1) const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],

          Text('Careers matched to you', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          for (final m in matches) ...[
            MatchCard(match: m),
            const SizedBox(height: 11),
          ],

          const SizedBox(height: 10),
          const _MethodNote(),
          const SizedBox(height: 18),
          KhethaButton(
            label: 'Back to my journey',
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ]),
      ],
    );
  }
}

class _InterestCard extends StatelessWidget {
  final UserProfile profile;
  const _InterestCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final sorted = profile.riasecScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your interest code',
                        style: KhethaText.sectionLabel(p)),
                    const SizedBox(height: 4),
                    Text(profile.hollandCode,
                        style: KhethaText.largeTitle(p)
                            .copyWith(color: p.accent, letterSpacing: 2)),
                  ],
                ),
              ),
              RiasecChart(scores: profile.riasecScores, size: 128),
            ],
          ),
          const SizedBox(height: 12),
          for (final e in top)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.accentMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(e.key.code,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: p.accent)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.key.plain, style: KhethaText.caption(p)),
                  ),
                ],
              ),
            ),
          Text(
            'This is a Holland code - the same six-dimension measure career practitioners use. Take it with you when you speak to one.',
            style: KhethaText.caption(p).copyWith(color: p.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _TraitCard extends StatelessWidget {
  final Map<String, int> traits;
  const _TraitCard({required this.traits});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final sorted = traits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How you like to work', style: KhethaText.headline(p)),
          const SizedBox(height: 10),
          for (final e in sorted.take(5))
            LabelledBar(
              label: traitLabels[e.key] ?? e.key,
              value: e.value / max,
              valueLabel: '${e.value}',
              color: p.warm,
            ),
        ],
      ),
    );
  }
}

/// A ranked career with its reasoning one tap away.
class MatchCard extends StatelessWidget {
  final MatchResult match;
  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final s = S.of(context);
    final fav = app.isFavourite(match.career.id);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScoreRing(
                percent: match.percent,
                label: match.career.title,
                size: 62,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.career.title, style: KhethaText.headline(p)),
                    const SizedBox(height: 3),
                    Text(match.confidenceLabel,
                        style: KhethaText.caption(p)
                            .copyWith(color: p.accent, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(match.career.sector, color: p.textSecondary),
                        if (match.career.scarceSkill)
                          Chip('High demand',
                              color: p.warm, icon: CupertinoIcons.flame_fill),
                      ],
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: () => app.toggleFavourite(match.career.id),
                child: Icon(
                  fav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  size: 21,
                  color: fav ? p.warm : p.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CareerIntelligence.explain(match, app.profile),
            style: KhethaText.caption(p).copyWith(height: 1.4),
          ),
          // Only a real gap is worth a warning. Before the Subject Chooser has
          // been used, every requirement reads as "missing", which would put an
          // amber alert on every card and teach the learner to ignore it.
          if (match.missingSubjects.isNotEmpty &&
              app.profile.chosenSubjects.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p.warmMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle_fill,
                      size: 14, color: p.warm),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Needs ${match.missingSubjects.join(" and ")} - which you have not selected.',
                      style: KhethaText.caption(p),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // IntrinsicHeight so the two buttons stay the same height when one
          // label wraps to a second line and the other does not.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: KhethaButton(
                    label: s.whyThisMatch,
                    secondary: true,
                    onTap: () => showWhySheet(context, match),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KhethaButton(
                    label: 'Details',
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) =>
                            CareerDetailScreen(careerId: match.career.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The explainability panel.
///
/// Breaks a match into the three weighted signals behind it and states what
/// the engine did *not* take into account. A recommendation a learner cannot
/// interrogate is one they cannot sensibly disagree with.
Future<void> showWhySheet(BuildContext context, MatchResult match) {
  final p = Palette.of(context);

  return showKhethaSheet(
    context,
    title: 'Why ${match.career.title}?',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your fit was scored ${match.percent}% from three signals, weighted as shown. Nothing else influenced it.',
          style: KhethaText.secondary(p),
        ),
        const SizedBox(height: 18),
        LabelledBar(
          label: 'Interest match (weight ${(CareerIntelligence.wInterest * 100).round()}%)',
          value: match.interestScore,
        ),
        LabelledBar(
          label: 'Work style (weight ${(CareerIntelligence.wWorkStyle * 100).round()}%)',
          value: match.workStyleScore,
          color: p.warm,
        ),
        LabelledBar(
          label: 'Subject alignment (weight ${(CareerIntelligence.wSubjects * 100).round()}%)',
          value: match.subjectScore,
          color: p.textSecondary,
        ),
        const SizedBox(height: 20),
        Text('Traced back to your answers',
            style: KhethaText.sectionLabel(p)),
        const SizedBox(height: 10),
        for (final e in match.evidence)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.arrow_turn_down_right,
                        size: 13, color: p.accent),
                    const SizedBox(width: 7),
                    Text(e.label,
                        style: KhethaText.caption(p).copyWith(
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(e.detail, style: KhethaText.caption(p)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.accentMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.info_circle_fill,
                      size: 15, color: p.accent),
                  const SizedBox(width: 8),
                  Text('What this did not consider',
                      style: KhethaText.caption(p).copyWith(
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary)),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Your marks, your financial situation, where you can realistically study, and what you are actually good at. This is a starting point for a conversation with a career practitioner - not a decision.',
                style: KhethaText.caption(p),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MethodNote extends StatelessWidget {
  const _MethodNote();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.device_phone_portrait, size: 17, color: p.accent),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Worked out on this phone',
                    style: KhethaText.headline(p)),
                const SizedBox(height: 5),
                Text(
                  'Your answers were scored on the device in a few milliseconds. Nothing was uploaded, and the app did not need a connection to do it.',
                  style: KhethaText.caption(p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
