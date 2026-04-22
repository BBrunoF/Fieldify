import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';

class NotifButton extends StatelessWidget {
  const NotifButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(51), width: 1.5),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            size: 16,
            color: FieldifyColors.g100,
          ),
        ),
        Positioned(
          top: -1,
          right: -1,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: FieldifyColors.g200,
              shape: BoxShape.circle,
              border: Border.all(color: FieldifyColors.g800, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class LogoutButton extends StatelessWidget {
  final Future<void> Function()? onLogout;

  const LogoutButton({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (onLogout != null) {
            await onLogout!();
            return;
          }
          await supabase.auth.signOut();
        },
        key: const Key('homeLogoutButton'),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(51), width: 1.5),
          ),
          child: const Icon(
            Icons.logout_rounded,
            size: 16,
            color: FieldifyColors.g100,
          ),
        ),
      ),
    );
  }
}
