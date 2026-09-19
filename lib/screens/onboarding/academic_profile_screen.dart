import 'package:flutter/cupertino.dart';

import '../../state/app_state.dart';
import '../../theme/glass.dart';
import '../../theme/palette.dart';

class AcademicProfileScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const AcademicProfileScreen({super.key, required this.onComplete});

  @override
  State<AcademicProfileScreen> createState() => _AcademicProfileScreenState();
}

class _AcademicProfileScreenState extends State<AcademicProfileScreen> {
  String _gradeLevel = 'Grade 12';
  final Map<String, int?> _marks = {};
  bool _showMore = false;

  static const _coreSubjects = [
    'Mathematics',
    'English',
    'Physical Sciences',
    'Life Sciences',
  ];

  static const _additionalSubjects = [
    'Accounting',
    'Business Studies',
    'Economics',
    'Geography',
    'History',
    'Information Technology',
    'Visual Arts',
    'Agricultural Sciences',
    'Engineering Graphics & Design',
    'Consumer Studies',
    'Tourism',
    'Dramatic Arts',
  ];

  static const _gradeLevels = [
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  int get _aps {
    var total = 0;
    for (final entry in _marks.entries) {
      final mark = entry.value;
      if (mark == null) continue;
      total += _markToApsPoint(mark);
    }
    return total;
  }

  int _markToApsPoint(int mark) {
    if (mark >= 80) return 7;
    if (mark >= 70) return 6;
    if (mark >= 60) return 5;
    if (mark >= 50) return 4;
    if (mark >= 40) return 3;
    if (mark >= 30) return 2;
    return 1;
  }

  bool get _hasAnyMarks => _marks.values.any((v) => v != null);

  void _save() {
    final app = AppScope.read(context);
    app.setOnboardingAcademicProfile(
      gradeLevel: _gradeLevel,
      subjectMarks: Map.fromEntries(
        _marks.entries.where((e) => e.value != null).map(
              (e) => MapEntry(e.key, e.value!),
            ),
      ),
      aps: _aps,
    );
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Academic Profile', style: KhethaText.largeTitle(p)),
          const SizedBox(height: 6),
          Text('Enter grades', style: KhethaText.secondary(p)),
          const SizedBox(height: 20),

          // Grade level selector
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current grade level', style: KhethaText.headline(p)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final level in _gradeLevels) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gradeLevel = level),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _gradeLevel == level
                                  ? p.accentMuted
                                  : p.cardSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _gradeLevel == level
                                    ? p.accent
                                    : p.separator,
                                width: _gradeLevel == level ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              level.replaceFirst('Grade ', 'Gr '),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _gradeLevel == level
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _gradeLevel == level
                                    ? p.accent
                                    : p.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (level != _gradeLevels.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Core subjects
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Core Subjects',
                          style: KhethaText.headline(p)),
                    ),
                    if (_hasAnyMarks)
                      _ApsChip(aps: _aps, palette: p),
                  ],
                ),
                const SizedBox(height: 14),
                for (final subject in _coreSubjects)
                  _SubjectMarkRow(
                    subject: subject,
                    mark: _marks[subject],
                    onChanged: (v) =>
                        setState(() => _marks[subject] = v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // High school / additional subjects
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showMore = !_showMore),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Additional Subjects',
                            style: KhethaText.headline(p)),
                      ),
                      Icon(
                        _showMore
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 18,
                        color: p.textTertiary,
                      ),
                    ],
                  ),
                ),
                if (_showMore) ...[
                  const SizedBox(height: 14),
                  for (final subject in _additionalSubjects)
                    _SubjectMarkRow(
                      subject: subject,
                      mark: _marks[subject],
                      onChanged: (v) =>
                          setState(() => _marks[subject] = v),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scan option
          GlassCard(
            child: Row(
              children: [
                Icon(CupertinoIcons.camera_fill,
                    size: 20, color: p.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Have a report card?',
                          style: KhethaText.headline(p)),
                      const SizedBox(height: 2),
                      Text(
                        'You can scan it later from the Journey tab using your camera, photo library, or a PDF.',
                        style: KhethaText.caption(p),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          KhethaButton(
            label: 'Save and Continue',
            icon: CupertinoIcons.arrow_right_circle_fill,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

class _SubjectMarkRow extends StatelessWidget {
  final String subject;
  final int? mark;
  final ValueChanged<int?> onChanged;

  const _SubjectMarkRow({
    required this.subject,
    required this.mark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(subject, style: KhethaText.body(p)),
          ),
          SizedBox(
            width: 70,
            height: 38,
            child: CupertinoTextField(
              placeholder: '%',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
              placeholderStyle: TextStyle(
                fontSize: 14,
                color: p.textTertiary,
              ),
              decoration: BoxDecoration(
                color: p.cardSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.separator),
              ),
              onChanged: (text) {
                final val = int.tryParse(text);
                if (val != null && val >= 0 && val <= 100) {
                  onChanged(val);
                } else if (text.isEmpty) {
                  onChanged(null);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApsChip extends StatelessWidget {
  final int aps;
  final Palette palette;
  const _ApsChip({required this.aps, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.accentMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('APS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: palette.textTertiary,
                letterSpacing: 0.5,
              )),
          Text('$aps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              )),
        ],
      ),
    );
  }
}
