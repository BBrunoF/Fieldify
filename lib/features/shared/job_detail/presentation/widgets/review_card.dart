import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/job_detail_model.dart';

class ReviewCard extends StatelessWidget {
  final String counterpartyName;
  final ReviewSummary? review;

  const ReviewCard({
    super.key,
    required this.counterpartyName,
    this.review,
  });

  @override
  Widget build(BuildContext context) {
    final existing = review;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      child: existing == null
          ? _PromptView(counterpartyName: counterpartyName)
          : _SubmittedView(review: existing, counterpartyName: counterpartyName),
    );
  }
}

class _PromptView extends StatelessWidget {
  final String counterpartyName;
  const _PromptView({required this.counterpartyName});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 6),
        Text(
          'Tap “Submit review” below to rate this job.',
          style: GoogleFonts.dmSans(fontSize: 12, color: FieldifyColors.ink3),
        ),
      ],
    );
  }
}

class _SubmittedView extends StatelessWidget {
  final ReviewSummary review;
  final String counterpartyName;
  const _SubmittedView({required this.review, required this.counterpartyName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your review of $counterpartyName',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: FieldifyColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        _StarsRow(rating: review.rating, interactive: false),
        if ((review.comment ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
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
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int rating;
  final bool interactive;
  final ValueChanged<int>? onChanged;
  const _StarsRow({
    required this.rating,
    required this.interactive,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final value = i + 1;
        final filled = value <= rating;
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 28,
          color: filled ? const Color(0xFFE3A91A) : FieldifyColors.ink4,
        );
        if (!interactive) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: icon,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkResponse(
            onTap: () => onChanged?.call(value),
            radius: 22,
            child: Semantics(
              button: true,
              label: '$value star${value == 1 ? '' : 's'}',
              child: icon,
            ),
          ),
        );
      }),
    );
  }
}

class ReviewSubmissionSheet extends StatefulWidget {
  final String counterpartyName;
  final Future<String?> Function(int rating, String? comment) onSubmit;
  final bool Function() isBusy;

  const ReviewSubmissionSheet({
    super.key,
    required this.counterpartyName,
    required this.onSubmit,
    required this.isBusy,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String counterpartyName,
    required Future<String?> Function(int rating, String? comment) onSubmit,
    required bool Function() isBusy,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewSubmissionSheet(
        counterpartyName: counterpartyName,
        onSubmit: onSubmit,
        isBusy: isBusy,
      ),
    );
  }

  @override
  State<ReviewSubmissionSheet> createState() => _ReviewSubmissionSheetState();
}

class _ReviewSubmissionSheetState extends State<ReviewSubmissionSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _error = 'Please pick a rating.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await widget.onSubmit(_rating, _commentController.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final busy = _submitting || widget.isBusy();
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: FieldifyColors.ink4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Rate ${widget.counterpartyName}',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: FieldifyColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your rating helps other clients pick the right pro.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: FieldifyColors.ink3,
                ),
              ),
              const SizedBox(height: 18),
              _StarsRow(
                rating: _rating,
                interactive: !busy,
                onChanged: (v) => setState(() {
                  _rating = v;
                  _error = null;
                }),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 5,
                enabled: !busy,
                style: GoogleFonts.dmSans(fontSize: 14, color: FieldifyColors.ink),
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: FieldifyColors.ink3,
                  ),
                  filled: true,
                  fillColor: FieldifyColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0x21000000)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0x21000000)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: FieldifyColors.g700),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFFC0392B),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              InkWell(
                key: const Key('reviewSheet.submitButton'),
                onTap: busy ? null : _submit,
                borderRadius: BorderRadius.circular(14),
                child: Opacity(
                  opacity: busy ? 0.5 : 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: FieldifyColors.g800,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                FieldifyColors.g100,
                              ),
                            ),
                          )
                        : Text(
                            'Submit review',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: FieldifyColors.g100,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
