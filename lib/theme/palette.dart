import 'package:flutter/cupertino.dart';

import 'sections.dart';

class Palette {
  static const govGreen = Color(0xFF1B4332);
  static const govGreenLight = Color(0xFF2D6A4F);
  static const govGold = Color(0xFFD4A843);
  static const govGoldLight = Color(0xFFE8C86A);
  static const govRed = Color(0xFFC1121F);

  final Brightness brightness;
  final bool highContrast;
  final KhethaSection section;

  const Palette._(this.brightness, this.highContrast, this.section);

  static Palette of(BuildContext context) {
    final b = CupertinoTheme.brightnessOf(context);
    final hc = MediaQuery.maybeOf(context)?.highContrast ?? false;
    return Palette._(b, hc, KhethaSectionScope.of(context));
  }

  static Palette forBrightness(
    Brightness b, {
    bool highContrast = false,
    KhethaSection section = KhethaSection.today,
  }) =>
      Palette._(b, highContrast, section);

  bool get isDark => brightness == Brightness.dark;

  Color get canvas =>
      isDark ? const Color(0xFF0A1A12) : const Color(0xFFF5F5F0);

  Color get surface =>
      isDark ? const Color(0xFF112A1C) : const Color(0xFFFFFFFF);

  Color get cardSurface =>
      isDark ? const Color(0xFF142E1F) : const Color(0xFFFFFFFF);

  Color get cardSurfaceElevated =>
      isDark ? const Color(0xFF1C3D2A) : const Color(0xFFF7F7F2);

  Color get surfaceRaised =>
      isDark ? const Color(0xFF183626) : const Color(0xFFFFFFFF);

  Color get glassFill => isDark
      ? const Color(0xFF0E2018).withValues(alpha: highContrast ? 0.94 : 0.55)
      : const Color(0xFFFFFFFF).withValues(alpha: highContrast ? 0.96 : 0.62);

  Color get glassBar => isDark
      ? const Color(0xFF081510).withValues(alpha: highContrast ? 0.97 : 0.72)
      : const Color(0xFFFFFFFF).withValues(alpha: highContrast ? 0.98 : 0.78);

  Color get glassStroke => isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: highContrast ? 0.28 : 0.12)
      : const Color(0xFF1B4332).withValues(alpha: highContrast ? 0.24 : 0.08);

  Color get separator => isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
      : const Color(0xFF1B4332).withValues(alpha: 0.08);

  Color get textPrimary =>
      isDark ? const Color(0xFFF0F0EC) : const Color(0xFF1A1A1A);

  Color get textSecondary => isDark
      ? (highContrast ? const Color(0xFFCCCCC5) : const Color(0xFF95A09A))
      : (highContrast ? const Color(0xFF3A3A35) : const Color(0xFF5C665F));

  Color get textTertiary => isDark
      ? const Color(0xFF6B7A72)
      : const Color(0xFF8A928C);

  Color get accent => section.onCanvas(brightness);

  Color get accentFill => section.resolve(brightness);

  Color get accentMuted => accentFill.withValues(alpha: isDark ? 0.20 : 0.12);

  Color get brand => isDark ? govGreenLight : govGreen;

  Color get warm => isDark ? govGoldLight : govGold;

  Color get warmMuted => isDark
      ? govGoldLight.withValues(alpha: 0.18)
      : govGold.withValues(alpha: 0.14);

  Color get onAccent {
    const ink = Color(0xFF10151A);
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    return ratio(accentFill, ink) >= ratio(accentFill, CupertinoColors.white)
        ? ink
        : CupertinoColors.white;
  }

  Color get danger => isDark ? const Color(0xFFFF6B63) : const Color(0xFFC1121F);

  List<Color> get ambientOrbs => isDark
      ? [
          govGreen.withValues(alpha: 0.35),
          govGold.withValues(alpha: 0.12),
        ]
      : [
          govGreen.withValues(alpha: 0.15),
          govGold.withValues(alpha: 0.10),
        ];
}

class KhethaText {
  static TextStyle largeTitle(Palette p) => TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: p.textPrimary,
      );

  static TextStyle title(Palette p) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: p.textPrimary,
      );

  static TextStyle headline(Palette p) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: p.textPrimary,
      );

  static TextStyle body(Palette p) => TextStyle(
        fontSize: 16,
        height: 1.35,
        color: p.textPrimary,
      );

  static TextStyle secondary(Palette p) => TextStyle(
        fontSize: 15,
        height: 1.35,
        color: p.textSecondary,
      );

  static TextStyle caption(Palette p) => TextStyle(
        fontSize: 13,
        height: 1.3,
        color: p.textSecondary,
      );

  static TextStyle sectionLabel(Palette p) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: p.textSecondary,
      );
}
