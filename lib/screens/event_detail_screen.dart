import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/career_models.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';

/// Everything about one career event, and the things a learner can do about it.
class EventDetailScreen extends StatelessWidget {
  final CareerEvent event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final isLocal = app.profile.province == event.province;

    return KhethaDetailPage(
      title: event.title,
      slivers: [
        SliverSection(children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(event.date, color: p.accent, icon: CupertinoIcons.calendar),
              Chip(event.province, color: p.textSecondary),
              if (isLocal)
                Chip('In your province',
                    color: p.warm, icon: CupertinoIcons.location_solid),
            ],
          ),
          const SizedBox(height: 16),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What it is', style: KhethaText.headline(p)),
                const SizedBox(height: 8),
                Text(event.description, style: KhethaText.body(p)),
                const SizedBox(height: 14),
                _Detail(
                    icon: CupertinoIcons.building_2_fill,
                    label: 'Hosted by',
                    value: event.host),
                const SizedBox(height: 10),
                _Detail(
                    icon: CupertinoIcons.location_solid,
                    label: 'Where',
                    value: '${event.location}, ${event.province}'),
                const SizedBox(height: 10),
                _Detail(
                    icon: CupertinoIcons.calendar,
                    label: 'When',
                    value: event.date),
              ],
            ),
          ),
          const SizedBox(height: 14),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What to take with you', style: KhethaText.headline(p)),
                const SizedBox(height: 10),
                for (final item in const [
                  'Your ID or birth certificate',
                  'Your latest results statement',
                  'A pen and something to write on',
                  'Your APS, so you can ask the right questions at each stand',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(CupertinoIcons.checkmark_circle,
                            size: 15, color: p.accent),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Text(item, style: KhethaText.caption(p))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          KhethaButton(
            label: 'Remind me about this',
            icon: CupertinoIcons.bell_fill,
            onTap: () async {
              if (!app.consentReminders) {
                await _explainConsent(context);
                return;
              }
              await NotificationService.instance.showEventReminder(event.title);
              if (!context.mounted) return;
              await showCupertinoDialog<void>(
                context: context,
                builder: (c) => CupertinoAlertDialog(
                  title: const Text('Reminder set'),
                  content: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'Khetha Go will nudge you before this event. Reminders are scheduled on this phone.'),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          KhethaButton(
            label: 'Search jobs in this field on LinkedIn',
            icon: CupertinoIcons.briefcase_fill,
            secondary: true,
            onTap: () => _openLinkedIn(context, event.title),
          ),
          const SizedBox(height: 10),
          Text(
            'LinkedIn opens in your browser with a search for roles in South Africa. Khetha Go does not read your LinkedIn account or post anything.',
            textAlign: TextAlign.center,
            style: KhethaText.caption(p).copyWith(color: p.textTertiary),
          ),
        ]),
      ],
    );
  }

  Future<void> _explainConsent(BuildContext context) => showCupertinoDialog<void>(
        context: context,
        builder: (c) => CupertinoAlertDialog(
          title: const Text('Reminders are off'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
                'Turn on reminder consent in Settings and Khetha Go can nudge you before events like this one.'),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

  Future<void> _openLinkedIn(BuildContext context, String keywords) async {
    final uri = Uri.https('www.linkedin.com', '/jobs/search/', {
      'keywords': keywords,
      'location': 'South Africa',
    });

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: const Text('Open LinkedIn?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
              'This leaves Khetha Go and opens LinkedIn in your browser. It uses data.'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Open'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing useful to do if no browser is available.
    }
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Detail({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: p.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: KhethaText.sectionLabel(p)),
              const SizedBox(height: 2),
              Text(value, style: KhethaText.body(p)),
            ],
          ),
        ),
      ],
    );
  }
}
