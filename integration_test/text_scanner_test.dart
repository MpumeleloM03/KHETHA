import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:khetha_ncap/data/results_parser.dart';
import 'package:khetha_ncap/services/text_scanner.dart';

/// End-to-end test of the on-device text recogniser.
///
/// Runs on a real simulator or device, because the point is the platform
/// channel and Apple's Vision framework — neither of which exists in the Dart
/// VM that the unit tests run in. The results statement is drawn at runtime
/// rather than bundled as a fixture, so nothing test-only ships in the app.
///
///   flutter test integration_test/text_scanner_test.dart -d <device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Renders a results statement to a PNG on disk and returns its path.
  Future<String> drawStatement(List<(String, int, int)> rows) async {
    const width = 1240.0;
    const height = 1754.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );

    void write(String text, double x, double y, {double size = 26, bool bold = false}) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: const ui.Color(0xFF000000),
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, ui.Offset(x, y));
    }

    var y = 80.0;
    write('NATIONAL SENIOR CERTIFICATE', 120, y, size: 34, bold: true);
    y += 54;
    write('STATEMENT OF RESULTS', 120, y, size: 26);
    y += 70;
    write('SUBJECT', 110, y, size: 22, bold: true);
    write('PERCENTAGE', 820, y, size: 22, bold: true);
    write('LEVEL', 1080, y, size: 22, bold: true);
    y += 50;

    for (final (subject, percentage, level) in rows) {
      write(subject, 110, y);
      write('$percentage', 880, y);
      write('$level', 1100, y);
      y += 52;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File(
      '${Directory.systemTemp.path}/khetha_statement_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file.path;
  }

  group('Vision text recognition', () {
    testWidgets('reads a rendered results statement off disk', (tester) async {
      final path = await drawStatement(const [
        ('ENGLISH HOME LANGUAGE', 68, 5),
        ('MATHEMATICS', 45, 3),
        ('ACCOUNTING', 72, 6),
        ('BUSINESS STUDIES', 70, 6),
        ('ECONOMICS', 65, 5),
        ('GEOGRAPHY', 60, 5),
        ('LIFE ORIENTATION', 78, 6),
      ]);

      addTearDown(() => File(path).delete());

      final recognised = await TextScanner.instance.recognise(path);

      expect(recognised.lines, isNotEmpty,
          reason: 'the recogniser returned no lines at all');
      expect(recognised.engine, contains('Vision'));
      expect(recognised.confidence, greaterThan(0));

      // Each table row must come back as one line with its subject and mark
      // together. Vision emits every cell as a separate observation, so the
      // grouping in TextScanner.swift is what makes the parse possible.
      expect(
        recognised.lines.any((l) =>
            l.contains('MATHEMATICS') && l.contains('45')),
        isTrue,
        reason: 'subject and mark were not grouped into one row: '
            '${recognised.lines}',
      );

      final outcome = ResultsParser.parse(
        recognised.lines,
        engine: recognised.engine,
        confidence: recognised.confidence,
      );

      // The whole pipeline: render, recognise, parse, score.
      expect(outcome.subjects.length, greaterThanOrEqualTo(6),
          reason: 'read only ${outcome.subjects.map((s) => s.subject).toList()}');

      int? markFor(String subject) {
        for (final s in outcome.subjects) {
          if (s.subject == subject) return s.percentage;
        }
        return null;
      }

      expect(markFor('Mathematics'), 45);
      expect(markFor('Accounting'), 72);
      expect(markFor('Life Orientation'), 78);
    });

    testWidgets('a file that is not an image fails with a clear message',
        (tester) async {
      final file = File('${Directory.systemTemp.path}/khetha_not_an_image.txt');
      await file.writeAsString('this is not a page of results');
      addTearDown(file.delete);

      await expectLater(
        TextScanner.instance.recognise(file.path),
        throwsA(isA<TextScanException>()),
      );
    });

    testWidgets('a missing file fails rather than hanging', (tester) async {
      await expectLater(
        TextScanner.instance.recognise('/tmp/khetha_does_not_exist.png'),
        throwsA(isA<TextScanException>()),
      );
    });
  });
}
