import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

void main() {
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
      home: const LoginScreen(),
    );
  }
}