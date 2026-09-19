import 'package:flutter/cupertino.dart';

import '../data/ncap_repository.dart';
import '../models/career_models.dart';
import '../theme/palette.dart';
import 'root_tabs.dart';

const _brandColors = <String, Color>{
  'UCT': Color(0xFF003B5C),
  'CPUT': Color(0xFF00205B),
  'UKZN': Color(0xFF8B0000),
  'DUT': Color(0xFF006633),
  'UP': Color(0xFF8B2332),
  'Wits': Color(0xFF003B5C),
  'TUT': Color(0xFF005B2F),
  'UJ': Color(0xFFFF6600),
  'UFH': Color(0xFF003366),
  'WSU': Color(0xFF006B3F),
  'NMU': Color(0xFF003366),
  'UFS': Color(0xFFCC0000),
  'Univen': Color(0xFF006600),
  'UL': Color(0xFF003399),
  'UMP': Color(0xFF1B4332),
  'NWU': Color(0xFF461D7C),
  'SPU': Color(0xFF8B0000),
  'SU': Color(0xFF8B0000),
  'RU': Color(0xFF660099),
};

Color brandColorFor(LearningProvider provider) {
  if (provider.abbreviation != null && _brandColors.containsKey(provider.abbreviation)) {
    return _brandColors[provider.abbreviation]!;
  }
  final hash = provider.id.hashCode;
  final hue = (hash % 360).abs().toDouble();
  return HSLColor.fromAHSL(1, hue, 0.5, 0.35).toColor();
}

class UniversityDetailScreen extends StatefulWidget {
  final String providerId;
  const UniversityDetailScreen({super.key, required this.providerId});

  @override
  State<UniversityDetailScreen> createState() => _UniversityDetailScreenState();
}

class _UniversityDetailScreenState extends State<UniversityDetailScreen> {
  int _tab = 0;
  String _courseQuery = '';

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final provider = Ncap.providers.firstWhere((x) => x.id == widget.providerId);
    final brandColor = brandColorFor(provider);
    final qualifications = Ncap.qualifications.where((q) {
      if (q.offeredBy.isNotEmpty && !q.offeredBy.contains(provider.id)) return false;
      return provider.offeredFields.contains(q.field);
    }).toList();

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(p, provider, brandColor)),
          SliverToBoxAdapter(child: _buildTabBar(p)),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          ...switch (_tab) {
            0 => _overviewSlivers(p, provider),
            1 => _coursesSlivers(p, provider, qualifications),
            2 => _requirementsSlivers(p, qualifications),
            _ => _contactSlivers(p, provider),
          },
          const SliverToBoxAdapter(child: SizedBox(height: tabBarInset)),
        ],
      ),
    );
  }

  Widget _buildHeader(Palette p, LearningProvider provider, Color brandColor) {
    final abbr = provider.abbreviation ?? provider.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [brandColor, brandColor.withValues(alpha: 0.7)],
            ),
          ),
          child: provider.heroImageUrl != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      provider.heroImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [brandColor.withValues(alpha: 0.5), brandColor.withValues(alpha: 0.85)],
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Icon(CupertinoIcons.back, color: CupertinoColors.white, size: 28),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(CupertinoIcons.back, color: CupertinoColors.white, size: 28),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: -30,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0x33000000), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Center(
              child: provider.logoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        provider.logoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _AbbrCircle(abbr: abbr, color: brandColor),
                      ),
                    )
                  : _AbbrCircle(abbr: abbr, color: brandColor),
            ),
          ),
        ),
        Positioned(
          left: 100,
          right: 16,
          bottom: -50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary, letterSpacing: -0.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(CupertinoIcons.location_solid, size: 13, color: p.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${provider.town}, ${provider.province}',
                      style: TextStyle(fontSize: 13, color: p.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 240),
      ],
    );
  }

  Widget _buildTabBar(Palette p) {
    final tabs = ['Overview', 'Courses', 'Requirements', 'Contact'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: p.separator,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _tab == i ? p.surfaceRaised : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _tab == i ? FontWeight.w600 : FontWeight.w500,
                        color: _tab == i ? p.textPrimary : p.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _overviewSlivers(Palette p, LearningProvider provider) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
              if (provider.description != null) ...[
                const SizedBox(height: 10),
                Text(provider.description!, style: TextStyle(fontSize: 15, height: 1.5, color: p.textSecondary)),
              ],
              const SizedBox(height: 20),
              _InfoRow(label: 'Type', value: provider.type, p: p),
              _InfoRow(label: 'Total Students', value: provider.totalStudents != null ? '${_formatNumber(provider.totalStudents!)}+' : 'N/A', p: p),
              _InfoRow(label: 'Website', value: provider.website, p: p, isLink: true),
              _InfoRow(label: 'NSFAS', value: provider.nsfasAccredited ? 'Accredited' : 'Not accredited', p: p),
              const SizedBox(height: 24),
              Text('Fields of Study', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final field in provider.offeredFields)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Palette.govGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Palette.govGreen.withValues(alpha: 0.15)),
                      ),
                      child: Text(field, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.brand)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _coursesSlivers(Palette p, LearningProvider provider, List<Qualification> qualifications) {
    final q = _courseQuery.toLowerCase();
    final filtered = q.isEmpty ? qualifications : qualifications.where((x) {
      return x.title.toLowerCase().contains(q) || x.field.toLowerCase().contains(q);
    }).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available NQF Qualifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
              const SizedBox(height: 12),
              CupertinoSearchTextField(
                placeholder: 'Filter courses...',
                onChanged: (v) => setState(() => _courseQuery = v),
                backgroundColor: p.cardSurface,
                style: KhethaText.body(p),
                itemColor: p.textTertiary,
              ),
              const SizedBox(height: 6),
              Text('${filtered.length} qualifications', style: KhethaText.caption(p)),
            ],
          ),
        ),
      ),
      if (filtered.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text('No qualifications found.', style: KhethaText.secondary(p))),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final qual = filtered[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.separator, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(qual.title, style: KhethaText.headline(p)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniChip(qual.nqfLevel, color: p.accent),
                          _MiniChip(qual.duration, color: p.textSecondary),
                          _MiniChip(qual.field, color: p.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: filtered.length,
          ),
        ),
    ];
  }

  List<Widget> _requirementsSlivers(Palette p, List<Qualification> qualifications) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.separator, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReqRow(icon: CupertinoIcons.doc_text, label: 'National Senior Certificate (NSC)', p: p),
                    const SizedBox(height: 12),
                    _ReqRow(icon: CupertinoIcons.checkmark_circle, label: 'Bachelor\'s pass for degree programmes', p: p),
                    const SizedBox(height: 12),
                    _ReqRow(icon: CupertinoIcons.number, label: 'Minimum APS as per programme', p: p),
                    const SizedBox(height: 12),
                    _ReqRow(icon: CupertinoIcons.book, label: 'Subject-specific requirements vary', p: p),
                  ],
                ),
              ),
              if (qualifications.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Programme-Specific Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(height: 12),
                for (final q in qualifications.take(10)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.separator, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.title, style: KhethaText.headline(p)),
                        const SizedBox(height: 6),
                        Text('${q.passRequired.label} | APS: ${q.apsRequired > 0 ? q.apsRequired.toString() : 'N/A'}',
                            style: KhethaText.caption(p)),
                        const SizedBox(height: 4),
                        Text(q.minimumRequirements, style: KhethaText.body(p).copyWith(fontSize: 13, color: p.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _contactSlivers(Palette p, LearningProvider provider) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
              const SizedBox(height: 16),
              if (provider.phone != null)
                _ContactTile(icon: CupertinoIcons.phone_fill, label: 'Phone', value: provider.phone!, p: p),
              if (provider.email != null)
                _ContactTile(icon: CupertinoIcons.mail_solid, label: 'Email', value: provider.email!, p: p),
              _ContactTile(icon: CupertinoIcons.globe, label: 'Website', value: provider.website, p: p),
              _ContactTile(icon: CupertinoIcons.location_solid, label: 'Location', value: '${provider.town}, ${provider.province}', p: p),
            ],
          ),
        ),
      ),
    ];
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return n.toString();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Palette p;
  final bool isLink;
  const _InfoRow({required this.label, required this.value, required this.p, this.isLink = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLink ? p.accent : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ReqRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Palette p;
  const _ReqRow({required this.icon, required this.label, required this.p});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: p.brand),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: p.textPrimary))),
      ],
    );
  }
}

class _AbbrCircle extends StatelessWidget {
  final String abbr;
  final Color color;
  const _AbbrCircle({required this.abbr, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          abbr,
          style: const TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Palette p;
  const _ContactTile({required this.icon, required this.label, required this.value, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.separator, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Palette.govGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: p.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
