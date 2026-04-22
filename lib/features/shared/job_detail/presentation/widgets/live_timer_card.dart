import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class LiveTimerCard extends StatefulWidget {
  final DateTime startedAt;
  final double ratePerHour;
  const LiveTimerCard({
    super.key,
    required this.startedAt,
    required this.ratePerHour,
  });

  @override
  State<LiveTimerCard> createState() => _LiveTimerCardState();
}

class _LiveTimerCardState extends State<LiveTimerCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final cost = elapsed.inSeconds / 3600 * widget.ratePerHour;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: FieldifyColors.g800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'In progress',
                    style: GoogleFonts.dmSans(fontSize: 11, color: FieldifyColors.g200),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _fmtDuration(elapsed),
                style: GoogleFonts.dmMono(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '€${widget.ratePerHour.toStringAsFixed(0)} / h',
                style: GoogleFonts.dmSans(fontSize: 11, color: FieldifyColors.g200),
              ),
              const SizedBox(height: 4),
              Text(
                '~€${cost.toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: FieldifyColors.g200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
