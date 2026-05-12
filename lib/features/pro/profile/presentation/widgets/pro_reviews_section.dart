import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/pro_profile_model.dart';

class ProReviewsSection extends StatelessWidget {
  final ProRatingSummary summary;
  final List<ProReview> reviews;
  final bool isLoading;

  const ProReviewsSection({
    super.key,
    required this.summary,
    required this.reviews,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FieldifyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(summary: summary),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                'No reviews yet.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: FieldifyColors.ink3,
                ),
              ),
            )
          else
            for (int i = 0; i < reviews.length; i++) ...[
              const Divider(height: 1, color: Color(0x14000000)),
              _ReviewTile(review: reviews[i]),
            ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ProRatingSummary summary;
  const _Header({required this.summary});

  @override
  Widget build(BuildContext context) {
    final hasRatings = summary.count > 0;
    final avgText = hasRatings ? summary.average.toStringAsFixed(1) : '—';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            size: 22,
            color: hasRatings ? const Color(0xFFE3A91A) : FieldifyColors.ink4,
          ),
          const SizedBox(width: 6),
          Text(
            avgText,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FieldifyColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasRatings
                ? '${summary.count} review${summary.count == 1 ? '' : 's'}'
                : 'No reviews yet',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: FieldifyColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProReview review;
  const _ReviewTile({required this.review});

  String get _initials {
    final parts = review.clientName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get _dateLabel {
    final d = review.createdAt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: FieldifyColors.g800,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.g100,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.clientName.isEmpty ? 'Client' : review.clientName,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _dateLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: FieldifyColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final filled = i < review.rating;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: filled ? const Color(0xFFE3A91A) : FieldifyColors.ink4,
                ),
              );
            }),
          ),
          if ((review.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: FieldifyColors.ink2,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
