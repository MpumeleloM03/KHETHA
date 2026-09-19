import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/admissions.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import 'qualification_detail_screen.dart';

/// The Central Applications Clearing House.
///
/// CACH is the DHET service for learners who did not get a place: it matches
/// them against the spaces institutions still have open after registration.
/// Every year learners who qualify for something end up out of the system
/// entirely because nobody told them this existed, which is exactly the kind of
/// gap a mobile app can close.
class CachScreen extends StatelessWidget {
  const CachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final results = app.results;

    // What is still genuinely open on these results - the list worth taking
    // into a clearing-house conversation.
    final open = AdmissionsEngine.openTo(results);
    final lowBar = open.where((e) => e.qualification.apsRequired <= 24).toList();
    final tvet = open
        .where((e) => e.qualification.providerType.contains('TVET'))
        .toList();

    return KhethaDetailPage(
      title: 'Clearing House',
      slivers: [
        SliverSection(children: [
          GlassCard(
            tint: p.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You still have options', style: KhethaText.title(p)),
                const SizedBox(height: 7),
                Text(
                  'CACH is run by the Department of Higher Education and Training for learners who did not get a place. You register once, and institutions with open spaces come to you. It is free.',
                  style: KhethaText.body(p),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text('How it works', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in const [
                  (
                    '1',
                    'Register with CACH',
                    'Online, by SMS, or through the Khetha advice line. You need your ID number and your final results.'
                  ),
                  (
                    '2',
                    'Your details go on the national list',
                    'Universities, universities of technology and TVET colleges with unfilled places search that list.'
                  ),
                  (
                    '3',
                    'An institution contacts you',
                    'They offer you a place in a programme you qualify for. It may not be your first choice, and it is a real place.'
                  ),
                  (
                    '4',
                    'You decide',
                    'Take it, or hold out. If you take it, you are registered for the year rather than sitting out.'
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.accentMuted,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(step.$1,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.accent)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step.$2,
                                  style: KhethaText.body(p)
                                      .copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(step.$3, style: KhethaText.caption(p)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          KhethaButton(
            label: 'Open the CACH website',
            icon: CupertinoIcons.globe,
            onTap: () => _open(context, 'https://www.dhet.gov.za/'),
          ),
          const SizedBox(height: 10),
          KhethaButton(
            label: 'Call the Khetha advice line',
            icon: CupertinoIcons.phone_fill,
            secondary: true,
            onTap: () => _open(context, 'tel:0860999123'),
          ),

          if (results != null) ...[
            const SizedBox(height: 26),
            Text('Take this list with you', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 6),
            Text(
              'These are the qualifications your results already open. Knowing them makes the clearing-house call a short one.',
              style: KhethaText.caption(p),
            ),
            const SizedBox(height: 12),

            if (lowBar.isEmpty && tvet.isEmpty)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start with a TVET college',
                        style: KhethaText.headline(p)),
                    const SizedBox(height: 6),
                    Text(
                      'NC(V) programmes start from Grade 9, have no APS requirement, and NSFAS funds them in full. They articulate into diplomas and then degrees.',
                      style: KhethaText.caption(p),
                    ),
                  ],
                ),
              )
            else
              GlassSection(
                footer:
                    'Spaces at the clearing house go quickly, and the ones that last longest are usually at TVET colleges and in less-subscribed fields.',
                children: [
                  for (final e in {...tvet, ...lowBar}.take(8))
                    GlassRow(
                      icon: CupertinoIcons.checkmark_seal_fill,
                      title: e.qualification.title,
                      subtitle:
                          '${e.qualification.nqfLevel} · ${e.qualification.providerType}',
                      showChevron: true,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => QualificationDetailScreen(
                              qualificationId: e.qualification.id),
                        ),
                      ),
                    ),
                ],
              ),
          ] else ...[
            const SizedBox(height: 22),
            GlassCard(
              tint: p.warm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add your results first',
                      style: KhethaText.headline(p)),
                  const SizedBox(height: 6),
                  Text(
                    'CACH will ask what you qualify for. Add your results and Khetha Go can hand you that list.',
                    style: KhethaText.caption(p),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),
          GlassCard(
            tint: p.warm,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.exclamationmark_shield_fill,
                    size: 18, color: p.warm),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nobody should charge you for this',
                          style: KhethaText.headline(p)),
                      const SizedBox(height: 6),
                      Text(
                        'CACH registration is free. Every January there are people who charge desperate families to "secure a place". They cannot. Call the advice line before you pay anyone anything.',
                        style: KhethaText.caption(p),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Institution and programme records here come from the demo dataset. Confirm open spaces with CACH or the institution directly.',
            textAlign: TextAlign.center,
            style: KhethaText.caption(p).copyWith(color: p.textTertiary),
          ),
        ]),
      ],
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(url.startsWith('tel:') ? 'Call 086 099 9123?' : 'Open in browser?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('This leaves Khetha Go and opens another app on your phone.'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing useful to do if the handler is unavailable.
    }
  }
}
