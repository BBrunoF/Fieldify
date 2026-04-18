// SPLIT FROM: home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  final bool showJobs;

  const BottomNav({
    super.key,
    required this.selected,
    required this.onTap,
    this.showJobs = true,
  });

  static const _labels = ['Home', 'Jobs', 'Messages', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x14000000))),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: (() {
          final visibleIndexes = showJobs ? const [0, 1, 2, 3] : const [0, 2, 3];
          return List.generate(
            visibleIndexes.length,
            (visibleIndex) {
              final i = visibleIndexes[visibleIndex];
              return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(
                    painter: NavIconPainter(
                      index: i,
                      active: selected == i,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[i],
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: selected == i
                        ? FieldifyColors.g800
                        : FieldifyColors.ink4,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: selected == i
                        ? FieldifyColors.g800
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          );
            },
          );
        })(),
      ),
    );
  }
}

/// Bottom nav icons (Home, Jobs, Messages, Profile)
class NavIconPainter extends CustomPainter {
  final int index;
  final bool active;

  const NavIconPainter({required this.index, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 22;
    canvas.save();
    canvas.scale(scale, scale);

    final color = active ? FieldifyColors.g800 : FieldifyColors.ink4;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (index) {
      case 0: // Home
        canvas.drawPath(
          Path()
            ..moveTo(3, 10)
            ..lineTo(11, 3)
            ..lineTo(19, 10)
            ..lineTo(19, 19)
            ..lineTo(14, 19)
            ..lineTo(14, 14)
            ..lineTo(8, 14)
            ..lineTo(8, 19)
            ..lineTo(3, 19)
            ..close(),
          stroke,
        );

      case 1: // Jobs/Calendar
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(3, 5, 16, 14), const Radius.circular(2)),
          stroke,
        );
        canvas.drawLine(const Offset(7, 3), const Offset(7, 7), stroke);
        canvas.drawLine(const Offset(15, 3), const Offset(15, 7), stroke);
        canvas.drawLine(const Offset(3, 10), const Offset(19, 10), stroke);

      case 2: // Messages
        canvas.drawPath(
          Path()
            ..moveTo(4, 4)
            ..lineTo(18, 4)
            ..arcTo(const Rect.fromLTWH(17, 4, 2, 2), -math.pi / 2, math.pi / 2, false)
            ..lineTo(20, 14)
            ..arcTo(const Rect.fromLTWH(17, 13, 2, 2), 0, math.pi / 2, false)
            ..lineTo(7, 15)
            ..lineTo(4, 18)
            ..lineTo(4, 15)
            ..arcTo(const Rect.fromLTWH(3, 13, 2, 2), math.pi / 2, math.pi / 2, false)
            ..lineTo(3, 5)
            ..arcTo(const Rect.fromLTWH(3, 4, 2, 2), math.pi, math.pi / 2, false)
            ..close(),
          stroke,
        );

      case 3: // Profile
        canvas.drawCircle(const Offset(11, 8), 3.5, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4, 19)
            ..cubicTo(4, 15.7, 7.1, 13, 11, 13)
            ..cubicTo(14.9, 13, 18, 15.7, 18, 19),
          stroke,
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant NavIconPainter old) =>
      old.active != active || old.index != index;
}
