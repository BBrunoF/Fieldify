import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class ReviewCard extends StatelessWidget {
  final String counterpartyName;
  const ReviewCard({super.key, required this.counterpartyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was $counterpartyName?',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviews coming soon.',
            style: GoogleFonts.dmSans(fontSize: 12, color: FieldifyColors.ink3),
          ),
        ],
      ),
    );
  }
}
