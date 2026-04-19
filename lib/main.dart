import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();

  runApp(const FieldifyApp());
}

class FieldifyApp extends StatelessWidget {
  const FieldifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fieldify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF27500A)),
        splashFactory: NoSplash.splashFactory,
      ),
      home: const AuthGate(),
    );
  }
}
