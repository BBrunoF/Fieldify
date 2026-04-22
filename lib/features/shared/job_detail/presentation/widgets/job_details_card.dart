import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/job_detail_model.dart';

class JobDetailsCard extends StatelessWidget {
  final JobDetail detail;
  const JobDetailsCard({super.key, required this.detail});

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool)>[
      ('Category', detail.trade.displayName, false),
      ('Title', detail.title, false),
      ('Address', detail.addressText, false),
      ('Submitted', _formatDateTime(detail.timeline.createdAt), true),
      ('Rate', '€${detail.trade.standardRate.toStringAsFixed(0)} / h', true),
      (
        'When',
        detail.timeline.scheduledAt == null
            ? 'As soon as possible'
            : _formatDateTime(detail.timeline.scheduledAt!),
        false,
      ),
    ];

    return _Card(
      title: 'Job details',
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _Row(
              label: rows[i].$1,
              value: rows[i].$2,
              mono: rows[i].$3,
              topBorder: true,
            ),
          if (detail.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  detail.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: FieldifyColors.ink2,
                    height: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
              title.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.ink3,
                letterSpacing: 0.6,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool topBorder;
  const _Row({
    required this.label,
    required this.value,
    required this.mono,
    required this.topBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: topBorder
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x14000000))),
            )
          : null,
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 12, color: FieldifyColors.ink3),
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (mono ? GoogleFonts.dmMono : GoogleFonts.dmSans)(
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
