import 'package:flutter/cupertino.dart';

import '../data/intelligence.dart';
import '../data/ncap_repository.dart';
import '../data/seed_directory.dart';
import '../data/seed_quizzes.dart';
import '../models/career_models.dart';
import '../models/results_models.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';
import 'career_choice_screen.dart';
import 'career_detail_screen.dart';
import 'job_fit_quiz_screen.dart';
import 'results_screen.dart';
import 'grade9_screen.dart';
import 'scan_results_screen.dart';
import 'subject_chooser_screen.dart';

/// The learner's personal career journey - the thing a website cannot do.
///
/// Every tool the learner touches writes into one profile, and this screen is
/// that profile read back: who they are, what their answers say, which careers
/// that points at, and what is still missing.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = Palette.of(context);
    final s = S.of(context);
    final profile = app.profile;

    final hasAnything = profile.journeyProgress > 0;
    final matches = hasAnything
        ? CareerIntelligence.rank(profile, limit: 8)
        : <MatchResult>[];
    final insights = CareerIntelligence.insights(profile, matches);
    final favourites = profile.savedFavourites
        .map(Ncap.careerById)
        .whereType<Career>()
        .toList();

    return KhethaPage(
      title: s.tabJourney,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: () => _editIdentity(context),
        child: Icon(CupertinoIcons.person_crop_circle,
            size: 24, color: p.accent),
      ),
      slivers: [
        SliverSection(children: [
          _ProfileHeader(onEdit: () => _editIdentity(context)),
          const SizedBox(height: 16),

          if (!hasAnything) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(CupertinoIcons.map_pin_ellipse,
                      size: 26, color: p.accent),
                  const SizedBox(height: 12),
                  Text('Your journey starts empty',
                      style: KhethaText.title(p)),
                  const SizedBox(height: 6),
                  Text(
                    'Take one questionnaire and this page fills with your interest profile, your matched careers and the reasons behind each one.',
                    style: KhethaText.secondary(p),
                  ),
                  const SizedBox(height: 16),
                  KhethaButton(
                    label: 'Take the Job Fit Quiz',
                    icon: CupertinoIcons.play_circle_fill,
                    onTap: () =>
                        pushTool(context, const JobFitQuizScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const _ResultsCard(),
          const SizedBox(height: 14),

          if (profile.riasecScores.isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Interest code',
                                style: KhethaText.sectionLabel(p)),
                            const SizedBox(height: 4),
                            Text(profile.hollandCode,
                                style: KhethaText.largeTitle(p).copyWith(
                                    color: p.accent, letterSpacing: 2)),
                            const SizedBox(height: 4),
                            Text(
                              'Your three strongest interests, in order.',
                              style: KhethaText.caption(p),
                            ),
                          ],
                        ),
                      ),
                      RiasecChart(scores: profile.riasecScores, size: 130),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (profile.traitScores.isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How you like to work',
                      style: KhethaText.headline(p)),
                  const SizedBox(height: 10),
                  ...(() {
                    final sorted = profile.traitScores.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    final max = sorted.first.value;
                    return [
                      for (final e in sorted)
                        LabelledBar(
                          label: traitLabels[e.key] ?? e.key,
                          value: e.value / max,
                          valueLabel: '${e.value}',
                          color: p.warm,
                        ),
                    ];
                  })(),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (profile.chosenSubjects.isNotEmpty) ...[
            GlassCard(
              onTap: () => pushTool(context, const SubjectChooserScreen()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Your subjects',
                            style: KhethaText.headline(p)),
                      ),
                      Icon(CupertinoIcons.pencil,
                          size: 16, color: p.textTertiary),
                    ],
                  ),
                  if (profile.interestField != null) ...[
                    const SizedBox(height: 3),
                    Text(profile.interestField!,
                        style: KhethaText.caption(p)),
                  ],
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final sub in profile.chosenSubjects)
                        Chip(sub, color: p.accent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (insights.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Insights', style: KhethaText.sectionLabel(p)),
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
                              size: 14, color: p.warm),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(insights[i],
                                style: KhethaText.body(p))),
                      ],
                    ),
                    if (i != insights.length - 1) const SizedBox(height: 13),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],

          if (favourites.isNotEmpty) ...[
            Text('Saved careers', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassSection(
              footer:
                  'Saved careers get their own reminders and stay at the top of your journey.',
              children: [
                for (final c in favourites)
                  GlassRow(
                    icon: CupertinoIcons.heart_fill,
                    iconColor: p.warm,
                    title: c.title,
                    subtitle: c.sector,
                    showChevron: true,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => CareerDetailScreen(careerId: c.id),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
          ],

          if (matches.isNotEmpty) ...[
            Text('All your matches', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            for (final m in matches) ...[
              MatchCard(match: m),
              const SizedBox(height: 11),
            ],
          ],

          if (hasAnything) ...[
            const SizedBox(height: 10),
            const _RetakeCard(),
          ],
        ]),
      ],
    );
  }

  void _editIdentity(BuildContext context) {
    showKhethaSheet(
      context,
      title: 'About you',
      child: const _IdentityForm(),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onEdit;
  const _ProfileHeader({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final profile = app.profile;
    final initial = (profile.displayName?.isNotEmpty ?? false)
        ? profile.displayName![0].toUpperCase()
        : '?';

    return GlassCard(
      onTap: onEdit,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.accent, p.warm]),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(initial,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: p.onAccent)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.displayName ?? 'Add your name',
                        style: KhethaText.title(p)),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (profile.grade != null) profile.grade!,
                        if (profile.province != null) profile.province!,
                      ].join(' · ').ifEmpty('Tap to add your grade and province'),
                      style: KhethaText.caption(p),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right,
                  size: 15, color: p.textTertiary),
            ],
          ),
          const SizedBox(height: 16),
          ProgressTrack(value: profile.journeyProgress),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(profile.journeyProgress * 100).round()}% of your journey complete',
                  style: KhethaText.caption(p),
                ),
              ),
              if (profile.lastUpdated != null)
                Text('Saved', style: KhethaText.caption(p).copyWith(color: p.accent)),
            ],
          ),
        ],
      ),
    );
  }
}

extension _EmptyString on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _IdentityForm extends StatefulWidget {
  const _IdentityForm();

  @override
  State<_IdentityForm> createState() => _IdentityFormState();
}

class _IdentityFormState extends State<_IdentityForm> {
  late TextEditingController _name;
  String? _grade;
  String? _province;

  static const _grades = [
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
    'Finished school',
    'Out of school',
  ];

  @override
  void initState() {
    super.initState();
    final profile = AppScope.read(context).profile;
    _name = TextEditingController(text: profile.displayName ?? '');
    _grade = profile.grade;
    _province = profile.province;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optional, and stored only on this phone. Your province is used to show institutions you can actually reach.',
          style: KhethaText.secondary(p),
        ),
        const SizedBox(height: 18),
        Text('First name', style: KhethaText.sectionLabel(p)),
        const SizedBox(height: 7),
        CupertinoTextField(
          controller: _name,
          placeholder: 'What should we call you?',
          style: KhethaText.body(p),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: p.glassStroke, width: 0.6),
          ),
        ),
        const SizedBox(height: 18),
        Text('Where you are', style: KhethaText.sectionLabel(p)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in _grades)
              _SelectChip(
                label: g,
                active: _grade == g,
                onTap: () => setState(() => _grade = _grade == g ? null : g),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Province', style: KhethaText.sectionLabel(p)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final prov in provinces)
              _SelectChip(
                label: prov,
                active: _province == prov,
                onTap: () =>
                    setState(() => _province = _province == prov ? null : prov),
              ),
          ],
        ),
        const SizedBox(height: 22),
        KhethaButton(
          label: 'Save',
          onTap: () async {
            await app.setIdentity(
              name: _name.text,
              grade: _grade,
              province: _province,
            );
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? p.accent : p.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.glassStroke, width: 0.6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? p.onAccent : p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RetakeCard extends StatelessWidget {
  const _RetakeCard();

  @override
  Widget build(BuildContext context) {
    return GlassSection(
      header: 'Change your answers',
      footer:
          'Retaking a questionnaire updates your interest profile. Both questionnaires feed the same profile and reinforce each other.',
      children: [
        GlassRow(
          icon: CupertinoIcons.arrow_counterclockwise,
          title: 'Retake Job Fit Quiz',
          showChevron: true,
          onTap: () => pushTool(context, const JobFitQuizScreen()),
        ),
        GlassRow(
          icon: CupertinoIcons.arrow_counterclockwise,
          title: 'Retake Career Choice',
          showChevron: true,
          onTap: () => pushTool(context, const CareerChoiceScreen()),
        ),
        GlassRow(
          icon: CupertinoIcons.book,
          title: 'Change my subjects',
          showChevron: true,
          onTap: () => pushTool(context, const SubjectChooserScreen()),
        ),
      ],
    );
  }
}


/// The learner's marks, or the prompt to add them.
///
/// Results sit alongside the questionnaire results rather than in a separate
/// part of the app, because the whole point of the journey is that the two are
/// read together.
class _ResultsCard extends StatelessWidget {
  const _ResultsCard();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final results = app.results;
    final isGrade9 = app.profile.grade == 'Grade 9';

    if (results == null) {
      return GlassCard(
        tint: p.warm,
        onTap: () => Navigator.of(context).push(
          CupertinoPageRoute<void>(
            builder: (_) =>
                isGrade9 ? const Grade9Screen() : const ScanResultsScreen(),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.warmMuted,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(CupertinoIcons.doc_text_viewfinder,
                  size: 19, color: p.warm),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGrade9 ? 'Add your Grade 9 marks' : 'Add your results',
                    style: KhethaText.headline(p),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isGrade9
                        ? 'Term 4 marks turn this into real subject advice.'
                        : 'Your APS, and what it opens.',
                    style: KhethaText.caption(p),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
          ],
        ),
      );
    }

    return GlassCard(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => results.kind == ResultsKind.grade9
              ? const Grade9Screen()
              : const ScanResultsScreen(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScoreRing(
                percent: ((results.aps / results.maxPossibleAps) * 100).round(),
                label: 'APS ${results.aps}',
                size: 58,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('APS ${results.aps}',
                            style: KhethaText.headline(p)),
                        const SizedBox(width: 8),
                        Chip(results.passType,
                            color:
                                results.hasBachelorPass ? p.accent : p.warm),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${results.kind.label} \u00b7 ${results.subjects.length} subjects',
                      style: KhethaText.caption(p),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
            ],
          ),
          if (results.kind.isProvisional) ...[
            const SizedBox(height: 11),
            Text(
              'Not final results, so everything built on them is an estimate to plan with.',
              style: KhethaText.caption(p).copyWith(color: p.textTertiary),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in results.countedSubjects)
                Chip('${s.subject.split(' ').first} ${s.percentage}%',
                    color: p.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}
