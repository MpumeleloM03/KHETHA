import 'package:flutter/cupertino.dart';

import '../data/admissions.dart';
import '../data/ncap_repository.dart';
import '../models/application_models.dart';
import '../models/career_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';

/// Choose where to apply for one qualification.
///
/// Every institution that offers the field is listed, with the learner's own
/// province first, and all of them can be selected at once. Applying to one
/// place instead of six is usually about the effort rather than the preference,
/// so the effort is what this screen removes.
class ApplyScreen extends StatefulWidget {
  final String qualificationId;
  const ApplyScreen({super.key, required this.qualificationId});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final q = Ncap.qualificationById(widget.qualificationId);
    if (q == null) {
      return const KhethaDetailPage(title: 'Not found', slivers: []);
    }

    final p = Palette.of(context);
    final app = AppScope.of(context);
    final province = app.profile.province;
    final eligibility = AdmissionsEngine.assess(q, app.results);

    final providers = Ncap.providers
        .where((prov) => prov.offeredFields.contains(q.field))
        .toList()
      ..sort((a, b) {
        if (province != null) {
          final aLocal = a.province == province;
          final bLocal = b.province == province;
          if (aLocal != bLocal) return aLocal ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

    final already = app.applications.map((a) => a.key).toSet();
    final addable = providers
        .where((prov) => !already.contains('${prov.id}::${q.id}'))
        .toList();

    return KhethaDetailPage(
      title: 'Where to apply',
      slivers: [
        SliverSection(children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.title, style: KhethaText.headline(p)),
                const SizedBox(height: 4),
                Text('${q.nqfLevel} · ${q.duration}',
                    style: KhethaText.caption(p)),
                const SizedBox(height: 10),
                Chip(eligibility.status.label,
                    color: switch (eligibility.status) {
                      EligibilityStatus.qualifies => p.accent,
                      EligibilityStatus.nearMiss => p.warm,
                      _ => p.textSecondary,
                    }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (eligibility.status == EligibilityStatus.notYet)
            GlassCard(
              tint: p.warm,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle_fill,
                      size: 18, color: p.warm),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'You do not meet the published requirements for this one. You can still apply - institutions sometimes admit below their minimum - but keep an application open somewhere you do qualify.',
                      style: KhethaText.caption(p),
                    ),
                  ),
                ],
              ),
            ),
          if (eligibility.status == EligibilityStatus.notYet)
            const SizedBox(height: 14),

          if (addable.isEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Already added everywhere',
                      style: KhethaText.headline(p)),
                  const SizedBox(height: 5),
                  Text(
                    'You have an application for this programme at every institution in the dataset that offers it.',
                    style: KhethaText.caption(p),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text('${addable.length} institutions offer this',
                      style: KhethaText.sectionLabel(p)),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 30),
                  onPressed: () => setState(() {
                    if (_selected.length == addable.length) {
                      _selected.clear();
                    } else {
                      _selected
                        ..clear()
                        ..addAll(addable.map((prov) => prov.id));
                    }
                  }),
                  child: Text(
                    _selected.length == addable.length
                        ? 'Clear all'
                        : 'Select all',
                    style: KhethaText.caption(p).copyWith(
                        color: p.accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GlassSection(
              children: [
                for (final prov in addable)
                  GlassRow(
                    icon: CupertinoIcons.building_2_fill,
                    iconColor: prov.province == province ? p.accent : p.textSecondary,
                    title: prov.name,
                    subtitle: prov.province == province
                        ? '${prov.town} · in your province'
                        : '${prov.town} · ${prov.province}',
                    trailing: Icon(
                      _selected.contains(prov.id)
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color: _selected.contains(prov.id) ? p.accent : p.textTertiary,
                    ),
                    onTap: () => setState(() {
                      if (!_selected.remove(prov.id)) _selected.add(prov.id);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            KhethaButton(
              label: _selected.isEmpty
                  ? 'Choose at least one'
                  : 'Add ${_selected.length} ${_selected.length == 1 ? "application" : "applications"}',
              icon: CupertinoIcons.add_circled_solid,
              onTap: _selected.isEmpty
                  ? null
                  : () async {
                      for (final providerId in _selected) {
                        await app.addApplication(InstitutionApplication(
                          providerId: providerId,
                          qualificationId: q.id,
                          state: ApplicationState.draft,
                          updatedAt: DateTime.now(),
                        ));
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
            ),
            const SizedBox(height: 10),
            Text(
              'Nothing is sent yet. Applications are added as drafts, and you send them together once your documents are ready.',
              textAlign: TextAlign.center,
              style: KhethaText.caption(p).copyWith(color: p.textTertiary),
            ),
          ],
        ]),
      ],
    );
  }
}

/// Convenience lookup used by the applications list.
LearningProvider? providerById(String id) {
  for (final p in Ncap.providers) {
    if (p.id == id) return p;
  }
  return null;
}
