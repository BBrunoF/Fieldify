import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ── Service icon types ────────────────────────────────────────────────────────
enum ServiceIconType { plumbing, electrical, carpentry, hvac, painting, other }

// ── Service icon painter ──────────────────────────────────────────────────────
class ServiceIconPainter extends CustomPainter {
  final ServiceIconType icon;
  final Color color;

  const ServiceIconPainter({required this.icon, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale, scale);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (icon) {
      case ServiceIconType.plumbing:
        canvas.drawPath(
          Path()
            ..moveTo(5, 19)
            ..lineTo(5, 9)
            ..lineTo(12, 4)
            ..lineTo(19, 9)
            ..lineTo(19, 19),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(9, 14, 6, 5),
            const Radius.circular(1),
          ),
          stroke,
        );

      case ServiceIconType.electrical:
        canvas.drawCircle(const Offset(12, 12), 3, stroke);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            Offset(12 + math.cos(a) * 6, 12 + math.sin(a) * 6),
            Offset(12 + math.cos(a) * 9, 12 + math.sin(a) * 9),
            stroke,
          );
        }

      case ServiceIconType.carpentry:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 7, 18, 10),
            const Radius.circular(2),
          ),
          stroke,
        );
        for (final x in [7.0, 12.0, 17.0]) {
          canvas.drawLine(Offset(x, 7), Offset(x, 6), stroke);
        }

      case ServiceIconType.hvac:
        canvas.drawPath(
          Path()
            ..moveTo(6, 12)
            ..arcTo(const Rect.fromLTWH(6, 6, 12, 12), math.pi, math.pi, false),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(9, 13, 6, 5),
            const Radius.circular(1.5),
          ),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        canvas.drawLine(const Offset(3, 12), const Offset(5, 12), stroke);
        canvas.drawLine(const Offset(19, 12), const Offset(21, 12), stroke);

      case ServiceIconType.painting:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.drawLine(const Offset(3, 8), const Offset(21, 8), stroke);
        canvas.drawLine(const Offset(8, 8), const Offset(8, 21), stroke);

      case ServiceIconType.other:
        canvas.drawCircle(const Offset(12, 12), 7, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(12, 8)
            ..lineTo(12, 12)
            ..lineTo(15, 14),
          stroke,
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ServiceIconPainter old) =>
      old.icon != icon || old.color != color;
}

// ── Map painter (road grid) ───────────────────────────────────────────────────
class MapPainter extends CustomPainter {
  /// SVG viewbox dimensions the block/road coordinates are based on.
  final double vw;
  final double vh;

  const MapPainter({this.vw = 342, this.vh = 160});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / vw, size.height / vh);

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, vw, vh),
      Paint()..color = const Color(0xFFD8EDBC),
    );

    // Blocks
    final bp = Paint()..color = const Color(0xFFC8E4A8);
    if (vw > 340) {
      // Home map blocks (342×160)
      for (final r in const [
        Rect.fromLTWH(0, 0, 90, 55),
        Rect.fromLTWH(100, 0, 70, 45),
        Rect.fromLTWH(180, 0, 80, 60),
        Rect.fromLTWH(270, 0, 72, 50),
        Rect.fromLTWH(0, 65, 75, 50),
        Rect.fromLTWH(85, 55, 95, 55),
        Rect.fromLTWH(190, 70, 65, 45),
        Rect.fromLTWH(265, 60, 77, 55),
        Rect.fromLTWH(0, 125, 100, 35),
        Rect.fromLTWH(110, 120, 80, 40),
        Rect.fromLTWH(200, 125, 70, 35),
        Rect.fromLTWH(280, 125, 62, 35),
      ]) {
        canvas.drawRect(r, bp);
      }
      final rp = Paint()..color = const Color(0xFFEAF3DE);
      canvas.drawRect(const Rect.fromLTWH(0, 55, 342, 10), rp);
      canvas.drawRect(const Rect.fromLTWH(0, 115, 342, 10), rp);
      canvas.drawRect(const Rect.fromLTWH(90, 0, 10, 160), rp);
      canvas.drawRect(const Rect.fromLTWH(170, 0, 10, 160), rp);
      canvas.drawRect(const Rect.fromLTWH(255, 0, 10, 160), rp);
      final dp = _dashPaint;
      _dash(canvas, const Offset(0, 60), const Offset(342, 60), dp);
      _dash(canvas, const Offset(0, 120), const Offset(342, 120), dp);
      _dash(canvas, const Offset(95, 0), const Offset(95, 160), dp);
      _dash(canvas, const Offset(175, 0), const Offset(175, 160), dp);
      _dash(canvas, const Offset(260, 0), const Offset(260, 160), dp);
    } else {
      // Location step map blocks (350×120)
      for (final r in const [
        Rect.fromLTWH(0, 0, 80, 42),
        Rect.fromLTWH(90, 0, 65, 36),
        Rect.fromLTWH(165, 0, 75, 48),
        Rect.fromLTWH(250, 0, 100, 42),
        Rect.fromLTWH(0, 52, 70, 40),
        Rect.fromLTWH(80, 46, 85, 46),
        Rect.fromLTWH(175, 58, 60, 36),
        Rect.fromLTWH(245, 52, 105, 44),
      ]) {
        canvas.drawRect(r, bp);
      }
      final rp = Paint()..color = const Color(0xFFEAF3DE);
      canvas.drawRect(const Rect.fromLTWH(0, 42, 350, 8), rp);
      canvas.drawRect(const Rect.fromLTWH(0, 92, 350, 8), rp);
      canvas.drawRect(const Rect.fromLTWH(80, 0, 8, 120), rp);
      canvas.drawRect(const Rect.fromLTWH(163, 0, 8, 120), rp);
      canvas.drawRect(const Rect.fromLTWH(243, 0, 8, 120), rp);
      final dp = _dashPaint;
      _dash(canvas, const Offset(0, 46), const Offset(350, 46), dp);
      _dash(canvas, const Offset(0, 96), const Offset(350, 96), dp);
      _dash(canvas, const Offset(84, 0), const Offset(84, 120), dp);
      _dash(canvas, const Offset(167, 0), const Offset(167, 120), dp);
      _dash(canvas, const Offset(247, 0), const Offset(247, 120), dp);
    }

    canvas.restore();
  }

  static final _dashPaint = Paint()
    ..color = const Color(0xFFA8C87A)
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;

  static void _dash(Canvas c, Offset a, Offset b, Paint p) {
    final d = b - a;
    final len = d.distance;
    final n = d / len;
    var pos = 0.0;
    while (pos < len) {
      final end = math.min(pos + 8.0, len);
      c.drawLine(a + n * pos, a + n * end, p);
      pos += 14.0;
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter old) => old.vw != vw || old.vh != vh;
}

// ── Reusable map pin widget ───────────────────────────────────────────────────
class MapPin extends StatelessWidget {
  final double size;
  const MapPin({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: FieldifyColors.g800,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: const BoxDecoration(
                color: FieldifyColors.g200,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: size * 0.36,
          height: size * 0.14,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(38),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ],
    );
  }
}
