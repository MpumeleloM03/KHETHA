import 'package:flutter/cupertino.dart';

import '../data/admissions.dart';
import '../data/ncap_repository.dart';
import '../models/results_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/listen_button.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';
import 'grade9_screen.dart';
import 'qualification_detail_screen.dart';
import 'scan_results_screen.dart';

/// Every qualification in the dataset, checked against the learner's results.
///
/// Sorted so the open doors are at the top and the closed ones are still
/// visible below with the reason attached. A learner is better served by
/// knowing why a door is shut than by not being shown it.
class EligibilityScreen extends StatefulWidget {
  /// Optional starting filter, used when arriving from a career.
  final String? field;
  const EligibilityScreen({super.key, this.field});

  @override
  State<EligibilityScreen> createState() => _EligibilityScreenState();
}

class _EligibilityScreenState extends State<EligibilityScreen> {
  late String? _field = widget.field;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final results = app.results;

    final all = AdmissionsEngine.assessAll(results, field: _field)
        .where((e) =>
            _query.isEmpty ||
            e.qualification.title.toLowerCase().contains(_query.toLowerCase()) ||
            e.qualification.field.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final qualifies =
        all.where((e) => e.status == EligibilityStatus.qualifies).toList();
    final near = all.where((e) => e.status == EligibilityStatus.nearMiss).toList();
    final closed = all.where((e) => e.status == EligibilityStatus.notYet).toList();
    final unknown = all
        .where((e) =>
            e.status == EligibilityStatus.unknown ||
            e.status == EligibilityStatus.tooEarly)
        .toList();

    return KhethaDetailPage(
      title: 'What you can study',
      slivers: [
        SliverSection(children: [
          if (results == null)
            const _NoResultsCard()
          else if (!results.kind.countsTowardsAdmission)
            const _TooEarlyCard()
          else
            _SummaryCard(
              aps: results.aps,
              passType: results.passType,
              open: qualifies.length,
              total: all.length,
              provisional: results.kind.isProvisional,
            ),
          const SizedBox(height: 16),

          CupertinoSearchTextField(
            placeholder: 'Search qualifications',
            onChanged: (v) => setState(() => _query = v),
            backgroundColor: p.surface.withValues(alpha: 0.6),
            style: KhethaText.body(p),
            itemColor: p.textTertiary,
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FieldChip(
                  label: 'All fields',
                  active: _field == null,
                  onTap: () => setState(() => _field = null),
                ),
                for (final field in Ncap.subjects.keys)
                  _FieldChip(
                    label: field,
                    active: _field == field,
                    onTap: () => setState(
                        () => _field = _field == field ? null : field),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (unknown.isNotEmpty)
            ..._group(
                context,
                results != null && !results.kind.countsTowardsAdmission
                    ? 'What these could lead to'
                    : 'All qualifications',
                unknown,
                p),
          if (qualifies.isNotEmpty)
            ..._group(context, 'Open to you now', qualifies, p,
                tint: p.accent),
          if (near.isNotEmpty)
            ..._group(context, 'Just short', near, p, tint: p.warm),
          if (closed.isNotEmpty)
            ..._group(context, 'Not yet - tap to see a way through', closed, p,
                tint: p.textSecondary),

          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(CupertinoIcons.search, size: 32, color: p.textTertiary),
                  const SizedBox(height: 12),
                  Text('Nothing matches that search',
                      style: KhethaText.secondary(p)),
                ],
              ),
            ),
        ]),
      ],
    );
  }

  List<Widget> _group(
    BuildContext context,
    String heading,
    List<Eligibility> items,
    Palette p, {
    Color? tint,
  }) {
    return [
      Row(
        children: [
          Expanded(child: Text(heading, style: KhethaText.sectionLabel(p))),
          Text('${items.length}',
              style: KhethaText.caption(p)
                  .copyWith(fontWeight: FontWeight.w700, color: tint)),
        ],
      ),
      const SizedBox(height: 8),
      for (final item in items) ...[
        _EligibilityCard(eligibility: item),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 14),
    ];
  }
}

/// Shown when the learner has Grade 9 marks rather than matric results.
class _TooEarlyCard extends StatelessWidget {
  const _TooEarlyCard();

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
              Icon(CupertinoIcons.clock_fill, size: 18, color: p.warm),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Too early for an APS',
                    style: KhethaText.headline(p)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Entry requirements are set against matric results, so your Grade 9 marks cannot be scored against them. What they can tell you is which subjects to take so that these stay open.',
            style: KhethaText.caption(p),
          ),
          const SizedBox(height: 13),
          KhethaButton(
            label: 'Choose my Grade 10 subjects',
            icon: CupertinoIcons.pencil_outline,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const Grade9Screen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsCard extends StatelessWidget {
  const _NoResultsCard();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      tint: p.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add your results first', style: KhethaText.headline(p)),
          const SizedBox(height: 5),
          Text(
            'Without your marks this is just a list of courses. With them, it becomes a list of the ones you can actually get into.',
            style: KhethaText.caption(p),
          ),
          const SizedBox(height: 14),
          KhethaButton(
            label: 'Scan or enter my results',
            icon: CupertinoIcons.doc_text_viewfinder,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const ScanResultsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int aps;
  final String passType;
  final int open;
  final int total;
  final bool provisional;

  const _SummaryCard({
    required this.aps,
    required this.passType,
    required this.open,
    required this.total,
    required this.provisional,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScoreRing(
                percent: ((aps / 42) * 100).round(),
                label: 'APS $aps',
                size: 66,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('APS $aps · $passType pass',
                        style: KhethaText.headline(p)),
                    const SizedBox(height: 4),
                    Text(
                      open == 0
                          ? 'Nothing in this list is open on these results yet. Tap any of them to see a route through.'
                          : '$open of $total qualifications are open to you right now.',
                      style: KhethaText.caption(p),
                    ),
                    ListenButton(
                      id: 'eligibility-summary',
                      text: 'APS $aps, $passType pass. ${open == 0 ? 'Nothing in this list is open on these results yet.' : '$open of $total qualifications are open to you right now.'}',
                      label: 'your results summary',
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provisional) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p.warmMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(CupertinoIcons.info_circle_fill, size: 14, color: p.warm),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'These are not final results, so everything here is an estimate to plan with. Only your final NSC decides admission.',
                      style: KhethaText.caption(p),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  final Eligibility eligibility;
  const _EligibilityCard({required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final q = eligibility.qualification;

    final (color, icon) = switch (eligibility.status) {
      EligibilityStatus.qualifies => (p.accent, CupertinoIcons.checkmark_seal_fill),
      EligibilityStatus.nearMiss => (p.warm, CupertinoIcons.exclamationmark_circle_fill),
      EligibilityStatus.notYet => (p.textSecondary, CupertinoIcons.lock_fill),
      EligibilityStatus.unknown => (p.textTertiary, CupertinoIcons.question_circle_fill),
      EligibilityStatus.tooEarly => (p.warm, CupertinoIcons.clock_fill),
    };

    return GlassCard(
      padding: const EdgeInsets.all(15),
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => QualificationDetailScreen(qualificationId: q.id),
        ),
      ),
      semanticLabel: '${q.title}. ${eligibility.status.label}. ${eligibility.summary}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.title, style: KhethaText.headline(p)),
                    const SizedBox(height: 3),
                    Text('${q.nqfLevel} · ${q.duration} · ${q.providerType}',
                        style: KhethaText.caption(p)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(eligibility.status.label, color: color),
              if (q.apsRequired > 0)
                Chip('APS ${q.apsRequired}',
                    color: eligibility.status == EligibilityStatus.qualifies
                        ? p.textSecondary
                        : (eligibility.apsHave >= q.apsRequired
                            ? p.textSecondary
                            : p.danger)),
              if (q.isExtendedProgramme)
                Chip('Extended programme', color: p.warm),
            ],
          ),
          if (eligibility.status != EligibilityStatus.unknown) ...[
            const SizedBox(height: 9),
            Text(
              eligibility.summary,
              style: KhethaText.caption(p),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FieldChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? p.onAccent : p.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
