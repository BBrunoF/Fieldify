import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/job_detail_model.dart';

class CancellationCard extends StatelessWidget {
  final JobDetail detail;
  const CancellationCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final t = detail.timeline;
    final at = t.cancelledAt?.toLocal();
    final time = at == null
        ? '—'
        : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'CANCELLATION',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.ink3,
                letterSpacing: 0.6,
              ),
            ),
          ),
          _Row(label: 'Cancelled at', value: time),
          if ((t.cancelReason ?? '').isNotEmpty) _Row(label: 'Reason', value: t.cancelReason!),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: FieldifyColors.ink3)),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
