import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shared/job_detail/data/models/job_detail_model.dart';
import '../../../../shared/job_detail/presentation/screens/job_detail_screen.dart';
import '../../data/models/accepted_job.dart';

class AcceptedJobCard extends StatelessWidget {
  final AcceptedJob job;
  final VoidCallback? onCancel;

  const AcceptedJobCard({super.key, required this.job, this.onCancel});

  String get _statusLabel {
    switch (job.status) {
      case 'accepted':
        return 'Accepted';
      case 'on_my_way':
      case 'on_the_way':
        return 'On my way';
      case 'in_progress':
        return 'In progress';
      default:
        return job.status.isEmpty ? '-' : job.status;
    }
  }

  String get _acceptedLabel {
    final acceptedAt = job.acceptedAt;
    if (acceptedAt == null) return 'Accepted date unavailable';

    final local = acceptedAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Accepted $day/$month/${local.year} at $hour:$minute';
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            JobDetailScreen(jobId: job.id, viewerRole: ViewerRole.pro),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('acceptedJobCardTap_${job.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title.isEmpty ? 'Untitled request' : job.title,
                    key: Key('acceptedJobTitle_${job.id}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.ink2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: FieldifyColors.g100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel,
                    key: Key('acceptedJobStatus_${job.id}'),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: FieldifyColors.g800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description.isEmpty
                  ? 'No description provided.'
                  : job.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: FieldifyColors.ink3,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 15,
                  color: FieldifyColors.ink4,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _acceptedLabel,
                    key: Key('acceptedJobAcceptedAt_${job.id}'),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: FieldifyColors.ink4,
                    ),
                  ),
                ),
              ],
            ),
            if ((job.addressText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 15,
                    color: FieldifyColors.ink4,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.addressText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: FieldifyColors.ink4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: Key('acceptedJobCancelButton_${job.id}'),
              onPressed: onCancel,
              icon: const Icon(Icons.undo_outlined, size: 16),
              label: Text(
                'Cancel job',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                foregroundColor: const Color(0xFFC0392B),
                side: const BorderSide(color: Color(0xFFF5C6C6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
