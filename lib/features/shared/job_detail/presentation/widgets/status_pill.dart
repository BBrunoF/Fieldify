import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/job_detail_model.dart';

class StatusPill extends StatelessWidget {
  final JobStatus status;
  const StatusPill({super.key, required this.status});

  String get _label {
    switch (status) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.accepted:
        return 'Accepted';
      case JobStatus.onMyWay:
        return 'On my way';
      case JobStatus.inProgress:
        return 'In progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  ({Color bg, Color fg}) get _colors {
    switch (status) {
      case JobStatus.pending:
        return (bg: Colors.white.withValues(alpha: 0.15), fg: FieldifyColors.g200);
      case JobStatus.accepted:
        return (bg: const Color(0xFFEEF2FF), fg: const Color(0xFF4338CA));
      case JobStatus.onMyWay:
        return (bg: const Color(0xFFFAEEDA), fg: const Color(0xFF854F0B));
      case JobStatus.inProgress:
      case JobStatus.completed:
        return (bg: FieldifyColors.g100, fg: FieldifyColors.g800);
      case JobStatus.cancelled:
        return (bg: const Color(0xFFFDF0EF), fg: const Color(0xFFC0392B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: c.fg,
        ),
      ),
    );
  }
}
