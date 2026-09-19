import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/theme/palette.dart';
import 'package:khetha_ncap/theme/sections.dart';

void main() {
  Future<Palette> paletteIn(
    WidgetTester tester,
    KhethaSection section,
    Brightness brightness,
  ) async {
    late Palette captured;
    await tester.pumpWidget(
      CupertinoApp(
        theme: CupertinoThemeData(brightness: brightness),
        home: KhethaSectionScope(
          section: section,
          child: Builder(builder: (context) {
            captured = Palette.of(context);
            return const SizedBox.shrink();
          }),
        ),
      ),
    );
    return captured;
  }

  group('section colours', () {
    test('each section carries its government hex', () {
      expect(KhethaSection.today.light, const Color(0xFF1B4332));
      expect(KhethaSection.explore.light, const Color(0xFF2D6A4F));
      expect(KhethaSection.apply.light, const Color(0xFF1967D2));
      expect(KhethaSection.support.light, const Color(0xFF40916C));
      expect(KhethaSection.settings.light, const Color(0xFF3A3A35));
    });

    test('every section is a distinct colour in both appearances', () {
      for (final b in Brightness.values) {
        final colours =
            KhethaSection.values.map((s) => s.resolve(b).toARGB32()).toSet();
        expect(colours.length, KhethaSection.values.length,
            reason: 'two sections share a colour in $b');
      }
    });
  });

  group('contrast against the neutral backdrops', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    test('the ink variant of every section is legible on its background', () {
      for (final s in KhethaSection.values) {
        for (final b in Brightness.values) {
          final bg = Palette.forBrightness(b).canvas;
          final ratio = contrast(s.onCanvas(b), bg);
          expect(ratio, greaterThanOrEqualTo(3.0),
              reason: '$s in $b is ${ratio.toStringAsFixed(2)}:1 on the backdrop');
        }
      }
    });

    test('the backdrops are the specified neutrals', () {
      expect(Palette.forBrightness(Brightness.dark).canvas,
          const Color(0xFF0A1A12));
      expect(Palette.forBrightness(Brightness.light).canvas,
          const Color(0xFFF5F5F0));
    });
  });

  group('the palette follows the scope', () {
    testWidgets('accent is the enclosing section, not a fixed brand colour',
        (tester) async {
      for (final section in KhethaSection.values) {
        final p = await paletteIn(tester, section, Brightness.dark);
        expect(p.accentFill, section.dark,
            reason: '$section did not reach the palette');
        expect(p.accent, section.onCanvas(Brightness.dark));
      }
    });

    testWidgets('outside any scope the app still has a colour', (tester) async {
      late Palette captured;
      await tester.pumpWidget(CupertinoApp(
        home: Builder(builder: (context) {
          captured = Palette.of(context);
          return const SizedBox.shrink();
        }),
      ));
      expect(captured.accentFill, KhethaSection.today.light);
    });

    testWidgets('foreground on accent stays readable', (tester) async {
      for (final section in KhethaSection.values) {
        for (final b in Brightness.values) {
          final p = await paletteIn(tester, section, b);
          final la = p.accentFill.computeLuminance();
          final lo = p.onAccent.computeLuminance();
          final hi = la > lo ? la : lo;
          final low = la > lo ? lo : la;
          final ratio = (hi + 0.05) / (low + 0.05);
          expect(ratio, greaterThanOrEqualTo(4.3),
              reason: 'text on $section in $b is only '
                  '${ratio.toStringAsFixed(2)}:1');
        }
      }
    });
  });
}
