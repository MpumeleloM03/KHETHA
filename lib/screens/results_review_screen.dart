import 'package:flutter/cupertino.dart';

import '../data/results_parser.dart';
import '../models/results_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/listen_button.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';

/// Check and correct what was scanned, before anything is relied on.
///
/// This screen exists because OCR is never perfect and the stakes here are a
/// learner's university application. Rows the recogniser was unsure about are
/// flagged, every mark is editable, and the APS updates as you correct it so
/// the consequence of a wrong digit is visible immediately.
class ResultsReviewScreen extends StatefulWidget {
  final ScanOutcome outcome;
  final String source;

  const ResultsReviewScreen({
    super.key,
    required this.outcome,
    required this.source,
  });

  @override
  State<ResultsReviewScreen> createState() => _ResultsReviewScreenState();
}

class _ResultsReviewScreenState extends State<ResultsReviewScreen> {
  late List<SubjectResult> _subjects;
  ResultsKind _kind = ResultsKind.nscFinal;

  @override
  void initState() {
    super.initState();
    _subjects = [...widget.outcome.subjects];
  }

  MatricResults get _results => MatricResults(
        kind: _kind,
        subjects: _subjects,
        capturedAt: DateTime.now(),
        source: widget.source,
      );

  bool get _isComplete => _subjects.length >= 6;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final unsure = _subjects.where((s) => s.needsChecking).length;

    return KhethaDetailPage(
      title: 'Check your results',
      slivers: [
        SliverSection(children: [
          if (widget.outcome.subjects.isNotEmpty) ...[
            GlassCard(
              tint: unsure > 0 ? p.warm : p.accent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    unsure > 0
                        ? CupertinoIcons.exclamationmark_circle_fill
                        : CupertinoIcons.checkmark_seal_fill,
                    size: 19,
                    color: unsure > 0 ? p.warm : p.accent,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unsure > 0
                              ? '$unsure ${unsure == 1 ? "row needs" : "rows need"} checking'
                              : 'Read ${_subjects.length} subjects',
                          style: KhethaText.headline(p),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compare every mark against your statement before you save. Tap a mark to change it.',
                          style: KhethaText.caption(p),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _ApsCard(results: _results, complete: _isComplete),
          const SizedBox(height: 16),

          Text('Which results are these?', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          GlassSection(
            footer: _kind.isProvisional
                ? 'Only your final NSC results decide admission. Everything the app shows from a term or Grade 11 report is an estimate to plan with.'
                : null,
            children: [
              for (final kind in ResultsKind.values)
                GlassRow(
                  title: kind.label,
                  trailing: _kind == kind
                      ? Icon(CupertinoIcons.checkmark_circle_fill,
                          color: p.accent, size: 21)
                      : null,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: Text('Subjects and marks',
                    style: KhethaText.sectionLabel(p)),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 30),
                onPressed: _addSubject,
                child: Text('Add',
                    style: KhethaText.caption(p).copyWith(
                        color: p.accent, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_subjects.isEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No subjects yet', style: KhethaText.headline(p)),
                  const SizedBox(height: 5),
                  Text(
                    'Add each subject and the percentage you got. Six subjects plus Life Orientation is the usual matric load.',
                    style: KhethaText.caption(p),
                  ),
                  const SizedBox(height: 14),
                  KhethaButton(
                    label: 'Add your first subject',
                    icon: CupertinoIcons.add_circled_solid,
                    onTap: _addSubject,
                  ),
                ],
              ),
            )
          else
            GlassSection(
              children: [
                for (var i = 0; i < _subjects.length; i++)
                  _SubjectRow(
                    result: _subjects[i],
                    onEdit: () => _editMark(i),
                    onRemove: () => setState(() => _subjects.removeAt(i)),
                  ),
              ],
            ),

          if (widget.outcome.unparsedLines.isNotEmpty) ...[
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lines the app could not read',
                      style: KhethaText.headline(p)),
                  const SizedBox(height: 5),
                  Text(
                    'These came off the page but did not match a subject. If one of them is a subject you took, add it above.',
                    style: KhethaText.caption(p),
                  ),
                  const SizedBox(height: 10),
                  for (final line in widget.outcome.unparsedLines.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'Menlo',
                          fontSize: 12,
                          color: p.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          KhethaButton(
            label: 'Save my results',
            icon: CupertinoIcons.checkmark_circle_fill,
            onTap: _subjects.length < 4
                ? null
                : () async {
                    await app.setResults(_results);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
          ),
          const SizedBox(height: 10),
          Text(
            _subjects.length < 4
                ? 'Add at least four subjects before saving.'
                : app.consentStoreProfile
                    ? 'Saved to this phone only.'
                    : 'Saving is off - turn on "Remember my progress" in Settings to keep this between sessions.',
            textAlign: TextAlign.center,
            style: KhethaText.caption(p).copyWith(color: p.textTertiary),
          ),
        ]),
      ],
    );
  }

  Future<void> _editMark(int index) async {
    final result = _subjects[index];
    final controller =
        TextEditingController(text: result.percentage.toString());

    final saved = await showKhethaSheet<bool>(
      context,
      title: result.subject,
      child: _MarkEditor(controller: controller),
    );

    if (saved != true) return;
    final value = int.tryParse(controller.text);
    if (value == null) return;

    setState(() {
      _subjects[index] = result.copyWith(percentage: value.clamp(0, 100));
    });
  }

  Future<void> _addSubject() async {
    final taken = _subjects.map((s) => s.subject).toSet();
    final available = ResultsParser.canonicalSubjects
        .where((s) => !taken.contains(s))
        .toList();

    final chosen = await showKhethaSheet<String>(
      context,
      title: 'Add a subject',
      child: GlassSection(
        children: [
          for (final subject in available)
            GlassRow(
              title: subject,
              showChevron: true,
              onTap: () => closeSheet(context, subject),
            ),
        ],
      ),
    );

    if (chosen == null || !mounted) return;

    final controller = TextEditingController();
    final saved = await showKhethaSheet<bool>(
      context,
      title: chosen,
      child: _MarkEditor(controller: controller),
    );

    if (saved != true) return;
    final value = int.tryParse(controller.text);
    if (value == null) return;

    setState(() {
      _subjects.add(SubjectResult(
        subject: chosen,
        percentage: value.clamp(0, 100),
      ));
    });
  }
}

class _MarkEditor extends StatelessWidget {
  final TextEditingController controller;
  const _MarkEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What percentage did you get?',
            style: KhethaText.secondary(p)),
        const SizedBox(height: 14),
        CupertinoTextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          placeholder: 'e.g. 64',
          suffix: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text('%', style: KhethaText.body(p)),
          ),
          style: KhethaText.body(p).copyWith(fontSize: 22),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.glassStroke, width: 0.6),
          ),
          onSubmitted: (_) => closeSheet(context, true),
        ),
        const SizedBox(height: 18),
        KhethaButton(
          label: 'Save',
          onTap: () => closeSheet(context, true),
        ),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectResult result;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _SubjectRow({
    required this.result,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final flagged = result.needsChecking;

    return GlassRow(
      icon: flagged
          ? CupertinoIcons.exclamationmark_circle_fill
          : CupertinoIcons.checkmark_circle,
      iconColor: flagged ? p.warm : p.accent,
      title: result.subject,
      subtitle: result.isLifeOrientation
          ? 'Level ${result.level} · not counted towards APS'
          : 'Level ${result.level} · ${result.levelDescription}',
      onTap: onEdit,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${result.percentage}%',
              style: KhethaText.body(p).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            onPressed: onRemove,
            child: Icon(CupertinoIcons.minus_circle,
                size: 19, color: p.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ApsCard extends StatelessWidget {
  final MatricResults results;
  final bool complete;

  const _ApsCard({required this.results, required this.complete});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final aps = results.aps;

    return GlassCard(
      child: Row(
        children: [
          ScoreRing(
            percent: ((aps / results.maxPossibleAps) * 100).round(),
            label: 'APS $aps out of ${results.maxPossibleAps}',
            size: 72,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('APS $aps', style: KhethaText.title(p)),
                    const SizedBox(width: 8),
                    Chip(results.passType,
                        color: results.hasBachelorPass ? p.accent : p.warm),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  complete
                      ? 'Your best six subjects, excluding Life Orientation. Institutions run their own scales, so treat this as the standard estimate.'
                      : 'Add all your subjects for an accurate score.',
                  style: KhethaText.caption(p),
                ),
                ListenButton(
                  id: 'aps-review',
                  text:
                      'Your APS is $aps out of ${results.maxPossibleAps}. ${results.passType} pass.',
                  label: 'your APS score',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
