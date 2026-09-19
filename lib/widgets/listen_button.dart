import 'package:flutter/cupertino.dart';

import '../services/speech_service.dart';
import '../theme/palette.dart';

/// A "Listen" pill that reads [text] aloud, and stops when tapped again.
///
/// [id] must be unique per piece of content so only the right button shows the
/// stop state. [label] names the content for screen readers ("Listen to
/// Software Developer"). Hidden entirely when Read aloud is off in Settings.
class ListenButton extends StatefulWidget {
  final String id;
  final String text;
  final String label;

  const ListenButton({
    super.key,
    required this.id,
    required this.text,
    required this.label,
  });

  @override
  State<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<ListenButton> {
  @override
  void dispose() {
    // Leaving the screen should silence it. Deferred so listeners are not
    // notified while the tree is being torn down.
    final speech = SpeechService.instance;
    if (speech.isSpeaking(widget.id)) Future.microtask(speech.stop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final speech = SpeechService.instance;

    return ListenableBuilder(
      listenable: speech,
      builder: (context, _) {
        if (!speech.enabled) return const SizedBox.shrink();
        final speaking = speech.isSpeaking(widget.id);

        return Semantics(
          button: true,
          label: speaking ? 'Stop reading aloud' : 'Listen to ${widget.label}',
          excludeSemantics: true,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            onPressed: () => speech.speak(widget.id, widget.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: p.accentMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    speaking
                        ? CupertinoIcons.stop_fill
                        : CupertinoIcons.speaker_2_fill,
                    size: 16,
                    color: p.accent,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    speaking ? 'Stop' : 'Listen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
