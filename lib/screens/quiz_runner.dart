import 'package:flutter/cupertino.dart';

import '../models/career_models.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/listen_button.dart';

/// Shared questionnaire flow used by both Job Fit and Career Choice.
///
/// One question per screen, large tap targets, an explicit progress bar and a
/// working Back button. Designed for a learner who may be reading on a small,
/// cracked screen and who will abandon anything that feels like a test.
class QuizRunner extends StatefulWidget {
  final String title;
  final String intro;
  final List<QuizQuestion> questions;

  /// Receives one selected option per question, in order.
  final void Function(List<QuizOption> answers) onComplete;

  const QuizRunner({
    super.key,
    required this.title,
    required this.intro,
    required this.questions,
    required this.onComplete,
  });

  @override
  State<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<QuizRunner> {
  int _index = -1; // -1 is the intro card
  final List<QuizOption> _answers = [];

  void _select(QuizOption option) {
    setState(() {
      if (_answers.length > _index) {
        _answers[_index] = option;
      } else {
        _answers.add(option);
      }
    });

    // A short pause so the selection is visibly registered before the screen
    // changes - without it the app feels like it skipped the answer.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_index < widget.questions.length - 1) {
        setState(() => _index++);
      } else {
        widget.onComplete(_answers);
      }
    });
  }

  void _back() {
    if (_index <= -1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final total = widget.questions.length;
    final atIntro = _index < 0;
    final progress = atIntro ? 0.0 : (_index) / total;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: ColoredBox(
        color: Palette.of(context).canvas,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 20, 6),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(44, 44),
                      onPressed: _back,
                      child: Icon(CupertinoIcons.chevron_left,
                          color: p.accent, size: 22),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: KhethaText.headline(p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!atIntro)
                      Text('${_index + 1} / $total',
                          style: KhethaText.caption(p)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(height: 4, color: p.separator),
                      LayoutBuilder(
                        builder: (context, box) => AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          height: 4,
                          width: box.maxWidth * progress,
                          color: p.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: atIntro
                      ? _Intro(
                          key: const ValueKey('intro'),
                          text: widget.intro,
                          count: total,
                          onStart: () => setState(() => _index = 0),
                        )
                      : _Question(
                          key: ValueKey(_index),
                          question: widget.questions[_index],
                          selected: _answers.length > _index
                              ? _answers[_index]
                              : null,
                          onSelect: _select,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final String text;
  final int count;
  final VoidCallback onStart;

  const _Intro({
    super.key,
    required this.text,
    required this.count,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [p.accent, p.warm]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(CupertinoIcons.chat_bubble_2_fill,
                      color: p.onAccent, size: 23),
                ),
                const SizedBox(height: 18),
                Text(text, style: KhethaText.body(p).copyWith(fontSize: 17)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Chip('$count questions',
                        color: p.accent, icon: CupertinoIcons.list_number),
                    const SizedBox(width: 7),
                    Chip('No wrong answers',
                        color: p.textSecondary,
                        icon: CupertinoIcons.checkmark_circle),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          KhethaButton(
            label: 'Start',
            icon: CupertinoIcons.arrow_right_circle_fill,
            onTap: onStart,
          ),
        ],
      ),
    );
  }
}

class _Question extends StatelessWidget {
  final QuizQuestion question;
  final QuizOption? selected;
  final ValueChanged<QuizOption> onSelect;

  const _Question({
    super.key,
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(question.question, style: KhethaText.largeTitle(p).copyWith(
                fontSize: 27,
              )),
          if (question.helper != null) ...[
            const SizedBox(height: 8),
            Text(question.helper!, style: KhethaText.secondary(p)),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: ListenButton(
              id: 'quiz-${question.question}',
              text: '${question.question} '
                  '${question.helper ?? ''} '
                  'Options. ${question.options.map((o) => o.label).join('. ')}.',
              label: 'this question',
            ),
          ),
          const SizedBox(height: 14),
          for (final option in question.options) ...[
            _OptionCard(
              option: option,
              selected: identical(option, selected),
              onTap: () => onSelect(option),
            ),
            const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final QuizOption option;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      onTap: onTap,
      tint: selected ? p.accent : null,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      semanticLabel: option.label,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? p.accent : const Color(0x00000000),
              border: Border.all(
                color: selected ? p.accent : p.textTertiary,
                width: 1.6,
              ),
            ),
            child: selected
                ? Icon(CupertinoIcons.checkmark,
                    size: 14, color: p.onAccent)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              option.label,
              style: KhethaText.body(p).copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
