import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../models/career_models.dart';
import '../theme/palette.dart';

/// Circular fit indicator. The number is always paired with the label so a
/// percentage never stands alone without its meaning - and the label is what
/// screen readers announce.
class ScoreRing extends StatelessWidget {
  final int percent;
  final String label;
  final double size;
  final Color? color;

  const ScoreRing({
    super.key,
    required this.percent,
    required this.label,
    this.size = 74,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = color ?? p.accent;
    return Semantics(
      label: '$label, $percent percent fit',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: percent / 100,
            track: p.separator,
            color: c,
            stroke: size * 0.09,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent',
                  style: TextStyle(
                    fontSize: size * 0.30,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '%',
                  style: TextStyle(
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.w600,
                    color: p.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color track;
  final Color color;
  final double stroke;

  _RingPainter({
    required this.value,
    required this.track,
    required this.color,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

/// Horizontal bar with a label and value. Used for trait strength and for the
/// evidence breakdown behind a match.
class LabelledBar extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final String? valueLabel;
  final Color? color;

  const LabelledBar({
    super.key,
    required this.label,
    required this.value,
    this.valueLabel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = color ?? p.accent;
    final v = value.clamp(0.0, 1.0);

    return Semantics(
      label: '$label, ${(v * 100).round()} percent',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: KhethaText.caption(p)),
                ),
                Text(
                  valueLabel ?? '${(v * 100).round()}%',
                  style: KhethaText.caption(p).copyWith(
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                children: [
                  Container(height: 7, color: p.separator),
                  LayoutBuilder(
                    builder: (context, box) => AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      height: 7,
                      width: box.maxWidth * v,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c.withValues(alpha: 0.75), c],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Six-axis interest plot for the RIASEC profile.
///
/// Drawn rather than charted with a library: one painter is a fraction of the
/// dependency weight, and it can be themed exactly to the rest of the app.
class RiasecChart extends StatelessWidget {
  final Map<Riasec, double> scores;
  final double size;

  const RiasecChart({super.key, required this.scores, this.size = 220});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    const ordered = Riasec.values;
    final max = scores.values.isEmpty
        ? 1.0
        : scores.values.reduce(math.max).clamp(0.0001, double.infinity);

    return Semantics(
      label: 'Interest profile chart. '
          '${ordered.map((r) => '${r.label} ${((scores[r] ?? 0) / max * 100).round()} percent').join(', ')}',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RadarPainter(
            values: [for (final r in ordered) (scores[r] ?? 0) / max],
            labels: [for (final r in ordered) r.code],
            grid: p.separator,
            fill: p.accent.withValues(alpha: 0.26),
            stroke: p.accent,
            labelColor: p.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color grid;
  final Color fill;
  final Color stroke;
  final Color labelColor;

  _RadarPainter({
    required this.values,
    required this.labels,
    required this.grid,
    required this.fill,
    required this.stroke,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final n = values.length;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = grid;

    // Concentric rings
    for (var ring = 1; ring <= 3; ring++) {
      final r = radius * ring / 3;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + (math.pi * 2 * i / n);
        final pt = centre + Offset(math.cos(a) * r, math.sin(a) * r);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Spokes
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (math.pi * 2 * i / n);
      canvas.drawLine(
        centre,
        centre + Offset(math.cos(a) * radius, math.sin(a) * radius),
        gridPaint,
      );
    }

    // Data polygon
    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (math.pi * 2 * i / n);
      final r = radius * values[i].clamp(0.0, 1.0);
      final pt = centre + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
    }
    dataPath.close();
    canvas.drawPath(dataPath, Paint()..color = fill);
    canvas.drawPath(
      dataPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = stroke,
    );

    // Vertex dots
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (math.pi * 2 * i / n);
      final r = radius * values[i].clamp(0.0, 1.0);
      canvas.drawCircle(
        centre + Offset(math.cos(a) * r, math.sin(a) * r),
        3,
        Paint()..color = stroke,
      );
    }

    // Axis labels
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (math.pi * 2 * i / n);
      final pt = centre + Offset(math.cos(a) * (radius + 14),
          math.sin(a) * (radius + 14));
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pt - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.values != values;
}

/// Thin progress track used for journey completion.
class ProgressTrack extends StatelessWidget {
  final double value;
  const ProgressTrack({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(height: 9, color: p.separator),
          LayoutBuilder(
            builder: (context, box) => AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: 9,
              width: box.maxWidth * value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [p.accent, p.warm]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
