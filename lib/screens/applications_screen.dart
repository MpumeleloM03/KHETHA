import 'package:flutter/cupertino.dart';

import '../data/ncap_repository.dart';
import '../models/application_models.dart';
import '../services/application_service.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';
import 'apply_screen.dart';
import 'cach_screen.dart';
import 'documents_screen.dart';
import 'eligibility_screen.dart';
import 'qualification_detail_screen.dart';
import 'scan_results_screen.dart';

/// The Apply tab: one document pack, many institutions, one submission.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);

    final drafts = app.draftApplications;
    final sent = app.applications
        .where((a) => a.state != ApplicationState.draft)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final offers =
        sent.where((a) => a.state == ApplicationState.offered).toList();
    final needsClearing = ApplicationService.needsClearingHouse(app.applications);
    final missingDocs = app.missingRequiredDocuments;
    final canSubmit = drafts.isNotEmpty && missingDocs.isEmpty && app.idNumber != null;

    return KhethaPage(
      title: 'Apply',
      subtitle:
          'Build the pack once, send it to every institution you choose.',
      slivers: [
        SliverSection(children: [
          if (app.results == null) ...[
            _ActionCard(
              icon: CupertinoIcons.doc_text_viewfinder,
              title: 'Start with your results',
              body:
                  'Scan or type your marks and Khetha Go can tell you which institutions to apply to rather than guessing.',
              label: 'Add my results',
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(builder: (_) => const ScanResultsScreen()),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _ReadinessCard(
            missingDocs: missingDocs.length,
            hasId: app.idNumber != null,
            drafts: drafts.length,
            sent: sent.length,
          ),
          const SizedBox(height: 14),

          GlassSection(
            children: [
              GlassRow(
                icon: CupertinoIcons.doc_on_doc_fill,
                title: 'Documents and ID',
                subtitle: missingDocs.isEmpty && app.idNumber != null
                    ? 'Complete'
                    : '${missingDocs.length} documents still needed',
                iconColor: missingDocs.isEmpty ? p.accent : p.warm,
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(builder: (_) => const DocumentsScreen()),
                ),
              ),
              GlassRow(
                icon: CupertinoIcons.search,
                title: 'Find programmes to apply for',
                subtitle: 'Checked against your own results.',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(builder: (_) => const EligibilityScreen()),
                ),
              ),
            ],
          ),

          if (needsClearing) ...[
            const SizedBox(height: 18),
            _ClearingHouseCard(),
          ],

          if (offers.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Offers', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            for (final a in offers) ...[
              _ApplicationCard(application: a),
              const SizedBox(height: 10),
            ],
          ],

          if (drafts.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text('Ready to send (${drafts.length})',
                      style: KhethaText.sectionLabel(p)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final a in drafts) ...[
              _ApplicationCard(application: a),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            KhethaButton(
              label: canSubmit
                  ? 'Send all ${drafts.length} applications'
                  : 'Complete your documents first',
              icon: CupertinoIcons.paperplane_fill,
              onTap: canSubmit
                  ? () => _submit(context, drafts)
                  : null,
            ),
            if (!canSubmit) ...[
              const SizedBox(height: 10),
              Text(
                app.idNumber == null
                    ? 'Add your ID number under Documents and ID.'
                    : 'Missing: ${missingDocs.map((d) => d.label).join(", ")}.',
                textAlign: TextAlign.center,
                style: KhethaText.caption(p).copyWith(color: p.warm),
              ),
            ],
          ],

          if (sent.where((a) => a.state != ApplicationState.offered).isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Sent', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            for (final a in sent.where((a) => a.state != ApplicationState.offered)) ...[
              _ApplicationCard(application: a),
              const SizedBox(height: 10),
            ],
          ],

          if (app.applications.isEmpty) ...[
            const SizedBox(height: 18),
            _ActionCard(
              icon: CupertinoIcons.compass_fill,
              title: 'Nothing added yet',
              body:
                  'Find a programme you qualify for, pick the institutions, and it lands here as a draft.',
              label: 'Find programmes',
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(builder: (_) => const EligibilityScreen()),
              ),
            ),
          ],

          const SizedBox(height: 22),
          const _PrototypeNotice(),
        ]),
      ],
    );
  }

  Future<void> _submit(
      BuildContext context, List<InstitutionApplication> drafts) async {
    await showCupertinoModalPopup<void>(
      context: context,
      // Without this the sheet is pushed inside the tab's navigator, which
      // paints below the floating tab bar: the bar stays tappable during a
      // submission that is deliberately not dismissible.
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => _SubmissionSheet(drafts: drafts),
    );
  }
}

/// Runs the submission and shows it happening, one institution at a time.
class _SubmissionSheet extends StatefulWidget {
  final List<InstitutionApplication> drafts;
  const _SubmissionSheet({required this.drafts});

  @override
  State<_SubmissionSheet> createState() => _SubmissionSheetState();
}

class _SubmissionSheetState extends State<_SubmissionSheet> {
  final _done = <String>{};
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final app = AppScope.read(context);

    await for (final submitted
        in ApplicationService.instance.submit(widget.drafts)) {
      await app.updateApplication(submitted);
      if (!mounted) return;
      setState(() => _done.add(submitted.key));
    }

    // Outcomes are derived from the learner's own results against the published
    // requirements, so the demo stays consistent with reality.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    for (final draft in widget.drafts) {
      final current = app.applications.firstWhere(
        (a) => a.key == draft.key,
        orElse: () => draft,
      );
      await app.updateApplication(
        ApplicationService.instance.decide(current, app.results),
      );
    }

    if (!mounted) return;
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _finished ? 'All sent' : 'Sending your applications',
                style: KhethaText.title(p),
              ),
              const SizedBox(height: 6),
              Text(
                _finished
                    ? 'Every institution has responded. Offers sit at the top of your Apply tab.'
                    : 'One submission per institution. Keep the app open.',
                style: KhethaText.secondary(p),
              ),
              const SizedBox(height: 18),

              for (final draft in widget.drafts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if (_done.contains(draft.key))
                        Icon(CupertinoIcons.checkmark_circle_fill,
                            size: 19, color: p.accent)
                      else
                        const CupertinoActivityIndicator(radius: 9),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          providerById(draft.providerId)?.name ?? 'Institution',
                          style: KhethaText.body(p),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 6),
              if (_finished)
                KhethaButton(
                  label: 'See my results',
                  onTap: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final int missingDocs;
  final bool hasId;
  final int drafts;
  final int sent;

  const _ReadinessCard({
    required this.missingDocs,
    required this.hasId,
    required this.drafts,
    required this.sent,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final steps = 2 + (drafts > 0 || sent > 0 ? 1 : 0);
    var done = 0;
    if (missingDocs == 0) done++;
    if (hasId) done++;
    if (sent > 0) done++;

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
                    Text('Application pack', style: KhethaText.headline(p)),
                    const SizedBox(height: 3),
                    Text(
                      sent > 0
                          ? '$sent sent · $drafts waiting'
                          : missingDocs == 0 && hasId
                              ? 'Ready. Add programmes and send them together.'
                              : 'Add your ID and documents once.',
                      style: KhethaText.caption(p),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('$done/$steps',
                  style: KhethaText.title(p).copyWith(color: p.accent)),
            ],
          ),
          const SizedBox(height: 13),
          ProgressTrack(value: steps == 0 ? 0 : done / steps),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final InstitutionApplication application;
  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final provider = providerById(application.providerId);
    final qualification = Ncap.qualificationById(application.qualificationId);

    final (color, icon) = switch (application.state) {
      ApplicationState.draft => (p.textTertiary, CupertinoIcons.doc_text),
      ApplicationState.submitted => (p.accent, CupertinoIcons.paperplane_fill),
      ApplicationState.underReview => (p.warm, CupertinoIcons.clock_fill),
      ApplicationState.offered => (p.accent, CupertinoIcons.checkmark_seal_fill),
      ApplicationState.waitlisted => (p.warm, CupertinoIcons.hourglass),
      ApplicationState.declined => (p.danger, CupertinoIcons.xmark_circle_fill),
    };

    return GlassCard(
      padding: const EdgeInsets.all(15),
      tint: application.state == ApplicationState.offered ? p.accent : null,
      onTap: qualification == null
          ? null
          : () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) =>
                      QualificationDetailScreen(qualificationId: qualification.id),
                ),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider?.name ?? 'Institution',
                        style: KhethaText.headline(p)),
                    const SizedBox(height: 3),
                    Text(qualification?.title ?? 'Programme',
                        style: KhethaText.caption(p)),
                  ],
                ),
              ),
              if (application.state == ApplicationState.draft)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  onPressed: () => app.removeApplication(application.key),
                  child: Icon(CupertinoIcons.minus_circle,
                      size: 19, color: p.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(application.state.label, color: color),
              if (application.reference != null)
                Chip(application.reference!, color: p.textSecondary),
            ],
          ),
          if (application.note != null) ...[
            const SizedBox(height: 9),
            Text(application.note!, style: KhethaText.caption(p)),
          ],
        ],
      ),
    );
  }
}

class _ClearingHouseCard extends StatelessWidget {
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
              Icon(CupertinoIcons.arrow_2_circlepath, size: 19, color: p.warm),
              const SizedBox(width: 10),
              Expanded(
                child: Text('No offer yet? This is not the end',
                    style: KhethaText.headline(p)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The Central Applications Clearing House exists for exactly this. It matches learners who did not get a place against the spaces institutions still have open.',
            style: KhethaText.caption(p),
          ),
          const SizedBox(height: 13),
          KhethaButton(
            label: 'Go to CACH',
            icon: CupertinoIcons.arrow_right_circle_fill,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const CachScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.label,
    required this.onTap,
  });

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
              Icon(icon, size: 19, color: p.warm),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: KhethaText.headline(p))),
            ],
          ),
          const SizedBox(height: 7),
          Text(body, style: KhethaText.caption(p)),
          const SizedBox(height: 13),
          KhethaButton(label: label, onTap: onTap),
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
                  'No South African institution exposes a public application interface today, so this build demonstrates submission rather than transmitting to institutions. Outcomes shown are calculated from your own results against the published entry requirements. In production this connects to the Central Application Service and the institutions’ own systems.',
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
