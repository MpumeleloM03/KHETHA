import 'package:flutter/cupertino.dart';

import '../data/ncap_repository.dart';
import '../data/seed_directory.dart';
import '../l10n/strings.dart';
import '../models/career_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import 'career_detail_screen.dart';
import 'root_tabs.dart';
import 'university_detail_screen.dart';

/// NCAP's three directories - Careers, What to Study, Where to Study - with
/// real search and filtering rather than a desktop table shrunk to fit.
/// Everything here is searched locally, so it works with no connection.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  int _tab = 0;
  String _query = '';
  String? _sectorFilter;
  String? _provinceFilter;
  bool _scarceOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final s = S.of(context);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(s.tabExplore),
            backgroundColor: AppScope.of(context).visualEffectsEnabled
                ? p.glassBar
                : p.surface.withValues(alpha: 0.98),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            transitionBetweenRoutes: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                children: [
                  CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: _placeholder(s),
                    onChanged: (v) => setState(() => _query = v),
                    backgroundColor: p.surface.withValues(alpha: 0.6),
                    style: KhethaText.body(p),
                    itemColor: p.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  CupertinoSlidingSegmentedControl<int>(
                    groupValue: _tab,
                    backgroundColor: p.separator,
                    thumbColor: p.surfaceRaised,
                    onValueChanged: (v) => setState(() {
                      _tab = v ?? 0;
                      // The field owns its own text, so clearing the query is not
                      // enough - the box would keep showing the old term.
                      _searchController.clear();
                      _query = '';
                      _sectorFilter = null;
                      _provinceFilter = null;
                      _scarceOnly = false;
                    }),
                    children: {
                      0: _seg(s.careers, p, _tab == 0),
                      1: _seg(s.whatToStudy, p, _tab == 1),
                      2: _seg(s.whereToStudy, p, _tab == 2),
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _filters(p)),
          ...switch (_tab) {
            0 => _careerSlivers(p),
            1 => _qualificationSlivers(p),
            _ => _providerSlivers(p),
          },
          const SliverToBoxAdapter(child: SizedBox(height: tabBarInset)),
        ],
      ),
    );
  }

  Widget _seg(String label, Palette p, bool active) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? p.textPrimary : p.textSecondary,
          ),
        ),
      );

  String _placeholder(S s) => switch (_tab) {
        0 => 'Search careers, sectors or OFO codes',
        1 => 'Search qualifications or SAQA IDs',
        _ => 'Search institutions or towns',
      };

  // ---- Filter row ---------------------------------------------------------
  Widget _filters(Palette p) {
    final chips = <Widget>[];

    if (_tab == 0 || _tab == 1) {
      chips.add(_FilterChip(
        label: _sectorFilter ?? 'All fields',
        active: _sectorFilter != null,
        onTap: () => _pickSector(),
      ));
    }
    if (_tab == 0) {
      chips.add(_FilterChip(
        label: 'High demand only',
        active: _scarceOnly,
        onTap: () => setState(() => _scarceOnly = !_scarceOnly),
      ));
    }
    if (_tab == 2) {
      chips.add(_FilterChip(
        label: _provinceFilter ?? 'All provinces',
        active: _provinceFilter != null,
        onTap: () => _pickProvince(),
      ));
      chips.add(_FilterChip(
        label: _sectorFilter ?? 'All fields',
        active: _sectorFilter != null,
        onTap: () => _pickSector(),
      ));
    }

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final c in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  void _pickSector() {
    final sectors = Ncap.subjects.keys.toList();
    showKhethaSheet(
      context,
      title: 'Filter by field',
      child: GlassSection(
        children: [
          GlassRow(
            title: 'All fields',
            trailing: _sectorFilter == null
                ? const Icon(CupertinoIcons.checkmark, size: 18)
                : null,
            onTap: () {
              setState(() => _sectorFilter = null);
              closeSheet(context);
            },
          ),
          for (final sec in sectors)
            GlassRow(
              title: sec,
              trailing: _sectorFilter == sec
                  ? const Icon(CupertinoIcons.checkmark, size: 18)
                  : null,
              onTap: () {
                setState(() => _sectorFilter = sec);
                closeSheet(context);
              },
            ),
        ],
      ),
    );
  }

  void _pickProvince() {
    showKhethaSheet(
      context,
      title: 'Filter by province',
      child: GlassSection(
        children: [
          GlassRow(
            title: 'All provinces',
            trailing: _provinceFilter == null
                ? const Icon(CupertinoIcons.checkmark, size: 18)
                : null,
            onTap: () {
              setState(() => _provinceFilter = null);
              closeSheet(context);
            },
          ),
          for (final prov in provinces)
            GlassRow(
              title: prov,
              trailing: _provinceFilter == prov
                  ? const Icon(CupertinoIcons.checkmark, size: 18)
                  : null,
              onTap: () {
                setState(() => _provinceFilter = prov);
                closeSheet(context);
              },
            ),
        ],
      ),
    );
  }

  // ---- Careers -------------------------------------------------------------
  List<Widget> _careerSlivers(Palette p) {
    final q = _query.toLowerCase();
    final list = Ncap.careers.where((c) {
      if (_scarceOnly && !c.scarceSkill) return false;
      if (_sectorFilter != null && c.sector != _sectorFilter) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.sector.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.ofoCode.contains(q);
    }).toList();

    if (list.isEmpty) return [_empty(p, 'No careers match that search.')];

    return [
      _countHeader(p, '${list.length} occupations'),
      SliverSection(children: [
        for (final c in list) ...[
          GlassCard(
            padding: const EdgeInsets.all(15),
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => CareerDetailScreen(careerId: c.id),
              ),
            ),
            semanticLabel: '${c.title}, ${c.sector}, ${c.nqfLevel}',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: KhethaText.headline(p)),
                      const SizedBox(height: 4),
                      Text(
                        c.description,
                        style: KhethaText.caption(p),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(c.sector, color: p.textSecondary),
                          Chip(c.nqfLevel, color: p.textSecondary),
                          if (c.scarceSkill)
                            Chip('High demand',
                                color: p.warm,
                                icon: CupertinoIcons.flame_fill),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(CupertinoIcons.chevron_right,
                    size: 15, color: p.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ]),
    ];
  }

  // ---- Qualifications -------------------------------------------------------
  List<Widget> _qualificationSlivers(Palette p) {
    final q = _query.toLowerCase();
    final list = Ncap.qualifications.where((x) {
      if (_sectorFilter != null && x.field != _sectorFilter) return false;
      if (q.isEmpty) return true;
      return x.title.toLowerCase().contains(q) ||
          x.field.toLowerCase().contains(q) ||
          x.saqaId.contains(q) ||
          x.providerType.toLowerCase().contains(q);
    }).toList();

    if (list.isEmpty) {
      return [_empty(p, 'No qualifications match that search.')];
    }

    return [
      _countHeader(p, '${list.length} qualifications'),
      SliverSection(children: [
        for (final x in list) ...[
          GlassCard(
            padding: const EdgeInsets.all(15),
            onTap: () => _showQualification(x, p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(x.title, style: KhethaText.headline(p)),
                const SizedBox(height: 4),
                Text(x.providerType, style: KhethaText.caption(p)),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(x.nqfLevel, color: p.accent),
                    Chip(x.duration, color: p.textSecondary),
                    Chip('SAQA ${x.saqaId}', color: p.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ]),
    ];
  }

  void _showQualification(Qualification x, Palette p) {
    final leadsTo = x.leadsToCareerIds
        .map(Ncap.careerById)
        .whereType<Career>()
        .toList();

    showKhethaSheet(
      context,
      title: x.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(x.nqfLevel, color: p.accent),
              Chip(x.duration, color: p.textSecondary),
              Chip('SAQA ${x.saqaId}', color: p.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Text('Minimum requirements', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 6),
          Text(x.minimumRequirements, style: KhethaText.body(p)),
          const SizedBox(height: 16),
          Text('Offered by', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 6),
          Text(x.providerType, style: KhethaText.body(p)),
          if (leadsTo.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Leads to', style: KhethaText.sectionLabel(p)),
            const SizedBox(height: 8),
            GlassSection(
              children: [
                for (final c in leadsTo)
                  GlassRow(
                    icon: CupertinoIcons.briefcase_fill,
                    title: c.title,
                    subtitle: c.sector,
                    showChevron: true,
                    onTap: () {
                      closeSheet(context);
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => CareerDetailScreen(careerId: c.id),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---- Providers -------------------------------------------------------------
  List<Widget> _providerSlivers(Palette p) {
    final q = _query.toLowerCase();
    final all = Ncap.providers.where((x) {
      if (_provinceFilter != null && x.province != _provinceFilter) return false;
      if (_sectorFilter != null && !x.offeredFields.contains(_sectorFilter)) {
        return false;
      }
      if (q.isEmpty) return true;
      return x.name.toLowerCase().contains(q) ||
          x.town.toLowerCase().contains(q) ||
          x.province.toLowerCase().contains(q) ||
          x.type.toLowerCase().contains(q) ||
          (x.abbreviation?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (all.isEmpty) {
      return [_empty(p, 'No institutions match that search.')];
    }

    final universities = all.where((x) => x.type.contains('University')).toList();
    final tvetColleges = all.where((x) => x.type == 'TVET College').toList();

    return [
      _countHeader(p, '${all.length} institutions'),
      if (universities.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text('Universities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ProviderRow(provider: universities[index], p: p),
            childCount: universities.length,
          ),
        ),
      ],
      if (tvetColleges.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text('TVET Colleges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ProviderRow(provider: tvetColleges[index], p: p),
            childCount: tvetColleges.length,
          ),
        ),
      ],
    ];
  }

  // ---- Shared -----------------------------------------------------------------
  Widget _countHeader(Palette p, String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
          child: Row(
            children: [
              Expanded(
                  child: Text(text, style: KhethaText.sectionLabel(p))),
              Icon(CupertinoIcons.wifi_slash, size: 12, color: p.textTertiary),
              const SizedBox(width: 5),
              Text('Offline', style: KhethaText.caption(p).copyWith(fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _empty(Palette p, String message) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            children: [
              Icon(CupertinoIcons.search, size: 34, color: p.textTertiary),
              const SizedBox(height: 14),
              Text(message,
                  textAlign: TextAlign.center,
                  style: KhethaText.secondary(p)),
              const SizedBox(height: 8),
              Text('Try a shorter search, or clear the filters.',
                  textAlign: TextAlign.center,
                  style: KhethaText.caption(p)),
            ],
          ),
        ),
      );
}

class _ProviderRow extends StatelessWidget {
  final LearningProvider provider;
  final Palette p;
  const _ProviderRow({required this.provider, required this.p});

  @override
  Widget build(BuildContext context) {
    final brandColor = brandColorFor(provider);
    final abbr = provider.abbreviation ?? provider.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => UniversityDetailScreen(providerId: provider.id)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: p.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.separator, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: provider.logoUrl != null ? CupertinoColors.white : brandColor,
                  shape: BoxShape.circle,
                  border: provider.logoUrl != null ? Border.all(color: p.separator, width: 0.5) : null,
                ),
                child: provider.logoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          provider.logoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(abbr, style: TextStyle(color: brandColor, fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          abbr,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: KhethaText.headline(p), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(provider.province, style: KhethaText.caption(p)),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? p.onAccent : p.textSecondary,
                ),
              ),
              const SizedBox(width: 5),
              Icon(CupertinoIcons.chevron_down,
                  size: 11, color: active ? p.onAccent : p.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
