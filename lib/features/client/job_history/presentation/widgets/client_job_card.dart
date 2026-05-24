import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shared/chat/presentation/screens/chat_screen.dart';
import '../../../../shared/job_detail/data/models/job_detail_model.dart';
import '../../../../shared/job_detail/presentation/screens/job_detail_screen.dart';
import '../../data/models/job_history_model.dart';
import '../job_status_style.dart';

class ClientJobCard extends StatelessWidget {
  final ClientJob job;

  const ClientJobCard({super.key, required this.job});

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(
          jobId: job.id,
          viewerRole: ViewerRole.client,
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          requestId: job.id,
          jobStatus: job.status,
          counterpartyName: job.tradeName ?? 'Professional',
          jobTitle: job.title.isEmpty ? 'Untitled request' : job.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActiveStatus = !job.isPast;
    final anchor = job.acceptedAt ?? job.createdAt;
    final showElapsed = isActiveStatus && anchor != null;

    return Container(
      key: Key('clientJobCard_${job.id}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: FieldifyColors.g700,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      job.proInitials,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.g100,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title.isEmpty ? 'Untitled request' : job.title,
                        key: Key('clientJobTitle_${job.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: FieldifyColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.displaySubtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: FieldifyColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: JobStatusStyle.bgColor(job.status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    job.statusLabel,
                    key: Key('clientJobStatus_${job.id}'),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: JobStatusStyle.fgColor(job.status),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showElapsed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color: FieldifyColors.g800,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Time elapsed',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: FieldifyColors.g100,
                      ),
                    ),
                  ),
                  Text(
                    JobStatusStyle.formatElapsed(
                      DateTime.now().difference(anchor),
                    ),
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    job.addressText?.isNotEmpty == true
                        ? job.addressText!
                        : (job.description.isEmpty
                            ? 'No details provided.'
                            : job.description),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: FieldifyColors.ink3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: Key('clientJobMessageButton_${job.id}'),
                  onPressed: () => _openChat(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: const BorderSide(color: Color(0x1F000000)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Message',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.ink2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: Key('clientJobTrackButton_${job.id}'),
                  onPressed: () => _openDetail(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: FieldifyColors.g100,
                    foregroundColor: FieldifyColors.g800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    job.isPast ? 'Details' : 'Track',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
