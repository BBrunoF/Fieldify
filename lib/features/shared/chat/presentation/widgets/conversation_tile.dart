import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/conversation_model.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = !conversation.isActive;
    final nameColor = inactive ? FieldifyColors.ink3 : FieldifyColors.ink;
    final previewColor = inactive ? FieldifyColors.ink4 : FieldifyColors.ink3;
    final avatarBg = inactive ? FieldifyColors.surface : FieldifyColors.g100;
    final avatarFg = inactive ? FieldifyColors.ink4 : FieldifyColors.g800;

    final preview = conversation.lastMessagePreview;
    final hasPreview = preview != null && preview.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conversation.counterpartyInitials,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: avatarFg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.counterpartyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nameColor,
                          ),
                        ),
                      ),
                      if (inactive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: FieldifyColors.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: FieldifyColors.border),
                          ),
                          child: Text(
                            'Archived',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: FieldifyColors.ink3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: inactive
                          ? FieldifyColors.ink4
                          : FieldifyColors.g700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPreview ? preview : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontStyle:
                          hasPreview ? FontStyle.normal : FontStyle.italic,
                      color: previewColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
