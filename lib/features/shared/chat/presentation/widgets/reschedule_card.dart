import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/message_model.dart';

class RescheduleCard extends StatelessWidget {
  final Message message;
  final bool isMine;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RescheduleCard({
    super.key,
    required this.message,
    required this.isMine,
    required this.onAccept,
    required this.onReject,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatted(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final proposed = message.rescheduleProposedAt;
    final status = message.rescheduleStatus ?? RescheduleStatus.pending;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldifyColors.g100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FieldifyColors.g200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_repeat,
                size: 16,
                color: FieldifyColors.g800,
              ),
              const SizedBox(width: 6),
              Text(
                'RESCHEDULE REQUEST',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FieldifyColors.g800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isMine
                ? 'You proposed a new date and time:'
                : 'A new date and time was proposed:',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: FieldifyColors.ink2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            proposed != null ? _formatted(proposed) : '—',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: FieldifyColors.ink,
            ),
          ),
          if (message.content.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message.content.trim(),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: FieldifyColors.ink2,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildFooter(status),
        ],
      ),
    );
  }

  Widget _buildFooter(RescheduleStatus status) {
    if (status == RescheduleStatus.accepted) {
      return _statusChip('Accepted — schedule updated', FieldifyColors.g800);
    }
    if (status == RescheduleStatus.rejected) {
      return _statusChip('Declined — original time kept', FieldifyColors.ink3);
    }
    // pending
    if (isMine) {
      return _statusChip('Waiting for a response…', FieldifyColors.ink3);
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('rescheduleRejectButton'),
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: FieldifyColors.ink2,
              side: const BorderSide(color: FieldifyColors.ink4),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              'Decline',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            key: const Key('rescheduleAcceptButton'),
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: FieldifyColors.g800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              'Accept',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FieldifyColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
