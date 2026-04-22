import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import 'photo_viewer.dart';

class PhotoGallery extends StatelessWidget {
  final List<String> urls;
  const PhotoGallery({super.key, required this.urls});

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewer(urls: urls, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHOTOS',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.ink3,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openViewer(context, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    urls[i],
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 92,
                      height: 92,
                      color: FieldifyColors.surface,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: FieldifyColors.ink4,
                      ),
                    ),
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : Container(
                            width: 92,
                            height: 92,
                            color: FieldifyColors.surface,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
