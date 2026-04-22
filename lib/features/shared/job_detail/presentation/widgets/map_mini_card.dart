import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class MapMiniCard extends StatelessWidget {
  final String? etaLabel;
  const MapMiniCard({super.key, this.etaLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: FieldifyColors.g100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 40, color: FieldifyColors.g500),
          if (etaLabel != null)
            Positioned(
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: FieldifyColors.g800,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  etaLabel!,
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.g100,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
