import 'package:flutter/cupertino.dart';

import '../data/intelligence.dart';
import '../data/ncap_repository.dart';
import '../data/results_parser.dart';
import '../data/subject_advisor.dart';
import '../models/career_models.dart';
import '../models/results_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import 'career_detail_screen.dart';
import 'job_fit_quiz_screen.dart';
import 'tutors_screen.dart';

/// Subject choice for a Grade 9 learner.
///
/// This is the highest-stakes decision in the whole app and the one made with
/// the least information. A learner picks in Grade 9, finds out in Grade 12
/// what it cost them, and by then it is a year of rewrites to undo. So this
/// flow takes their Term 4 marks, their interests, and the career they say they
/// want, and tells them plainly which combination keeps that career reachable.
class Grade9Screen extends StatefulWidget {
  const Grade9Screen({super.key});

  @override
  State<Grade9Screen> createState() => _Grade9ScreenState();
}

class _Grade9ScreenState extends State<Grade9Screen> {
  final Map<String, int> _marks = {};
  String? _goalCareerId;

  @override
  void initState() {
    super.initState();
    final stored = AppScope.read(context).results;
    if (stored != null && stored.kind == ResultsKind.grade9) {
      for (final s in stored.subjects) {
        _marks[s.subject] = s.percentage;
      }
    }
    final favourites = AppScope.read(context).profile.savedFavourites;
    if (favourites.isNotEmpty) _goalCareerId = favourites.first;
  }

  MatricResults get _results => MatricResults(
        kind: ResultsKind.grade9,
        capturedAt: DateTime.now(),
        source: 'Grade 9 Term 4 report',
        subjects: [
          for (final e in _marks.entries)
            SubjectResult(subject: e.key, percentage: e.value),
        ],
      );

  bool get _hasEnough => _marks.length >= 4;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final goal = _goalCareerId == null ? null : Ncap.careerById(_goalCareerId!);

    final strengths = _hasEnough ? SubjectAdvisor.strengths(_results) : const <SubjectResult>[];
    final package = _hasEnough
        ? SubjectAdvisor.recommendPackage(
            grade9: _results,
            goal: goal,
            field: app.profile.interestField,
          )
        : const <SubjectAdvice>[];
    final blockers = (_hasEnough && goal != null)
        ? SubjectAdvisor.blockers(grade9: _results, goal: goal)
        : const <SubjectAdvice>[];
    final mathAdvice = _hasEnough
        ? SubjectAdvisor.advise(grade9: _results, goal: goal)
            .where((a) => a.subject == 'Mathematical Literacy')
            .toList()
        : const <SubjectAdvice>[];

    return KhethaDetailPage(
      title: 'Choosing subjects',
      slivers: [
        SliverSection(children: [
          GlassCard(
            tint: p.warm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The decision nobody explains',
                    style: KhethaText.headline(p)),
                const SizedBox(height: 7),
                Text(
                  'The subjects you pick this year decide what you can study in three years’ time. Put in your Term 4 marks and Khetha Go will tell you which combination keeps the most doors open for you specifically.',
                  style: KhethaText.body(p).copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text('Your Grade 9 Term 4 marks', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          GlassSection(
            footer:
                'Tap a subject to enter or change the mark. Four or more gives a useful answer.',
            children: [
              for (final subject in ResultsParser.grade9Subjects)
                GlassRow(
                  title: subject,
                  subtitle: _marks[subject] == null
                      ? 'Not entered'
                      : _bandFor(_marks[subject]!),
                  trailing: Text(
                    _marks[subject] == null ? '-' : '${_marks[subject]}%',
                    style: KhethaText.body(p).copyWith(
                      fontWeight: FontWeight.w700,
                      color: _marks[subject] == null ? p.textTertiary : p.textPrimary,
                    ),
                  ),
                  onTap: () => _enterMark(subject),
                ),
            ],
          ),

          const SizedBox(height: 22),
          Text('What do you want to become?', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          GlassCard(
            onTap: _pickGoal,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: goal == null ? p.warmMuted : p.accentMuted,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    goal == null
                        ? CupertinoIcons.question
                        : CupertinoIcons.briefcase_fill,
                    size: 19,
                    color: goal == null ? p.warm : p.accent,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal?.title ?? 'Pick a career you are aiming at',
                          style: KhethaText.headline(p)),
                      const SizedBox(height: 3),
                      Text(
                        goal == null
                            ? 'Optional, but it sharpens everything below.'
                            : goal.sector,
                        style: KhethaText.caption(p),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
              ],
            ),
          ),

          if (!app.profile.hasJobFit) ...[
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Not sure what you want yet?',
                      style: KhethaText.headline(p)),
                  const SizedBox(height: 6),
                  Text(
                    'Most people your age are not. The Job Fit Quiz takes two minutes and gives the recommendation something to work with besides your marks.',
                    style: KhethaText.caption(p),
                  ),
                  const SizedBox(height: 13),
                  KhethaButton(
                    label: 'Take the quiz',
                    secondary: true,
                    onTap: () => pushTool(context, const JobFitQuizScreen()),
                  ),
                ],
              ),
            ),
          ],

          if (_hasEnough) ...[
            const SizedBox(height: 26),
            Text('What you are strong at', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in strengths)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.star_fill, size: 14, color: p.warm),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(s.subject, style: KhethaText.body(p)),
                          ),
                          Text('${s.percentage}%',
                              style: KhethaText.body(p)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  Text(
                    'Strength is not the same as interest, and neither on its own decides a career. Both are below.',
                    style: KhethaText.caption(p),
                  ),
                ],
              ),
            ),

            if (mathAdvice.isNotEmpty) ...[
              const SizedBox(height: 22),
              _MathsCard(advice: mathAdvice.first),
            ],

            if (package.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('Recommended for you', style: KhethaText.sectionLabel(p)),
              const SizedBox(height: 6),
              Text(
                'You choose three electives on top of two languages, Life Orientation and a Mathematics. These three fit your marks${goal == null ? '' : ' and keep ${goal.title} reachable'}.',
                style: KhethaText.caption(p),
              ),
              const SizedBox(height: 12),
              for (final advice in package) ...[
                _AdviceCard(advice: advice),
                const SizedBox(height: 10),
              ],
            ],

            if (blockers.isNotEmpty) ...[
              const SizedBox(height: 18),
              _BlockerCard(goal: goal!, blockers: blockers),
            ],

            const SizedBox(height: 22),
            Text('Everything else', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassSection(
              footer:
                  'Advice is based on the Grade 9 subject that best predicts each one. Your school may not offer all of these.',
              children: [
                for (final advice
                    in SubjectAdvisor.advise(grade9: _results, goal: goal)
                        .where((a) =>
                            !package.contains(a) &&
                            a.subject != 'Mathematical Literacy'))
                  GlassRow(
                    icon: _iconFor(advice.readiness),
                    iconColor: _colourFor(advice.readiness, p),
                    title: advice.subject,
                    subtitle: advice.reason,
                    trailing: advice.neededForGoal
                        ? Chip('Needed', color: p.warm)
                        : null,
                  ),
              ],
            ),

            const SizedBox(height: 22),
            KhethaButton(
              label: 'Save my marks',
              icon: CupertinoIcons.checkmark_circle_fill,
              onTap: () async {
                await app.setResults(_results);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Saved to this phone only. Nothing goes to your school.',
              textAlign: TextAlign.center,
              style: KhethaText.caption(p).copyWith(color: p.textTertiary),
            ),
          ] else ...[
            const SizedBox(height: 22),
            GlassCard(
              child: Text(
                'Add at least four marks above and the recommendation appears here.',
                style: KhethaText.secondary(p),
              ),
            ),
          ],
        ]),
      ],
    );
  }

  String _bandFor(int mark) => switch (mark) {
        >= 80 => 'Outstanding',
        >= 70 => 'Meritorious',
        >= 60 => 'Substantial',
        >= 50 => 'Adequate',
        >= 40 => 'Moderate',
        >= 30 => 'Elementary',
        _ => 'Not achieved',
      };

  IconData _iconFor(SubjectReadiness r) => switch (r) {
        SubjectReadiness.strong => CupertinoIcons.star_fill,
        SubjectReadiness.viable => CupertinoIcons.checkmark_circle_fill,
        SubjectReadiness.risky => CupertinoIcons.exclamationmark_circle_fill,
        SubjectReadiness.notAdvised => CupertinoIcons.xmark_circle_fill,
      };

  Color _colourFor(SubjectReadiness r, Palette p) => switch (r) {
        SubjectReadiness.strong => p.accent,
        SubjectReadiness.viable => p.accent,
        SubjectReadiness.risky => p.warm,
        SubjectReadiness.notAdvised => p.danger,
      };

  Future<void> _enterMark(String subject) async {
    final controller =
        TextEditingController(text: _marks[subject]?.toString() ?? '');

    final saved = await showKhethaSheet<bool>(
      context,
      title: subject,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What was your Term 4 percentage?',
              style: KhethaText.secondary(Palette.of(context))),
          const SizedBox(height: 14),
          CupertinoTextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            placeholder: 'e.g. 62',
            style: KhethaText.body(Palette.of(context)).copyWith(fontSize: 22),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Palette.of(context).surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Palette.of(context).glassStroke, width: 0.6),
            ),
            onSubmitted: (_) => closeSheet(context, true),
          ),
          const SizedBox(height: 18),
          KhethaButton(
            label: 'Save',
            onTap: () => closeSheet(context, true),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final value = int.tryParse(controller.text);
    setState(() {
      if (value == null) {
        _marks.remove(subject);
      } else {
        _marks[subject] = value.clamp(0, 100);
      }
    });
  }

  Future<void> _pickGoal() async {
    final app = AppScope.read(context);
    final suggested = app.profile.hasJobFit
        ? CareerIntelligence.rank(app.profile, limit: 6)
            .map((m) => m.career)
            .toList()
        : <Career>[];
    final rest = Ncap.careers.where((c) => !suggested.contains(c)).toList();

    final chosen = await showKhethaSheet<String>(
      context,
      title: 'What do you want to become?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (suggested.isNotEmpty) ...[
            Text('Matched to your answers',
                style: KhethaText.sectionLabel(Palette.of(context))),
            const SizedBox(height: 8),
            GlassSection(
              children: [
                for (final c in suggested)
                  GlassRow(
                    icon: CupertinoIcons.sparkles,
                    title: c.title,
                    subtitle: c.sector,
                    showChevron: true,
                    onTap: () => closeSheet(context, c.id),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          Text('Everything else',
              style: KhethaText.sectionLabel(Palette.of(context))),
          const SizedBox(height: 8),
          GlassSection(
            children: [
              for (final c in rest)
                GlassRow(
                  title: c.title,
                  subtitle: c.sector,
                  showChevron: true,
                  onTap: () => closeSheet(context, c.id),
                ),
            ],
          ),
        ],
      ),
    );

    if (chosen == null) return;
    setState(() => _goalCareerId = chosen);
  }
}

class _MathsCard extends StatelessWidget {
  final SubjectAdvice advice;
  const _MathsCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final avoidMathLit = advice.readiness == SubjectReadiness.notAdvised ||
        advice.readiness == SubjectReadiness.risky;

    return GlassCard(
      tint: avoidMathLit ? p.danger : p.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                avoidMathLit
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : CupertinoIcons.info_circle_fill,
                size: 19,
                color: avoidMathLit ? p.danger : p.warm,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Mathematics or Mathematical Literacy',
                    style: KhethaText.headline(p)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(advice.reason, style: KhethaText.body(p).copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What Mathematical Literacy closes',
                    style: KhethaText.caption(p).copyWith(
                        fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Engineering, medicine, pharmacy, veterinary science, actuarial science, chartered accountancy, computer science and most BSc degrees. It does not close teaching, social work, law, most BCom streams, the creative fields or any trade.',
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

class _AdviceCard extends StatelessWidget {
  final SubjectAdvice advice;
  const _AdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final colour = switch (advice.readiness) {
      SubjectReadiness.strong => p.accent,
      SubjectReadiness.viable => p.accent,
      SubjectReadiness.risky => p.warm,
      SubjectReadiness.notAdvised => p.danger,
    };

    return GlassCard(
      padding: const EdgeInsets.all(15),
      tint: colour,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(advice.subject, style: KhethaText.headline(p)),
              ),
              const SizedBox(width: 8),
              Chip(advice.readiness.label, color: colour),
            ],
          ),
          const SizedBox(height: 7),
          Text(advice.reason, style: KhethaText.caption(p)),
          if (advice.neededForGoal) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(CupertinoIcons.arrow_right_circle_fill,
                    size: 13, color: p.warm),
                const SizedBox(width: 7),
                Expanded(
                  child: Text('Required for the career you picked.',
                      style: KhethaText.caption(p).copyWith(
                          color: p.textPrimary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockerCard extends StatelessWidget {
  final Career goal;
  final List<SubjectAdvice> blockers;

  const _BlockerCard({required this.goal, required this.blockers});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final first = blockers.first;

    return GlassCard(
      tint: p.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.flag_fill, size: 18, color: p.warm),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Still set on ${goal.title}?',
                    style: KhethaText.headline(p)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'It needs ${blockers.map((b) => b.subject).join(' and ')}, and on your current marks that would be hard. That is not a no. You have three years, and the marks that matter are the ones you finish with.',
            style: KhethaText.body(p).copyWith(fontSize: 15),
          ),
          const SizedBox(height: 10),
          for (final b in blockers)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('· ${b.reason}', style: KhethaText.caption(p)),
            ),
          const SizedBox(height: 13),
          KhethaButton(
            label: 'Get help with ${first.basedOn}',
            icon: CupertinoIcons.person_2_fill,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => TutorsScreen(subject: first.basedOn),
              ),
            ),
          ),
          const SizedBox(height: 10),
          KhethaButton(
            label: 'See what ${goal.title} actually needs',
            secondary: true,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => CareerDetailScreen(careerId: goal.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
