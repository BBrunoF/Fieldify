import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/incoming_job.dart';

class IncomingJobCard extends StatelessWidget {
  final IncomingJob job;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingJobCard({
    super.key,
    required this.job,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Expanded(
                child: Text(
                  job.title.isEmpty ? 'Untitled request' : job.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.ink2,
                  ),
                ),
              ),
              if (job.isRejected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E8D7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'REJECTED',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9A5D14),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FieldifyColors.g100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  job.status.toUpperCase(),
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
            job.description.isEmpty ? 'No description provided.' : job.description,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: FieldifyColors.ink3,
              height: 1.45,
            ),
          ),
          if ((job.addressText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 15, color: FieldifyColors.ink4),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.addressText!,
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: Color(0x1F000000)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    job.isRejected ? 'Reject again' : 'Reject',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.ink2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: FieldifyColors.g800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Accept',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
