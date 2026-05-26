import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../payments/data/models/payment_models.dart';
import '../../data/models/job_detail_model.dart';

class PaymentSummaryCard extends StatelessWidget {
  final JobDetail detail;
  final PaymentInfo? payment;
  const PaymentSummaryCard({super.key, required this.detail, this.payment});

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
          if (payment?.isCaptured == true && payment?.amountCharged != null) ...[
            const Divider(height: 1, color: Color(0x14000000)),
            _Row(
              label: 'Charged',
              value: '€${payment!.amountCharged!.toStringAsFixed(2)}',
              emphasised: true,
            ),
            if (payment?.platformFee != null)
              _Row(
                label: 'Platform fee',
                value: '€${payment!.platformFee!.toStringAsFixed(2)}',
              ),
          ] else if (payment?.isAuthorised == true) ...[
            const Divider(height: 1, color: Color(0x14000000)),
            _Row(
              label: 'Authorised (hold)',
              value: '€${payment!.amountAuthorised.toStringAsFixed(2)}',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Held on your card — charged when the job completes.',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: FieldifyColors.ink3),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'No payment recorded for this job.',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: FieldifyColors.ink3),
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
  final bool emphasised;
  const _Row({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

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
              fontSize: emphasised ? 15 : 13,
              fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
              color: FieldifyColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
