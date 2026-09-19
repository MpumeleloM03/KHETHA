import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/ncap_repository.dart';
import '../l10n/strings.dart';
import '../models/career_models.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import 'event_detail_screen.dart';
import 'faq_screen.dart';
import 'tutors_screen.dart';

/// Access to a human.
///
/// The brief asks for in-app access to Khetha's career advice directory and
/// contact channels. Free channels are listed first and labelled, because for
/// a learner with R3 of airtime the cost of the call is the deciding factor,
/// not the convenience of it.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final s = S.of(context);

    final free = Ncap.channels.where((c) => c.freeToUse).toList();
    final other = Ncap.channels.where((c) => !c.freeToUse).toList();

    return KhethaPage(
      title: s.tabSupport,
      subtitle:
          'An algorithm can rank careers. It cannot know your circumstances. These people can.',
      slivers: [
        SliverSection(children: [
          GlassCard(
            tint: p.accent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.person_2_fill, size: 20, color: p.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khetha Career Development Services',
                          style: KhethaText.headline(p)),
                      const SizedBox(height: 5),
                      Text(
                        'Qualified career practitioners employed by the Department of Higher Education and Training. Advice is free and available in all 11 official languages.',
                        style: KhethaText.caption(p),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text('Free to contact', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          GlassSection(
            footer:
                'These channels cost you nothing. WhatsApp uses data you may already have; the advice line is a toll-free number.',
            children: [
              for (final c in free) _channelRow(context, c, p),
            ],
          ),

          const SizedBox(height: 22),
          GlassCard(
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const FaqScreen()),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(CupertinoIcons.chat_bubble_text_fill,
                      size: 20, color: p.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FAQ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          )),
                      Text('Find answers to common questions',
                          style: TextStyle(
                              fontSize: 13, color: p.textSecondary)),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right,
                    size: 14, color: p.textTertiary),
              ],
            ),
          ),

          const SizedBox(height: 22),
          Text('Other channels', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          GlassSection(
            children: [
              for (final c in other) _channelRow(context, c, p),
            ],
          ),

          const SizedBox(height: 26),
          Text('Career events near you', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          for (final e in Ncap.events) ...[
            _EventCard(event: e),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 16),
          Text('Help with a subject', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          GlassSection(
            footer:
                'Free options first. The Second Chance Programme runs at district offices countrywide and costs nothing.',
            children: [
              for (final subject in const [
                'Mathematics',
                'Physical Sciences',
                'Accounting',
                'Life Sciences',
                'English Home Language',
              ])
                GlassRow(
                  icon: CupertinoIcons.person_2_fill,
                  title: subject,
                  showChevron: true,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => TutorsScreen(subject: subject),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          GlassCard(
            tint: p.warm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_shield_fill,
                        size: 18, color: p.warm),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text('Before you pay anyone',
                          style: KhethaText.headline(p)),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'Khetha advice is always free. No legitimate institution asks for a registration fee over WhatsApp, and every real qualification has a SAQA ID you can check. If something feels wrong, call the advice line before you pay.',
                  style: KhethaText.caption(p),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _channelRow(BuildContext context, AdviceChannel c, Palette p) {
    return GlassRow(
      icon: _iconFor(c.kind),
      iconColor: c.freeToUse ? p.accent : p.textSecondary,
      title: c.name,
      subtitle: '${c.description}\n${c.availability}',
      trailing: c.freeToUse
          ? Chip(S.of(context).freeToUse, color: p.accent)
          : null,
      showChevron: true,
      onTap: () => _open(context, c),
    );
  }

  IconData _iconFor(String kind) => switch (kind) {
        'phone' => CupertinoIcons.phone_fill,
        'whatsapp' => CupertinoIcons.chat_bubble_fill,
        'sms' => CupertinoIcons.text_bubble_fill,
        'email' => CupertinoIcons.mail_solid,
        'web' => CupertinoIcons.globe,
        _ => CupertinoIcons.info_circle_fill,
      };

  /// Confirms before handing off to the phone, mail or browser app. A learner
  /// should never be surprised by a dialler opening, and the number they are
  /// about to call is shown in full first.
  Future<void> _open(BuildContext context, AdviceChannel c) async {
    final p = Palette.of(context);

    final uri = switch (c.kind) {
      'phone' => Uri.parse('tel:${c.value}'),
      'whatsapp' =>
        Uri.parse('https://wa.me/27${c.value.replaceFirst(RegExp(r"^0"), "")}'),
      'sms' => Uri.parse('sms:${c.value}?body=Career'),
      'email' => Uri.parse(
          'mailto:${c.value}?subject=Career%20guidance%20question'),
      _ => Uri.parse(c.value),
    };

    final action = switch (c.kind) {
      'phone' => 'Call ${_pretty(c.value)}',
      'whatsapp' => 'Open WhatsApp',
      'sms' => 'Send an SMS to ${_pretty(c.value)}',
      'email' => 'Email ${c.value}',
      _ => 'Open ${uri.host}',
    };

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(c.name),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$action?\n\nThis leaves Khetha Go and opens another app on your phone.',
            style: KhethaText.caption(p),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Could not open that'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Reach them directly on ${c.value}.'),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _pretty(String number) {
    if (number.length == 10) {
      return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    }
    return number;
  }
}

class _EventCard extends StatelessWidget {
  final CareerEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(15),
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => EventDetailScreen(event: event),
        ),
      ),
      semanticLabel: '${event.title}, ${event.date}, ${event.location}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: p.accentMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  event.date.split(' ').first,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
                Text(
                  event.date.split(' ').last.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: KhethaText.headline(p)),
                const SizedBox(height: 3),
                Text('${event.location} · ${event.province}',
                    style: KhethaText.caption(p)),
                const SizedBox(height: 7),
                Text(event.description,
                    style: KhethaText.caption(p),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
        ],
      ),
    );
  }
}
