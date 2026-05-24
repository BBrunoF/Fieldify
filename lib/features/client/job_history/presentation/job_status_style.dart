import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class JobStatusStyle {
  const JobStatusStyle._();

  static Color bgColor(String status) {
    switch (status) {
      case 'on_the_way':
        return const Color(0xFFF6E8D7);
      case 'cancelled':
        return const Color(0xFFF3D7D7);
      default:
        return FieldifyColors.g100;
    }
  }

  static Color fgColor(String status) {
    switch (status) {
      case 'on_the_way':
        return const Color(0xFF9A5D14);
      case 'cancelled':
        return const Color(0xFF8A1F1F);
      default:
        return FieldifyColors.g800;
    }
  }

  static String formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h  ${m.toString().padLeft(2, '0')}m';
  }
}
