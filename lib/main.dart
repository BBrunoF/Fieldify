import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jdmnvmqkmthjllckzlmp.supabase.co',
    anonKey: 'sb_publishable_GbzZ4mVffFIIYoKW0vjqDQ_eNoI5Ixo',
  );

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
