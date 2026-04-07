import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_shared.dart';
import 'register_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signIn(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );
      // AuthGate handles navigation via stream
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: FieldifyColors.g800,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: FieldifyColors.g800,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandBlock(
                headline: 'Welcome\nback.',
                subtitle: 'Sign in to your account',
              ),
              Expanded(
                child: AuthFormShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Email ─────────────────────────────────────────────
                      const FieldLabel('Email'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration: authInputDecoration(hint: 'you@email.com'),
                      ),
                      const SizedBox(height: 14),

                      // ── Password ──────────────────────────────────────────
                      const FieldLabel('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pwCtrl,
                        obscureText: _obscure,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration: authInputDecoration(
                          hint: '••••••••',
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: _obscure
                                  ? FieldifyColors.ink3
                                  : FieldifyColors.g700,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),

                      // ── Forgot password ───────────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: FieldifyColors.g700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ── Error message ─────────────────────────────────────
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: const Color(0xFFC0392B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],

                      // ── Sign in button ────────────────────────────────────
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : PrimaryButton(
                              label: 'Sign in',
                              onPressed: _signIn,
                            ),
                      const SizedBox(height: 18),

                      // ── OR divider ────────────────────────────────────────
                      const OrDivider(),
                      const SizedBox(height: 18),

                      // ── Google button ─────────────────────────────────────
                      GoogleButton(onPressed: () {}),
                      const SizedBox(height: 20),

                      // ── Footer ────────────────────────────────────────────
                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: FieldifyColors.ink3),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign up',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: FieldifyColors.g700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}