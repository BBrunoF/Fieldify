import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/job_detail_model.dart';

class CounterpartyCard extends StatelessWidget {
  final CounterpartyInfo info;
  final VoidCallback? onMessage;
  const CounterpartyCard({super.key, required this.info, this.onMessage});

  String get _subtitle {
    if (info.tradeName != null) {
      return info.isVerifiedPro
          ? '${info.tradeName} · Verified'
          : info.tradeName!;
    }
    return info.phone ?? 'Client';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: FieldifyColors.g800,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              info.initials,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.g100,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.fullName.isEmpty ? '—' : info.fullName,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: FieldifyColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          if (onMessage != null)
            GestureDetector(
              onTap: onMessage,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: FieldifyColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x21000000)),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: FieldifyColors.ink2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
