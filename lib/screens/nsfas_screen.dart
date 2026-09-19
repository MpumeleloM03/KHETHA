import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../models/funding_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';


class NsfasScreen extends StatelessWidget {
  const NsfasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final nsfas = app.nsfasApplication;

    return KhethaPage(
      title: 'NSFAS',
      subtitle: 'National Student Financial Aid Scheme',
      opaqueBackground: true,
      slivers: [
        SliverSection(children: [
          if (nsfas == null) ...[
            const _NsfasInfoCard(),
            const SizedBox(height: 16),
            const _EligibilityCard(),
            const SizedBox(height: 16),
            _ApplyCard(),
          ] else ...[
            _StatusCard(application: nsfas),
            const SizedBox(height: 16),
            _TimelineCard(application: nsfas),
            if (nsfas.status == NsfasStatus.approved) ...[
              const SizedBox(height: 16),
              const _CongratsCard(
                title: 'NSFAS Approved!',
                message:
                    'Your NSFAS funding has been approved. Your tuition, accommodation and living allowance will be covered.',
              ),
            ],
            if (nsfas.status == NsfasStatus.declined) ...[
              const SizedBox(height: 16),
              _DeclinedCard(application: nsfas),
            ],
          ],
          const SizedBox(height: 20),
          const _NsfasRequirementsCard(),
          const SizedBox(height: 16),
          const _PrototypeNotice(),
        ]),
      ],
    );
  }
}

class _NsfasInfoCard extends StatelessWidget {
  const _NsfasInfoCard();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(CupertinoIcons.creditcard_fill,
                    size: 20, color: p.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('What is NSFAS?', style: KhethaText.title(p)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'NSFAS provides financial aid to eligible students at public universities and TVET colleges in South Africa. It covers tuition, accommodation, a meal allowance, a book allowance and a personal care allowance.',
            style: KhethaText.body(p),
          ),
        ],
      ),
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Am I eligible?', style: KhethaText.headline(p)),
          const SizedBox(height: 10),
          _CheckItem(label: 'South African citizen', checked: true),
          _CheckItem(
              label: 'Combined household income under R350 000', checked: true),
          _CheckItem(
              label: 'Accepted at a public university or TVET college',
              checked: true),
          _CheckItem(label: 'First-time undergraduate or TVET student', checked: true),
          const SizedBox(height: 10),
          Text(
            'SASSA grant recipients are automatically eligible.',
            style: KhethaText.caption(p).copyWith(color: p.accent),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool checked;
  const _CheckItem({required this.label, required this.checked});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            size: 18,
            color: checked ? p.accent : p.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: KhethaText.body(p)),
          ),
        ],
      ),
    );
  }
}

class _ApplyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apply to NSFAS', style: KhethaText.headline(p)),
          const SizedBox(height: 8),
          Text(
            'Submit your application and we will track the status for you. Make sure your documents are ready.',
            style: KhethaText.caption(p),
          ),
          const SizedBox(height: 16),
          KhethaButton(
            label: 'Submit NSFAS Application',
            icon: CupertinoIcons.paperplane_fill,
            onTap: () => _apply(context),
          ),
        ],
      ),
    );
  }

  Future<void> _apply(BuildContext context) async {
    final app = AppScope.read(context);
    final ref = 'NSFAS-${DateTime.now().year}-${(Random().nextInt(900000) + 100000)}';
    await app.setNsfasApplication(NsfasApplication(
      status: NsfasStatus.applied,
      referenceNumber: ref,
      appliedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    if (!context.mounted) return;

    // Simulate processing after a delay
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    await app.setNsfasApplication(app.nsfasApplication!.copyWith(
      status: NsfasStatus.documentsSubmitted,
      updatedAt: DateTime.now(),
    ));

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    await app.setNsfasApplication(app.nsfasApplication!.copyWith(
      status: NsfasStatus.underReview,
      updatedAt: DateTime.now(),
    ));

    await Future<void>.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;

    // Decide outcome based on whether they have documents
    final approved = app.documents.isNotEmpty || app.results != null;
    if (approved) {
      await app.setNsfasApplication(app.nsfasApplication!.copyWith(
        status: NsfasStatus.approved,
        updatedAt: DateTime.now(),
      ));
    } else {
      await app.setNsfasApplication(app.nsfasApplication!.copyWith(
        status: NsfasStatus.declined,
        updatedAt: DateTime.now(),
        declineReason: 'Supporting documents incomplete. You may appeal within 30 days.',
      ));
    }
  }
}

class _StatusCard extends StatelessWidget {
  final NsfasApplication application;
  const _StatusCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (color, icon) = switch (application.status) {
      NsfasStatus.notApplied => (p.textTertiary, CupertinoIcons.doc_text),
      NsfasStatus.applied => (p.accent, CupertinoIcons.paperplane_fill),
      NsfasStatus.documentsSubmitted => (p.accent, CupertinoIcons.doc_checkmark_fill),
      NsfasStatus.underReview => (p.warm, CupertinoIcons.clock_fill),
      NsfasStatus.approved => (p.accent, CupertinoIcons.checkmark_seal_fill),
      NsfasStatus.declined => (p.danger, CupertinoIcons.xmark_circle_fill),
      NsfasStatus.appealPending => (p.warm, CupertinoIcons.arrow_2_circlepath),
    };

    return GlassCard(
      tint: application.status.isPositive ? p.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NSFAS Application', style: KhethaText.headline(p)),
                    const SizedBox(height: 3),
                    Text(application.status.label,
                        style: KhethaText.body(p).copyWith(color: color)),
                  ],
                ),
              ),
            ],
          ),
          if (application.referenceNumber != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Chip('Ref: ${application.referenceNumber!}', color: p.textSecondary),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final NsfasApplication application;
  const _TimelineCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final steps = [
      ('Application submitted', NsfasStatus.applied),
      ('Documents received', NsfasStatus.documentsSubmitted),
      ('Under review', NsfasStatus.underReview),
      ('Decision', NsfasStatus.approved),
    ];

    final currentIndex = switch (application.status) {
      NsfasStatus.applied => 0,
      NsfasStatus.documentsSubmitted => 1,
      NsfasStatus.underReview => 2,
      NsfasStatus.approved || NsfasStatus.declined => 3,
      _ => -1,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application Timeline', style: KhethaText.headline(p)),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i <= currentIndex
                            ? (i == 3 && application.status == NsfasStatus.declined
                                ? p.danger
                                : p.accent)
                            : p.cardSurface,
                        shape: BoxShape.circle,
                        border: i > currentIndex
                            ? Border.all(color: p.textTertiary, width: 1.5)
                            : null,
                      ),
                      child: i <= currentIndex
                          ? Icon(
                              i == 3 && application.status == NsfasStatus.declined
                                  ? CupertinoIcons.xmark
                                  : CupertinoIcons.checkmark,
                              size: 13,
                              color: CupertinoColors.white,
                            )
                          : null,
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 28,
                        color: i < currentIndex ? p.accent : p.separator,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      i == 3 && application.status == NsfasStatus.declined
                          ? 'Not approved'
                          : steps[i].$1,
                      style: KhethaText.body(p).copyWith(
                        color: i <= currentIndex ? p.textPrimary : p.textTertiary,
                        fontWeight:
                            i == currentIndex ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CongratsCard extends StatelessWidget {
  final String title;
  final String message;
  const _CongratsCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      useGlass: true,
      tint: p.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: KhethaText.title(p).copyWith(color: p.accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: KhethaText.body(p)),
          const SizedBox(height: 14),
          Text(
            'Congratulations on securing your funding. Focus on your studies and make it count.',
            style: KhethaText.caption(p).copyWith(
                color: p.accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DeclinedCard extends StatelessWidget {
  final NsfasApplication application;
  const _DeclinedCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      tint: p.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle_fill,
                  size: 20, color: p.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Application not approved',
                    style: KhethaText.headline(p)),
              ),
            ],
          ),
          if (application.declineReason != null) ...[
            const SizedBox(height: 10),
            Text(application.declineReason!, style: KhethaText.body(p)),
          ],
          const SizedBox(height: 14),
          Text(
            'This is not the end. Look at the bursaries available on the Apply tab, or consider the CACH clearing house.',
            style: KhethaText.caption(p),
          ),
        ],
      ),
    );
  }
}

class _NsfasRequirementsCard extends StatelessWidget {
  const _NsfasRequirementsCard();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Documents needed', style: KhethaText.headline(p)),
          const SizedBox(height: 10),
          _DocItem(label: 'South African ID document'),
          _DocItem(label: 'Latest results or matric certificate'),
          _DocItem(label: 'Proof of income (parent/guardian payslips or SASSA letter)'),
          _DocItem(label: 'Proof of registration or acceptance letter'),
          _DocItem(label: 'Consent form signed by parent/guardian'),
        ],
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final String label;
  const _DocItem({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.doc_fill, size: 14, color: p.textTertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: KhethaText.caption(p))),
        ],
      ),
    );
  }
}

class _PrototypeNotice extends StatelessWidget {
  const _PrototypeNotice();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.info_circle_fill, size: 17, color: p.textTertiary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prototype', style: KhethaText.headline(p)),
                const SizedBox(height: 6),
                Text(
                  'This is a demonstration of the NSFAS application flow. In production this would connect to the NSFAS myNSFAS portal. Outcomes shown are simulated.',
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
