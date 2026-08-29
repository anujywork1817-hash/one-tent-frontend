// Shared design primitives that push the UI away from the "generated
// template" look: imperfect angles, a hand-lettered accent font, grain
// texture, and wavy (not ruler-straight) dividers.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Secondary accent colors, used sparingly alongside the gold/maroon brand
/// pair. A palette that only ever reuses one accent color everywhere is one
/// of the clearest "generated from a template" tells — real hand-branded
/// work picks a small family of colors and lets different elements borrow
/// different members of it.
class AppPalette {
  static const terracotta = Color(0xFFC1502E);
  static const sage = Color(0xFF6B7F5E);
  static const indigo = Color(0xFF3B4A6B);
  static const mustard = Color(0xFFC98A1B);

  static const accents = [terracotta, sage, indigo, mustard];

  /// Deterministic pick from [accents] by index — lets sibling items (list
  /// rows, chips, icons) each get a different, stable accent.
  static Color accentFor(int index) => accents[index % accents.length];
}

/// A hard, unblurred, offset shadow — the "cut paper sticker" look, as
/// opposed to the soft blurred glow every Material/AI-template shadow
/// defaults to.
List<BoxShadow> stickerShadow(Color color, {double dx = 4, double dy = 4}) => [
      BoxShadow(color: color, offset: Offset(dx, dy), blurRadius: 0),
    ];

/// Four corner radii nudged slightly apart from a shared [base] instead of
/// perfectly matching circular() on every corner — the asymmetry a hand-cut
/// card edge would actually have.
BorderRadius handDrawnRadius({double base = 16, int seed = 0}) {
  double v(int i) => base + (((seed + i) * 13) % 7) - 3;
  return BorderRadius.only(
    topLeft: Radius.circular(v(0)),
    topRight: Radius.circular(v(1)),
    bottomLeft: Radius.circular(v(2)),
    bottomRight: Radius.circular(v(3)),
  );
}

class AppFonts {
  /// Warm serif for headlines — used in place of the same bold sans-serif
  /// every section title otherwise shares.
  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  /// Hand-lettered accent for small notes, wordmarks, and stamps — never
  /// full paragraphs, just the odd word that should feel written, not set.
  static TextStyle handwritten({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.caveat(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}

/// Rotates its child by a small, fixed angle so it sits very slightly off
/// the grid — one of the cheapest ways to break the too-perfect symmetry
/// that reads as machine-generated. [seed] picks a deterministic angle
/// (varying it between sibling widgets avoids everything tilting in unison).
class Tilt extends StatelessWidget {
  const Tilt({super.key, required this.child, this.seed = 0, this.degrees});

  final Widget child;
  final int seed;
  final double? degrees;

  @override
  Widget build(BuildContext context) {
    // Deterministic pseudo-random angle in [-2.2, 2.2] degrees from [seed],
    // unless the caller pins an exact value via [degrees].
    final angleDeg = degrees ?? (((seed * 37) % 45) / 10 - 2.2);
    return Transform.rotate(
      angle: angleDeg * math.pi / 180,
      child: child,
    );
  }
}

/// A horizontal divider drawn as a slightly irregular hand-drawn line
/// instead of a ruler-straight 1px rule.
class WavyDivider extends StatelessWidget {
  const WavyDivider({
    super.key,
    this.color = const Color(0xFFDDD0C4),
    this.height = 10,
    this.strokeWidth = 1.4,
  });

  final Color color;
  final double height;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavyLinePainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _WavyLinePainter extends CustomPainter {
  _WavyLinePainter({required this.color, required this.strokeWidth});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;
    const waveLength = 14.0;
    const amplitude = 1.6;
    path.moveTo(0, midY);
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      final nextX = math.min(x + waveLength, size.width);
      // Alternate the bow up/down with a little irregularity in amplitude,
      // the way a hand-drawn line never repeats identically.
      final amp = amplitude * (0.7 + 0.3 * ((i % 3) / 2));
      final dy = (i.isEven ? -amp : amp);
      path.quadraticBezierTo((x + nextX) / 2, midY + dy, nextX, midY);
      x = nextX;
      i++;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Subtle paper-grain texture — a scatter of low-opacity dots, meant to sit
/// behind flat-color sections so they read as textured paper rather than a
/// perfectly flat digital fill. Cheap (one CustomPaint, no image asset) and
/// deterministic (fixed seed) so it doesn't repaint differently each frame.
class PaperGrain extends StatelessWidget {
  const PaperGrain({
    super.key,
    this.opacity = 0.05,
    this.color = Colors.black,
  });

  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GrainPainter(color: color.withValues(alpha: opacity)),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7); // fixed seed → stable across rebuilds
    final paint = Paint()..color = color;
    final count = (size.width * size.height / 900).clamp(80, 1400).toInt();
    for (var i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 0.7 + 0.3;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}

/// A rough-edged circular "stamp" — for verification/status badges that
/// should look ink-stamped rather than a clean Material chip.
class InkStamp extends StatelessWidget {
  const InkStamp({
    super.key,
    required this.text,
    this.color = const Color(0xFFD4891A),
    this.size = 64,
    this.degrees = -8,
  });

  final String text;
  final Color color;
  final double size;
  final double degrees;

  @override
  Widget build(BuildContext context) {
    return Tilt(
      degrees: degrees,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: size * 0.16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
