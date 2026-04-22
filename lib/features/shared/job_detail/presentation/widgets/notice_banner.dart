import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

enum NoticeKind { info, warn, danger }

class NoticeBanner extends StatelessWidget {
  final NoticeKind kind;
  final String text;
  const NoticeBanner({super.key, required this.kind, required this.text});

  ({Color bg, Color fg}) get _colors {
    switch (kind) {
      case NoticeKind.info:
        return (bg: FieldifyColors.g100, fg: FieldifyColors.g800);
      case NoticeKind.warn:
        return (bg: const Color(0xFFFAEEDA), fg: const Color(0xFF854F0B));
      case NoticeKind.danger:
        return (bg: const Color(0xFFFDF0EF), fg: const Color(0xFFC0392B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(fontSize: 12, color: c.fg, height: 1.5),
      ),
    );
  }
}
