import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/supabase/supabase_client.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();

Future<void> main() async {
  await bootstrap();
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
