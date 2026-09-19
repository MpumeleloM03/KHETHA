import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/ncap_repository.dart';
import '../models/career_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';

/// Help with a subject that is standing between a learner and what they want.
///
/// Free options are listed first and labelled. The paid listings are demo data
/// and say so: sending a learner to an unvetted stranger on the strength of an
/// invented track record would be worse than showing nothing.
class TutorsScreen extends StatelessWidget {
  final String subject;
  const TutorsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final province = app.profile.province;

    // The requirement label can read "Mathematics or Mathematical Literacy";
    // match on the first named subject.
    final term = subject.split(' or ').first.trim();
    final matches = Ncap.tutorsFor(term, province: province);
    final free = matches.where((t) => t.rate.toLowerCase().contains('free')).toList();
    final paid = matches.where((t) => !t.rate.toLowerCase().contains('free')).toList();

    return KhethaDetailPage(
      title: 'Help with $term',
      slivers: [
        SliverSection(children: [
          GlassCard(
            tint: p.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A mark is not a verdict', style: KhethaText.headline(p)),
                const SizedBox(height: 6),
                Text(
                  'If $term is the only thing between you and the course you want, lifting it is usually a smaller job than changing your whole plan. Start with the free options.',
                  style: KhethaText.caption(p),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          if (free.isNotEmpty) ...[
            Text('Free help', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            for (final tutor in free) ...[
              _TutorCard(tutor: tutor, isFree: true),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
          ],

          if (paid.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    province == null
                        ? 'Tutors'
                        : 'Tutors near $province',
                    style: KhethaText.sectionLabel(p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final tutor in paid) ...[
              _TutorCard(tutor: tutor, isFree: false),
              const SizedBox(height: 10),
            ],
          ],

          if (matches.isEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No listings for $term yet',
                      style: KhethaText.headline(p)),
                  const SizedBox(height: 6),
                  Text(
                    'The Khetha advice line can point you at support in your district. It is free to call.',
                    style: KhethaText.caption(p),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
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
                      Text('About these listings',
                          style: KhethaText.headline(p)),
                      const SizedBox(height: 6),
                      Text(
                        'The paid tutors here are demo entries for the prototype, not real people. In a live build this would be a vetted panel with SACE registration checked and outcomes reported by learners. Never pay anyone up front, and always meet in a public place or online.',
                        style: KhethaText.caption(p),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

class _TutorCard extends StatelessWidget {
  final Tutor tutor;
  final bool isFree;

  const _TutorCard({required this.tutor, required this.isFree});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(15),
      tint: isFree ? p.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isFree ? p.accentMuted : p.warmMuted,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isFree ? CupertinoIcons.building_2_fill : CupertinoIcons.person_fill,
                  size: 19,
                  color: isFree ? p.accent : p.warm,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tutor.name, style: KhethaText.headline(p)),
                    const SizedBox(height: 3),
                    Text('${tutor.town} · ${tutor.mode}',
                        style: KhethaText.caption(p)),
                  ],
                ),
              ),
              if (tutor.rating > 0)
                Row(
                  children: [
                    Icon(CupertinoIcons.star_fill, size: 13, color: p.warm),
                    const SizedBox(width: 3),
                    Text(tutor.rating.toStringAsFixed(1),
                        style: KhethaText.caption(p).copyWith(
                            fontWeight: FontWeight.w700, color: p.textPrimary)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 11),
          Text(tutor.credential, style: KhethaText.caption(p)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(tutor.rate, color: isFree ? p.accent : p.textSecondary),
              if (tutor.learnersHelped > 0)
                Chip('${tutor.learnersHelped} learners', color: p.textSecondary),
              for (final s in tutor.subjects.take(3))
                Chip(s, color: p.textSecondary),
            ],
          ),
          if (isFree) ...[
            const SizedBox(height: 13),
            KhethaButton(
              label: 'Find my nearest centre',
              icon: CupertinoIcons.phone_fill,
              onTap: () async {
                final uri = Uri.parse('tel:0860999123');
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  // The dialler is unavailable on a simulator; the number is
                  // already on screen, so there is nothing further to do.
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
