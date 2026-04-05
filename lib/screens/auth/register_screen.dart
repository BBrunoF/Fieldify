import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_shared.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscure = true;

  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
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
                headline: 'Create your\naccount.',
                subtitle: 'Free to join, no commitments',
              ),
              Expanded(
                child: AuthFormShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── First + Last name (lado a lado) ─────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FieldLabel('First name'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _firstCtrl,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      color: FieldifyColors.ink),
                                  decoration:
                                      authInputDecoration(hint: 'Bruno'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FieldLabel('Last name'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _lastCtrl,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      color: FieldifyColors.ink),
                                  decoration:
                                      authInputDecoration(hint: 'Silva'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Email ────────────────────────────────────────────
                      const FieldLabel('Email'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration:
                            authInputDecoration(hint: 'you@email.com'),
                      ),
                      const SizedBox(height: 14),

                      // ── Phone ────────────────────────────────────────────
                      const FieldLabel('Phone'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration: authInputDecoration(
                            hint: '+351 912 345 678'),
                      ),
                      const SizedBox(height: 14),

                      // ── Password ─────────────────────────────────────────
                      const FieldLabel('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pwCtrl,
                        obscureText: _obscure,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration: authInputDecoration(
                          hint: 'Min. 8 characters',
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
                      const SizedBox(height: 20),

                      // ── Create account button ─────────────────────────────
                      PrimaryButton(
                          label: 'Create account', onPressed: () {}),
                      const SizedBox(height: 18),

                      // ── OR divider ────────────────────────────────────────
                      const OrDivider(),
                      const SizedBox(height: 18),

                      // ── Google button ─────────────────────────────────────
                      GoogleButton(onPressed: () {}),
                      const SizedBox(height: 14),

                      // ── Terms ─────────────────────────────────────────────
                      Text(
                        'By creating an account you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: FieldifyColors.ink4,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Footer ────────────────────────────────────────────
                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: FieldifyColors.ink3),
                            children: [
                              const TextSpan(
                                  text: 'Already have an account? '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: () =>
                                      Navigator.of(context).pop(),
                                  child: Text(
                                    'Sign in',
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
