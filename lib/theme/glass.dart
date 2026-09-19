import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import '../state/app_state.dart';
import 'palette.dart';

/// Frosted panel used for every card in the app.
///
/// Renders through `liquid_glass_widgets`, which puts a real shader-based
/// refraction behind the surface instead of a `BackdropFilter` approximation.
/// The API is unchanged from the hand-rolled version it replaces, so every
/// existing call site keeps working.
///
/// The glass body stays neutral and translucent. What carries section identity
/// is the rim: a one-pixel stroke plus a soft outer bloom in the active
/// section's colour. That has to be composited *outside* the glass because
/// `LiquidGlassSettings` has no border-colour or specular-colour field - the
/// shader derives its rim from the backdrop and the glass tint, so the only way
/// to get an exact brand hex on the edge is to draw it yourself. This is what
/// the package does internally for its own bordered surfaces.
///
/// Degrades on purpose: with Low-bandwidth mode on, or the OS reporting Reduce
/// Transparency, the shader is dropped for a solid surface. Nothing in the
/// layout depends on the effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;

  /// Overrides the section colour for this card's rim. Used for state that
  /// outranks the section - a warning, a danger, a success.
  final Color? tint;
  final String? semanticLabel;

  /// When true, renders with the glass shader + coloured rim.
  /// When false (default), renders as a flat solid card.
  final bool useGlass;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = 16,
    this.onTap,
    this.tint,
    this.semanticLabel,
    this.useGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final effects = AppScope.of(context).visualEffectsEnabled;
    final accent = tint ?? p.accentFill;
    final border = BorderRadius.circular(radius);

    Widget surface;

    if (useGlass && effects) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: border,
          border: Border.all(
            color: accent.withValues(alpha: p.isDark ? 0.38 : 0.30),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: p.isDark ? 0.22 : 0.14),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
        child: lg.GlassCard(
          padding: padding,
          shape: lg.LiquidRoundedSuperellipse(borderRadius: radius),
          child: child,
        ),
      );
    } else {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          color: p.cardSurface,
          borderRadius: border,
        ),
        child: Padding(padding: padding, child: child),
      );
    }

    if (onTap != null) {
      surface = _PressableScale(onTap: onTap!, child: surface);
    }
    if (semanticLabel != null) {
      surface = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: surface,
      );
    }

    return margin == null ? surface : Padding(padding: margin!, child: surface);
  }
}

/// The per-screen glass layer every [GlassCard] below it shares.
///
/// One shader pass for the whole screen instead of one per card. Also where the
/// section tint enters the glass body itself, at a low enough alpha that the
/// body still reads as neutral.
class KhethaGlassLayer extends StatelessWidget {
  final Widget child;
  const KhethaGlassLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    if (!AppScope.of(context).visualEffectsEnabled) return child;

    return lg.AdaptiveLiquidGlassLayer(
      settings: lg.LiquidGlassSettings(
        glassColor: p.isDark
            ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.55),
        thickness: p.isDark ? 10 : 12,
        blur: p.isDark ? 5 : 6,
        lightIntensity: p.isDark ? 0.7 : 0.85,
        ambientStrength: p.isDark ? 0.0 : 0.15,
        edgeAbsorption: p.isDark ? 0.12 : 0.08,
        saturation: 1.15,
      ),
      child: child,
    );
  }
}

/// iOS-style press feedback: a small, fast scale-down with a spring release.
/// Honours the system Reduce Motion setting.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 240),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => reduceMotion ? null : _c.forward(),
      onTapCancel: () => _c.reverse(),
      onTapUp: (_) => _c.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(
          scale: 1 - (_c.value * 0.022),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Soft brand-coloured light sources behind the canvas. They exist so the
/// frosted panels have something to refract - glass over a flat colour just
/// looks like a grey box.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final effects = AppScope.of(context).visualEffectsEnabled;

    if (!effects) {
      return ColoredBox(color: p.canvas, child: child);
    }

    final orbs = p.ambientOrbs;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: p.canvas)),
        Positioned(
          top: -140,
          left: -110,
          child: _Orb(color: orbs[0], size: 380),
        ),
        Positioned(
          top: 220,
          right: -150,
          child: _Orb(color: orbs[1], size: 330),
        ),
        Positioned(
          bottom: -170,
          left: -60,
          child: _Orb(color: orbs[0].withValues(alpha: 0.5), size: 400),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// A grouped list section in the style of the iOS Settings app, rebuilt on
/// glass so it matches the rest of the app.
class GlassSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  const GlassSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Container(height: 0.6, color: p.separator),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(header!.toUpperCase(),
                style: KhethaText.sectionLabel(p)),
          ),
        GlassCard(
          padding: EdgeInsets.zero,
          radius: 20,
          child: Column(children: rows),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(footer!, style: KhethaText.caption(p)),
          ),
      ],
    );
  }
}

/// One row inside a [GlassSection]. Guaranteed to meet the 44pt minimum
/// touch target from the iOS Human Interface Guidelines.
class GlassRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  const GlassRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: (iconColor ?? p.accent).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon,
                    size: 17, color: iconColor ?? p.accent),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: KhethaText.body(p)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: KhethaText.caption(p)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(CupertinoIcons.chevron_right,
                  size: 15, color: p.textTertiary),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: _PressableScale(onTap: onTap!, child: row),
    );
  }
}

/// Filled capsule button - the primary action style.
class KhethaButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool secondary;
  final bool expand;

  const KhethaButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.secondary = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final enabled = onTap != null;
    // A filled button is a surface (brand hex + matched foreground); a
    // secondary button is ink on a wash, so it takes the legible variant.
    final bg = secondary ? p.accentMuted : p.accentFill;
    final fg = secondary ? p.accent : p.onAccent;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: _PressableScale(
        onTap: onTap ?? () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Small rounded label used for metadata (NQF level, province, demand).
class Chip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  const Chip(this.label, {super.key, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = color ?? p.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: c),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}
