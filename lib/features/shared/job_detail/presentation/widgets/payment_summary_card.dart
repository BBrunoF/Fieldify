import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/job_detail_model.dart';

class PaymentSummaryCard extends StatelessWidget {
  final JobDetail detail;
  const PaymentSummaryCard({super.key, required this.detail});

  Duration? get _duration {
    final t = detail.timeline;
    if (t.startedAt == null || t.completedAt == null) return null;
    return t.completedAt!.difference(t.startedAt!);
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final d = _duration;
    final rate = detail.trade.standardRate;

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
              'PAYMENT',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.ink3,
                letterSpacing: 0.6,
              ),
            ),
          ),
          _Row(label: 'Duration', value: d == null ? '—' : _fmtDuration(d)),
          _Row(label: 'Rate', value: '€${rate.toStringAsFixed(0)} / h'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Final total pending — payments coming soon.',
              style: GoogleFonts.dmSans(fontSize: 11, color: FieldifyColors.ink3),
            ),
          ),
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
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: FieldifyColors.ink3)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmMono(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
