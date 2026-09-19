import 'package:flutter/cupertino.dart';

import '../data/intelligence.dart';
import '../data/ncap_repository.dart';
import '../models/career_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/listen_button.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';
import 'results_screen.dart';
import 'root_tabs.dart';

/// Everything about one occupation, in the order a learner actually asks:
/// does it suit me, what is the day like, can I still get in, what do I study,
/// where, and what does it pay.
class CareerDetailScreen extends StatelessWidget {
  final String careerId;
  const CareerDetailScreen({super.key, required this.careerId});

  @override
  Widget build(BuildContext context) {
    final career = Ncap.careerById(careerId);
    if (career == null) {
      return const KhethaDetailPage(title: 'Not found', slivers: []);
    }

    final app = AppScope.of(context);
    final p = Palette.of(context);
    final profile = app.profile;
    final fav = app.isFavourite(career.id);

    final hasProfile = profile.riasecScores.isNotEmpty ||
        profile.traitScores.isNotEmpty ||
        profile.chosenSubjects.isNotEmpty;
    final match = hasProfile
        ? CareerIntelligence.rank(profile, limit: Ncap.careers.length)
            .firstWhere((m) => m.career.id == career.id)
        : null;
    final readiness = CareerIntelligence.readiness(career, profile);

    final quals = Ncap.qualificationsFor(career.id);
    final allProviders = Ncap.providersFor(career.sector);

    // Narrow to the learner's province only if they have told us one. Passing a
    // null province to the repository matches every institution, which would
    // let the heading claim a province the learner never set.
    final localProviders = profile.province == null
        ? const <LearningProvider>[]
        : Ncap.providersFor(career.sector, province: profile.province);

    final shownProviders = localProviders.isNotEmpty
        ? localProviders
        : allProviders.take(3).toList();

    return KhethaDetailPage(
      title: career.title,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: () => app.toggleFavourite(career.id),
        child: Icon(
          fav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          size: 22,
          color: fav ? p.warm : p.accent,
        ),
      ),
      slivers: [
        SliverSection(children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(career.sector, color: p.accent),
              Chip(career.nqfLevel, color: p.textSecondary),
              // A scarce-skill occupation is already high demand, so show the
              // stronger national-list label instead of both.
              if (career.scarceSkill)
                Chip('Occupation in high demand',
                    color: p.warm, icon: CupertinoIcons.flame_fill)
              else
                Chip(career.demand.label, color: p.textSecondary),
            ],
          ),
          const SizedBox(height: 16),

          if (match != null) ...[
            GlassCard(
              child: Row(
                children: [
                  ScoreRing(
                    percent: match.percent,
                    label: 'Fit with ${career.title}',
                    size: 70,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.confidenceLabel,
                            style: KhethaText.headline(p)),
                        const SizedBox(height: 4),
                        Text(
                          'Based on the answers you have given so far.',
                          style: KhethaText.caption(p),
                        ),
                        const SizedBox(height: 9),
                        KhethaButton(
                          label: 'Why this score?',
                          secondary: true,
                          expand: false,
                          onTap: () => showWhySheet(context, match),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _Block(
            icon: CupertinoIcons.sun_max_fill,
            title: 'What the work is',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ListenButton(
                    id: 'career-${career.id}',
                    text:
                        '${career.title}. ${career.description} A day in the life. ${career.dayInTheLife}',
                    label: career.title,
                  ),
                ),
                Text(career.description, style: KhethaText.body(p)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: p.accentMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A day in the life',
                          style: KhethaText.caption(p).copyWith(
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary)),
                      const SizedBox(height: 5),
                      Text(career.dayInTheLife, style: KhethaText.caption(p)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _Block(
            icon: CupertinoIcons.checkmark_seal,
            title: 'Can you still get in?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.chosenSubjects.isNotEmpty) ...[
                  LabelledBar(
                    label: 'Subject readiness',
                    value: readiness.ratio,
                    valueLabel: '${readiness.percent}%',
                    color: readiness.missing.isEmpty ? p.accent : p.warm,
                  ),
                  const SizedBox(height: 10),
                ],
                Text(readiness.verdict, style: KhethaText.body(p)),
                const SizedBox(height: 14),
                _SubjectList(
                  label: 'Required subjects',
                  subjects: career.requiredSubjects,
                  chosen: profile.chosenSubjects,
                  missing: readiness.missing,
                ),
                if (career.helpfulSubjects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Also helpful',
                      style: KhethaText.sectionLabel(p)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final sub in career.helpfulSubjects)
                        Chip(sub, color: p.textSecondary),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          _Block(
            icon: CupertinoIcons.map,
            title: 'How you get there',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(career.studyPathway, style: KhethaText.body(p)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Fact(
                        label: 'Minimum qualification',
                        value: career.minQualification,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Fact(label: 'OFO code', value: career.ofoCode),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _Block(
            icon: CupertinoIcons.money_dollar_circle,
            title: 'What it pays',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Fact(label: 'Starting out', value: career.entrySalaryBand),
                const SizedBox(height: 10),
                _Fact(
                    label: 'With experience',
                    value: career.experiencedSalaryBand),
                const SizedBox(height: 10),
                Text(
                  'Indicative national ranges for the demo dataset. Actual pay varies by employer, province and sector.',
                  style: KhethaText.caption(p).copyWith(color: p.textTertiary),
                ),
              ],
            ),
          ),

          if (quals.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('What to study', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassSection(
              children: [
                for (final q in quals)
                  GlassRow(
                    icon: CupertinoIcons.doc_text_fill,
                    title: q.title,
                    subtitle: '${q.nqfLevel} · ${q.duration} · ${q.providerType}',
                    showChevron: true,
                    onTap: () => _showQualification(context, q),
                  ),
              ],
            ),
          ],

          if (shownProviders.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    localProviders.isNotEmpty
                        ? 'Where to study in ${profile.province}'
                        : 'Where to study',
                    style: KhethaText.sectionLabel(p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GlassSection(
              footer: localProviders.isEmpty && profile.province != null
                  ? 'No institution in ${profile.province} offers this field in the demo dataset. The nearest options are shown instead.'
                  : null,
              children: [
                for (final prov in shownProviders)
                  GlassRow(
                    icon: CupertinoIcons.building_2_fill,
                    title: prov.name,
                    subtitle: '${prov.town} · ${prov.type}',
                  ),
              ],
            ),
          ],

          if (career.relatedCareerIds.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Related careers', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassSection(
              children: [
                for (final id in career.relatedCareerIds)
                  if (Ncap.careerById(id) != null)
                    GlassRow(
                      icon: CupertinoIcons.arrow_branch,
                      title: Ncap.careerById(id)!.title,
                      subtitle: Ncap.careerById(id)!.sector,
                      showChevron: true,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => CareerDetailScreen(careerId: id),
                        ),
                      ),
                    ),
              ],
            ),
          ],

          const SizedBox(height: 22),
          GlassCard(
            tint: p.warm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Not sure about this one?',
                    style: KhethaText.headline(p)),
                const SizedBox(height: 5),
                Text(
                  'A Khetha career practitioner can talk it through with you - free, on WhatsApp or the advice line.',
                  style: KhethaText.caption(p),
                ),
                const SizedBox(height: 13),
                KhethaButton(
                  label: 'Talk to a practitioner',
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  onTap: () {
                    // Resolve the tab controller before popping - this context
                    // is gone once the route is removed.
                    final tabs = RootTabs.of(context);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    tabs?.goToTab(3);
                  },
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  void _showQualification(BuildContext context, Qualification q) {
    final p = Palette.of(context);
    showKhethaSheet(
      context,
      title: q.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(q.nqfLevel, color: p.accent),
              Chip(q.duration, color: p.textSecondary),
              Chip('SAQA ${q.saqaId}', color: p.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Text('Minimum requirements', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 6),
          Text(q.minimumRequirements, style: KhethaText.body(p)),
          const SizedBox(height: 16),
          Text('Offered by', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 6),
          Text(q.providerType, style: KhethaText.body(p)),
          const SizedBox(height: 16),
          Text(
            'The SAQA ID lets you verify this qualification on the national register before you pay any registration fee.',
            style: KhethaText.caption(p).copyWith(color: p.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Block({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: p.accent),
              const SizedBox(width: 9),
              Expanded(child: Text(title, style: KhethaText.headline(p))),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: KhethaText.sectionLabel(p)),
        const SizedBox(height: 3),
        Text(value, style: KhethaText.body(p)),
      ],
    );
  }
}

class _SubjectList extends StatelessWidget {
  final String label;
  final List<String> subjects;
  final List<String> chosen;
  final List<String> missing;

  const _SubjectList({
    required this.label,
    required this.subjects,
    required this.chosen,
    required this.missing,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: KhethaText.sectionLabel(p)),
        const SizedBox(height: 7),
        for (final sub in subjects)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  chosen.isEmpty
                      ? CupertinoIcons.circle
                      : missing.contains(sub)
                          ? CupertinoIcons.xmark_circle_fill
                          : CupertinoIcons.checkmark_circle_fill,
                  size: 16,
                  color: chosen.isEmpty
                      ? p.textTertiary
                      : missing.contains(sub)
                          ? p.danger
                          : p.accent,
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(sub, style: KhethaText.body(p))),
              ],
            ),
          ),
      ],
    );
  }
}
