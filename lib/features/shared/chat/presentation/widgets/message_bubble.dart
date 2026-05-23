import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: isMine ? FieldifyColors.g800 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: FieldifyColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isMine ? Colors.white : FieldifyColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _time(message.createdAt),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: isMine
                    ? FieldifyColors.g200
                    : FieldifyColors.ink4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
