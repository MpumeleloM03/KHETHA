import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../data/results_parser.dart';
import '../models/results_models.dart';
import '../services/text_scanner.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import 'results_review_screen.dart';

/// Capture a results statement.
///
/// Three ways in - camera, photo library, PDF - all ending at the same review
/// screen, plus manual entry that never depends on a camera working. Recognition
/// happens on the device through Apple's Vision framework; the image is read and
/// discarded, never uploaded.
class ScanResultsScreen extends StatefulWidget {
  const ScanResultsScreen({super.key});

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _fromCamera() => _scan(() async {
        final file = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 100,
        );
        return file?.path;
      }, 'Photographed');

  Future<void> _fromLibrary() => _scan(() async {
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );
        return file?.path;
      }, 'From photo library');

  Future<void> _fromPdf() => _scan(() async {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        return picked?.files.single.path;
      }, 'From PDF');

  Future<void> _scan(Future<String?> Function() pick, String source) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final path = await pick();
      if (path == null) {
        setState(() => _busy = false);
        return;
      }

      final recognised = await TextScanner.instance.recognise(path);
      final outcome = ResultsParser.parse(
        recognised.lines,
        engine: recognised.engine,
        confidence: recognised.confidence,
      );

      if (!mounted) return;

      if (outcome.subjects.isEmpty) {
        setState(() {
          _busy = false;
          _error =
              'No subjects could be read from that. Try again in better light with the page flat, or enter your results by hand.';
        });
        return;
      }

      setState(() => _busy = false);
      await Navigator.of(context).push(CupertinoPageRoute<void>(
        builder: (_) => ResultsReviewScreen(outcome: outcome, source: source),
      ));
      if (mounted) Navigator.of(context).pop();
    } on TextScanException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Something went wrong reading that file. $e';
      });
    }
  }

  Future<void> _manual() async {
    await Navigator.of(context).push(CupertinoPageRoute<void>(
      builder: (_) => const ResultsReviewScreen(
        outcome: ScanOutcome(
          subjects: [],
          confidence: 1,
          engine: 'Entered by hand',
        ),
        source: 'Entered by hand',
      ),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final scannerAvailable = TextScanner.instance.isSupported;

    return KhethaDetailPage(
      title: 'Your results',
      slivers: [
        SliverSection(children: [
          Text(
            'Add your latest results and Khetha Go can tell you what you qualify for, where the gaps are, and what to do about them.',
            style: KhethaText.secondary(p),
          ),
          const SizedBox(height: 20),

          if (_busy) ...[
            GlassCard(
              child: Row(
                children: [
                  const CupertinoActivityIndicator(radius: 12),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reading your results',
                            style: KhethaText.headline(p)),
                        const SizedBox(height: 3),
                        Text('This happens on your phone. Nothing is uploaded.',
                            style: KhethaText.caption(p)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_error != null) ...[
            GlassCard(
              tint: p.danger,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle_fill,
                      size: 18, color: p.danger),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(_error!, style: KhethaText.body(p)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (scannerAvailable) ...[
            _Option(
              icon: CupertinoIcons.camera_fill,
              title: 'Take a photo',
              subtitle:
                  'Lay the page flat in good light and fill the frame with it.',
              onTap: _busy ? null : _fromCamera,
              primary: true,
            ),
            const SizedBox(height: 10),
            _Option(
              icon: CupertinoIcons.photo_fill,
              title: 'Choose a photo',
              subtitle: 'If you have already photographed your results.',
              onTap: _busy ? null : _fromLibrary,
            ),
            const SizedBox(height: 10),
            _Option(
              icon: CupertinoIcons.doc_fill,
              title: 'Choose a PDF',
              subtitle: 'A statement downloaded from your school or the DBE.',
              onTap: _busy ? null : _fromPdf,
            ),
            const SizedBox(height: 10),
          ],

          _Option(
            icon: CupertinoIcons.keyboard,
            title: 'Enter my results by hand',
            subtitle: scannerAvailable
                ? 'Six subjects takes about a minute.'
                : 'Scanning is not available on this device.',
            onTap: _busy ? null : _manual,
            primary: !scannerAvailable,
          ),

          const SizedBox(height: 22),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.lock_shield_fill,
                        size: 17, color: p.accent),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text('What happens to the photo',
                          style: KhethaText.headline(p)),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'The image is read by your phone’s own text recogniser and then discarded. It is never uploaded, and neither are your marks. You check and correct everything the app read before anything is saved.',
                  style: KhethaText.caption(p),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;

  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: GlassCard(
        onTap: onTap ?? () {},
        tint: primary ? p.accent : null,
        padding: const EdgeInsets.all(16),
        semanticLabel: '$title. $subtitle',
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: primary
                    ? LinearGradient(colors: [p.accent, p.warm])
                    : null,
                color: primary ? null : p.accentMuted,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon,
                  size: 20, color: primary ? p.onAccent : p.accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KhethaText.headline(p)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: KhethaText.caption(p)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}
