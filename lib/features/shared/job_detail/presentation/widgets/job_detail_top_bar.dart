import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/job_detail_model.dart';
import 'status_pill.dart';

class JobDetailTopBar extends StatelessWidget {
  final String title;
  final JobStatus status;
  final VoidCallback onBack;

  const JobDetailTopBar({
    super.key,
    required this.title,
    required this.status,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FieldifyColors.g800,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('jobDetailBackButton'),
            onTap: onBack,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: const Icon(Icons.chevron_left, color: FieldifyColors.g100, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(status: status),
        ],
      ),
    );
  }
}
