import 'package:flutter/cupertino.dart';

import '../../state/app_state.dart';
import '../../theme/glass.dart';
import '../../theme/palette.dart';

class DiscoverPathScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const DiscoverPathScreen({super.key, required this.onComplete});

  @override
  State<DiscoverPathScreen> createState() => _DiscoverPathScreenState();
}

class _DiscoverPathScreenState extends State<DiscoverPathScreen> {
  int _step = 0;

  String? _favouriteSubjectType;
  final Set<String> _careerGoals = {};

  static final _subjectTypes = [
    ('STEM', CupertinoIcons.bolt_fill, 'Science, Technology, Engineering, Maths'),
    ('Creative Arts', CupertinoIcons.paintbrush_fill, 'Design, Music, Drama, Visual Arts'),
    ('Humanities', CupertinoIcons.book_fill, 'Languages, History, Social Sciences'),
    ('Commerce', CupertinoIcons.chart_bar_fill, 'Business, Accounting, Economics'),
  ];

  static final _goals = [
    ('Tech', CupertinoIcons.desktopcomputer, 'Work in technology or engineering'),
    ('Leadership', CupertinoIcons.person_3_fill, 'Lead teams or organisations'),
    ('Research', CupertinoIcons.eyeglasses, 'Discover and innovate'),
    ('Healthcare', CupertinoIcons.heart_fill, 'Help people heal and stay healthy'),
    ('Creative', CupertinoIcons.paintbrush, 'Create, design, perform'),
    ('Service', CupertinoIcons.hand_raised_fill, 'Teach, counsel, uplift communities'),
  ];

  bool get _canProceed {
    if (_step == 0) return _favouriteSubjectType != null;
    return _careerGoals.isNotEmpty;
  }

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      final app = AppScope.read(context);
      app.setOnboardingPreferences(
        favouriteSubjectType: _favouriteSubjectType!,
        careerGoals: _careerGoals.toList(),
      );
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.accentMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(CupertinoIcons.compass_fill,
                    size: 22, color: p.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Discover Your Path',
                    style: KhethaText.largeTitle(p)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Interests and Passions',
            style: KhethaText.secondary(p).copyWith(fontSize: 15),
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _step == 0
                ? _SubjectTypeStep(
                    key: const ValueKey(0),
                    selected: _favouriteSubjectType,
                    onSelect: (v) =>
                        setState(() => _favouriteSubjectType = v),
                  )
                : _GoalsStep(
                    key: const ValueKey(1),
                    selected: _careerGoals,
                    onToggle: (v) => setState(() {
                      if (_careerGoals.contains(v)) {
                        _careerGoals.remove(v);
                      } else {
                        _careerGoals.add(v);
                      }
                    }),
                  ),
          ),
          const SizedBox(height: 24),
          KhethaButton(
            label: _step == 0 ? 'Next' : 'Continue',
            onTap: _canProceed ? _next : null,
          ),
          if (_step == 1) ...[
            const SizedBox(height: 10),
            KhethaButton(
              label: 'Back',
              secondary: true,
              onTap: () => setState(() => _step = 0),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectTypeStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _SubjectTypeStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is your favourite type of subject?',
            style: KhethaText.headline(p)),
        const SizedBox(height: 14),
        for (final (name, icon, desc)
            in _DiscoverPathScreenState._subjectTypes) ...[
          _OptionTile(
            label: name,
            subtitle: desc,
            icon: icon,
            selected: selected == name,
            onTap: () => onSelect(name),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GoalsStep extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _GoalsStep({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are your career goals?', style: KhethaText.headline(p)),
        const SizedBox(height: 4),
        Text('Select all that apply',
            style: KhethaText.caption(p)),
        const SizedBox(height: 14),
        for (final (name, icon, desc) in _DiscoverPathScreenState._goals) ...[
          _OptionTile(
            label: name,
            subtitle: desc,
            icon: icon,
            selected: selected.contains(name),
            onTap: () => onToggle(name),
            checkbox: true,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool checkbox;

  const _OptionTile({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.checkbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? p.accentMuted : p.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? p.accent : p.separator,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? (checkbox
                      ? CupertinoIcons.checkmark_square_fill
                      : CupertinoIcons.checkmark_circle_fill)
                  : (checkbox
                      ? CupertinoIcons.square
                      : CupertinoIcons.circle),
              size: 22,
              color: selected ? p.accent : p.textTertiary,
            ),
            const SizedBox(width: 14),
            Icon(icon, size: 20, color: selected ? p.accent : p.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: KhethaText.headline(p).copyWith(
                        color: selected ? p.accent : p.textPrimary,
                      )),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: KhethaText.caption(p).copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
