import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ── Shared widgets ────────────────────────────────────────────────────────────

class FieldifyLogo extends StatelessWidget {
  const FieldifyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: FieldifyColors.g100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(20, 20),
              painter: FieldifyMarkPainter(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Fieldify',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class AuthBrandBlock extends StatelessWidget {
  final String headline;
  final String subtitle;

  const AuthBrandBlock({
    super.key,
    required this.headline,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FieldifyColors.g800,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldifyLogo(),
          const SizedBox(height: 32),
          Text(
            headline,
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.78,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: FieldifyColors.g200,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFormShell extends StatelessWidget {
  final Widget child;
  const AuthFormShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: FieldifyColors.g800, height: 24),
        Container(
          decoration: const BoxDecoration(
            color: FieldifyColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: child,
          ),
        ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: FieldifyColors.ink3,
        letterSpacing: 0.44,
      ),
    );
  }
}

InputDecoration authInputDecoration({required String hint, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink4),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: FieldifyColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: FieldifyColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: FieldifyColors.g500, width: 1.5),
    ),
    suffixIcon: suffix,
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Key? buttonKey; // NOVO

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.buttonKey, // NOVO
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: FieldifyColors.g800,
        foregroundColor: FieldifyColors.g100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: FieldifyColors.g100,
        ),
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: FieldifyColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CustomPaint(painter: GoogleLogoPainter()),
          ),
          const SizedBox(width: 10),
          Text(
            'Continue with Google',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: FieldifyColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.ink4),
          ),
        ),
        const Expanded(
            child: Divider(color: FieldifyColors.border, thickness: 1)),
      ],
    );
  }
}

// ── Custom painters ───────────────────────────────────────────────────────────

class FieldifyMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = FieldifyColors.g800
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(3, 16)
        ..lineTo(10, 4)
        ..lineTo(17, 16),
      p,
    );
    canvas.drawLine(const Offset(6, 11.5), const Offset(14, 11.5), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 18;
    canvas.save();
    canvas.scale(s, s);

    void fill(Color c, Path path) =>
        canvas.drawPath(path, Paint()..color = c..style = PaintingStyle.fill);

    fill(
      const Color(0xFF4285F4),
      Path()
        ..moveTo(16.5, 9.2)
        ..cubicTo(16.5, 8.6, 16.4, 8.1, 16.3, 7.5)
        ..lineTo(9, 7.5)
        ..lineTo(9, 10.7)
        ..lineTo(13.2, 10.7)
        ..cubicTo(12.83, 11.57, 12.18, 12.27, 11.34, 12.72)
        ..lineTo(13.94, 15.32)
        ..cubicTo(15.44, 13.92, 16.5, 11.72, 16.5, 9.2)
        ..close(),
    );
    fill(
      const Color(0xFF34A853),
      Path()
        ..moveTo(9, 17)
        ..cubicTo(11.1, 17, 12.9, 16.3, 14.14, 15.1)
        ..lineTo(11.54, 12.5)
        ..cubicTo(10.84, 13.0, 9.94, 13.3, 9, 13.3)
        ..cubicTo(7.0, 13.3, 5.3, 12.0, 4.7, 10.1)
        ..lineTo(2, 12.2)
        ..cubicTo(3.26, 14.96, 5.9, 17, 9, 17)
        ..close(),
    );
    fill(
      const Color(0xFFFBBC05),
      Path()
        ..moveTo(4.7, 10.7)
        ..cubicTo(4.54, 10.16, 4.44, 9.59, 4.44, 9.0)
        ..cubicTo(4.44, 8.41, 4.54, 7.84, 4.7, 7.3)
        ..lineTo(2, 5.2)
        ..cubicTo(1.36, 6.5, 1, 7.92, 1, 9.0)
        ..cubicTo(1, 10.08, 1.36, 11.5, 2, 12.8)
        ..close(),
    );
    fill(
      const Color(0xFFEA4335),
      Path()
        ..moveTo(9, 3.8)
        ..cubicTo(10.1, 3.8, 11.1, 4.2, 11.9, 4.9)
        ..lineTo(14.1, 2.7)
        ..cubicTo(12.5, 1.26, 10.86, 1, 9, 1)
        ..cubicTo(5.9, 1, 3.26, 3.04, 2, 5.8)
        ..lineTo(4.7, 7.9)
        ..cubicTo(5.3, 6.0, 7.0, 3.8, 9, 3.8)
        ..close(),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
