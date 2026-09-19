import 'package:flutter/cupertino.dart';

import '../data/admissions.dart';
import '../data/ncap_repository.dart';
import '../models/career_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';
import 'apply_screen.dart';
import 'career_detail_screen.dart';
import 'tutors_screen.dart';

/// One qualification, checked line by line against the learner's own results.
///
/// When the answer is no, this screen does not stop at no. The bridging routes
/// below the requirements are the point of it: a closed door with three ways
/// around it is a different message from a closed door.
class QualificationDetailScreen extends StatelessWidget {
  final String qualificationId;
  const QualificationDetailScreen({super.key, required this.qualificationId});

  @override
  Widget build(BuildContext context) {
    final q = Ncap.qualificationById(qualificationId);
    if (q == null) {
      return const KhethaDetailPage(title: 'Not found', slivers: []);
    }

    final p = Palette.of(context);
    final app = AppScope.of(context);
    final results = app.results;
    final eligibility = AdmissionsEngine.assess(q, results);
    final routes = AdmissionsEngine.routesTo(q, results);

    final careers = q.leadsToCareerIds
        .map(Ncap.careerById)
        .whereType<Career>()
        .toList();
    final providers = Ncap.providers
        .where((prov) => prov.offeredFields.contains(q.field))
        .toList();
    final localProviders = app.profile.province == null
        ? const <LearningProvider>[]
        : providers.where((prov) => prov.province == app.profile.province).toList();

    final (statusColor, statusIcon) = switch (eligibility.status) {
      EligibilityStatus.qualifies => (p.accent, CupertinoIcons.checkmark_seal_fill),
      EligibilityStatus.nearMiss => (p.warm, CupertinoIcons.exclamationmark_circle_fill),
      EligibilityStatus.notYet => (p.danger, CupertinoIcons.lock_fill),
      EligibilityStatus.unknown => (p.textTertiary, CupertinoIcons.question_circle_fill),
      EligibilityStatus.tooEarly => (p.warm, CupertinoIcons.clock_fill),
    };

    return KhethaDetailPage(
      title: q.title,
      slivers: [
        SliverSection(children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(q.nqfLevel, color: p.accent),
              Chip(q.duration, color: p.textSecondary),
              Chip('SAQA ${q.saqaId}', color: p.textSecondary),
              if (q.isExtendedProgramme)
                Chip('Extended programme', color: p.warm),
            ],
          ),
          const SizedBox(height: 16),

          GlassCard(
            tint: statusColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, size: 22, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eligibility.status.label,
                          style: KhethaText.title(p)),
                      const SizedBox(height: 5),
                      Text(eligibility.summary, style: KhethaText.body(p)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _RequirementsCard(eligibility: eligibility),

          if (routes.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Icon(CupertinoIcons.arrow_branch, size: 16, color: p.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Ways to get there anyway',
                      style: KhethaText.sectionLabel(p)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Missing the entry requirements does not close this off. These routes all end at ${q.title}.',
              style: KhethaText.caption(p),
            ),
            const SizedBox(height: 12),
            for (final route in routes) ...[
              _RouteCard(route: route),
              const SizedBox(height: 12),
            ],
          ],

          if (eligibility.status != EligibilityStatus.qualifies &&
              eligibility.shortfalls.any((s) =>
                  s.label != 'APS' && s.label != 'NSC pass type')) ...[
            const SizedBox(height: 6),
            _TutorPrompt(
              subject: eligibility.shortfalls
                  .firstWhere((s) =>
                      s.label != 'APS' && s.label != 'NSC pass type')
                  .label,
            ),
          ],

          if (careers.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Where it leads', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassSection(
              children: [
                for (final c in careers)
                  GlassRow(
                    icon: CupertinoIcons.briefcase_fill,
                    title: c.title,
                    subtitle: c.scarceSkill
                        ? 'In high demand nationally'
                        : c.sector,
                    iconColor: c.scarceSkill ? p.warm : p.accent,
                    showChevron: true,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => CareerDetailScreen(careerId: c.id),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 22),
          Text(
            localProviders.isNotEmpty
                ? 'Offered in ${app.profile.province}'
                : 'Where it is offered',
            style: KhethaText.sectionLabel(p),
          ),
          const SizedBox(height: 8),
          GlassSection(
            footer: localProviders.isEmpty && app.profile.province != null
                ? 'No institution in ${app.profile.province} offers this field in the demo dataset.'
                : null,
            children: [
              for (final prov
                  in (localProviders.isNotEmpty ? localProviders : providers.take(4)))
                GlassRow(
                  icon: CupertinoIcons.building_2_fill,
                  title: prov.name,
                  subtitle: '${prov.town} · ${prov.type}',
                ),
            ],
          ),

          const SizedBox(height: 22),
          KhethaButton(
            label: eligibility.status == EligibilityStatus.notYet
                ? 'Apply anyway'
                : 'Apply to this programme',
            icon: CupertinoIcons.paperplane_fill,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => ApplyScreen(qualificationId: q.id),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Institutions set their own requirements and may admit above the published minimum. Confirm with the institution before you rely on anything here.',
            textAlign: TextAlign.center,
            style: KhethaText.caption(p).copyWith(color: p.textTertiary),
          ),
        ]),
      ],
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  final Eligibility eligibility;
  const _RequirementsCard({required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final results = app.results;
    final q = eligibility.qualification;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What it needs', style: KhethaText.headline(p)),
          const SizedBox(height: 12),

          _Check(
            label: q.passRequired.label,
            met: results == null
                ? null
                : eligibility.shortfalls.every((s) => s.label != 'NSC pass type'),
            detail: results == null
                ? 'Add your results to check.'
                : 'You have a ${results.passType} pass.',
          ),

          if (q.apsRequired > 0) ...[
            const SizedBox(height: 10),
            _Check(
              label: 'APS ${q.apsRequired}',
              met: results == null ? null : eligibility.apsHave >= q.apsRequired,
              detail: results == null
                  ? 'Add your results to check.'
                  : 'You have ${eligibility.apsHave}.',
            ),
            if (results != null) ...[
              const SizedBox(height: 10),
              LabelledBar(
                label: 'Your APS against the requirement',
                value: (eligibility.apsHave / q.apsRequired).clamp(0.0, 1.0),
                valueLabel: '${eligibility.apsHave} / ${q.apsRequired}',
                color: eligibility.apsHave >= q.apsRequired ? p.accent : p.warm,
              ),
            ],
          ],

          for (final req in q.requirements) ...[
            const SizedBox(height: 10),
            _Check(
              label: req.description,
              met: results == null
                  ? null
                  : eligibility.shortfalls.every((s) => s.label != req.label),
              detail: results == null
                  ? 'Add your results to check.'
                  : _markDetail(req, eligibility),
            ),
          ],

          const SizedBox(height: 14),
          Text(q.minimumRequirements, style: KhethaText.caption(p)),
        ],
      ),
    );
  }

  String _markDetail(SubjectRequirement req, Eligibility eligibility) {
    for (final s in eligibility.shortfalls) {
      if (s.label == req.label) return s.detail;
    }
    return 'Met.';
  }
}

class _Check extends StatelessWidget {
  final String label;
  final bool? met;
  final String detail;

  const _Check({required this.label, required this.met, required this.detail});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (icon, color) = switch (met) {
      true => (CupertinoIcons.checkmark_circle_fill, p.accent),
      false => (CupertinoIcons.xmark_circle_fill, p.danger),
      _ => (CupertinoIcons.circle, p.textTertiary),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: KhethaText.body(p)),
              const SizedBox(height: 2),
              Text(detail, style: KhethaText.caption(p)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final BridgingRoute route;
  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return GlassCard(
      tint: p.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(route.title, style: KhethaText.headline(p))),
              const SizedBox(width: 8),
              Chip(route.totalDuration, color: p.textSecondary),
            ],
          ),
          const SizedBox(height: 7),
          Text(route.summary, style: KhethaText.caption(p)),
          const SizedBox(height: 14),

          for (var i = 0; i < route.steps.length; i++)
            _Step(
              step: route.steps[i],
              index: i + 1,
              isLast: i == route.steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final RouteStep step;
  final int index;
  final bool isLast;

  const _Step({required this.step, required this.index, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    final icon = switch (step.kind) {
      RouteStepKind.apply => CupertinoIcons.paperplane_fill,
      RouteStepKind.study => CupertinoIcons.book_fill,
      RouteStepKind.upgrade => CupertinoIcons.arrow_up_circle_fill,
      RouteStepKind.work => CupertinoIcons.pencil_circle_fill,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.accentMuted,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 14, color: p.accent),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: p.separator,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title on its own line. Sharing a row with the duration
                  // squeezed it to one character per line whenever the timing
                  // text was long ("Exams in May/June or October/November").
                  Text(step.title,
                      style: KhethaText.body(p)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(CupertinoIcons.clock, size: 11, color: p.textTertiary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(step.duration,
                            style: KhethaText.caption(p)
                                .copyWith(color: p.textTertiary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(step.detail, style: KhethaText.caption(p)),
                  if (step.qualificationId != null) ...[
                    const SizedBox(height: 7),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 30),
                      onPressed: () => Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => QualificationDetailScreen(
                            qualificationId: step.qualificationId!,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('See this qualification',
                              style: KhethaText.caption(p).copyWith(
                                  color: p.accent,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Icon(CupertinoIcons.chevron_right,
                              size: 11, color: p.accent),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorPrompt extends StatelessWidget {
  final String subject;
  const _TutorPrompt({required this.subject});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      tint: p.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.person_2_fill, size: 18, color: p.warm),
              const SizedBox(width: 9),
              Expanded(
                child: Text('Set on this one anyway?',
                    style: KhethaText.headline(p)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If this is what you want, the answer is to lift the mark rather than to change the plan. There is free help, and there are tutors near you.',
            style: KhethaText.caption(p),
          ),
          const SizedBox(height: 13),
          KhethaButton(
            label: 'Get help with $subject',
            icon: CupertinoIcons.person_2_fill,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => TutorsScreen(subject: subject),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
