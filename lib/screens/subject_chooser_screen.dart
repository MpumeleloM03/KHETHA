import 'package:flutter/cupertino.dart';

import '../data/ncap_repository.dart';
import '../data/seed_directory.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import 'career_detail_screen.dart';

/// NCAP's Subject Chooser, with the part the website leaves out: once you pick
/// subjects they are saved to your profile, and every career match afterwards
/// is checked against them. Choosing a subject is the decision that quietly
/// closes doors three years later, so the app names the doors.
class SubjectChooserScreen extends StatefulWidget {
  const SubjectChooserScreen({super.key});

  @override
  State<SubjectChooserScreen> createState() => _SubjectChooserScreenState();
}

class _SubjectChooserScreenState extends State<SubjectChooserScreen> {
  String? _field;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final profile = AppScope.read(context).profile;
    _field = profile.interestField;
    _selected = profile.chosenSubjects.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final fields = Ncap.subjects.keys.toList();

    final recommended = _field == null ? <String>[] : Ncap.subjects[_field]!;
    final rationale = _field == null ? null : subjectRationale[_field];

    // Which occupations the current selection actually keeps open.
    final opened = _field == null
        ? <String>[]
        : Ncap.careers
            .where((c) =>
                c.sector == _field &&
                c.requiredSubjects.every((r) => _satisfied(r)))
            .map((c) => c.title)
            .toList();

    return KhethaDetailPage(
      title: 'Subject Chooser',
      slivers: [
        SliverSection(children: [
          Text(
            'Pick the field you are interested in, then tick the subjects you are taking or plan to take.',
            style: KhethaText.secondary(p),
          ),
          const SizedBox(height: 18),

          Text('Field of interest', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          GlassSection(
            children: [
              for (final f in fields)
                GlassRow(
                  title: f,
                  subtitle: f == 'Skilled Trades & Artisanship'
                      ? 'Starts from Grade 9 · NSFAS-funded at TVET colleges'
                      : null,
                  trailing: _field == f
                      ? Icon(CupertinoIcons.checkmark_circle_fill,
                          color: p.accent, size: 22)
                      : Icon(CupertinoIcons.circle,
                          color: p.textTertiary, size: 22),
                  onTap: () => setState(() {
                    _field = f;
                    _selected = Ncap.subjects[f]!.toSet();
                  }),
                ),
            ],
          ),

          if (_field != null) ...[
            const SizedBox(height: 22),
            Text('Recommended subjects', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassSection(
              footer: rationale,
              children: [
                for (final sub in recommended)
                  GlassRow(
                    title: sub,
                    trailing: CupertinoSwitch(
                      value: _selected.contains(sub),
                      activeTrackColor: p.accent,
                      onChanged: (v) => setState(() {
                        v ? _selected.add(sub) : _selected.remove(sub);
                      }),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),
            GlassCard(
              tint: opened.isEmpty ? p.warm : p.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        opened.isEmpty
                            ? CupertinoIcons.lock_fill
                            : CupertinoIcons.lock_open_fill,
                        size: 17,
                        color: opened.isEmpty ? p.warm : p.accent,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          opened.isEmpty
                              ? 'This selection closes every career in the field'
                              : 'This selection keeps ${opened.length} career${opened.length == 1 ? "" : "s"} open',
                          style: KhethaText.headline(p),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  if (opened.isEmpty)
                    Text(
                      'None of the occupations in $_field accept this subject combination. Turn a required subject back on to see the difference.',
                      style: KhethaText.caption(p),
                    )
                  else
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final title in opened)
                          Chip(title, color: p.accent),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            KhethaButton(
              label: 'Save to my journey',
              icon: CupertinoIcons.checkmark_circle_fill,
              onTap: _selected.isEmpty
                  ? null
                  : () async {
                      await app.setSubjects(_field!, _selected.toList());
                      if (!context.mounted) return;
                      _showSaved(context);
                    },
            ),
            const SizedBox(height: 10),
            Text(
              app.consentStoreProfile
                  ? 'Saved to this phone only.'
                  : 'Saving is off. Turn on "Remember my progress" in Settings to keep this between sessions.',
              textAlign: TextAlign.center,
              style: KhethaText.caption(p).copyWith(color: p.textTertiary),
            ),
          ],
        ]),
      ],
    );
  }

  bool _satisfied(String requirement) {
    final alternatives =
        requirement.toLowerCase().split(' or ').map((s) => s.trim());
    for (final alt in alternatives) {
      for (final c in _selected) {
        final lc = c.toLowerCase();
        if (lc == alt) return true;
        if (lc.contains(alt) || alt.contains(lc)) {
          if (lc.contains('literacy') && alt == 'mathematics') continue;
          return true;
        }
      }
    }
    return false;
  }

  void _showSaved(BuildContext context) {
    final p = Palette.of(context);
    final matches = Ncap.careers
        .where((c) =>
            c.sector == _field &&
            c.requiredSubjects.every((r) => _satisfied(r)))
        .take(4)
        .toList();

    showKhethaSheet(
      context,
      title: 'Subjects saved',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your subject choices are now part of your journey. Every career match from here on is checked against them, and the app will tell you when a subject is standing in the way.',
            style: KhethaText.secondary(p),
          ),
          const SizedBox(height: 18),
          if (matches.isNotEmpty) ...[
            Text('Open to you right now',
                style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassSection(
              children: [
                for (final c in matches)
                  GlassRow(
                    icon: CupertinoIcons.briefcase_fill,
                    title: c.title,
                    subtitle: c.nqfLevel,
                    showChevron: true,
                    onTap: () {
                      closeSheet(context);
                      Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => CareerDetailScreen(careerId: c.id),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          KhethaButton(
            label: 'Done',
            onTap: () {
              // Close the confirmation sheet, then the tool behind it.
              closeSheet(context);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
