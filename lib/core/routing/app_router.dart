// SPLIT FROM: lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../notifications/notification_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _permissionRequested = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data!.session;
        if (session != null && !_permissionRequested) {
          _permissionRequested = true;
          NotificationService.instance
              .requestNotificationPermission()
              .catchError((_) => false);
        }
        if (session == null) _permissionRequested = false;
        return session != null
            ? HomeScreen(
                onLogout: () => Supabase.instance.client.auth.signOut(),
              )
            : const LoginScreen();
      },
    );
  }
}
