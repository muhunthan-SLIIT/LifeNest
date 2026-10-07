// LifeNest Welcome Screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_screen.dart';

void main() => runApp(const LifeNestApp());

class AppColors {
  static const forest = Color(0xFF16402B);
  static const cream = Color(0xFFFAF8F3);
  static const sage = Color(0xFFDDE9E0);
  static const peach = Color(0xFFFCE4DC);
  static const accentPeach = Color(0xFFE9795A);
  static const accentGreen = Color(0xFF5E9B6F);
  static const mutedText = Color(0xFF6E7F75);
  static const border = Color(0xFFE4E4E0);
}

class LifeNestApp extends StatelessWidget {
  const LifeNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeNest',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.cream,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const WelcomeScreen(),
    );
  }
}

// Alias for test compatibility
typedef MyApp = LifeNestApp;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateToAuth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Sage shape, upper right
          Positioned(
            top: -w * 0.35,
            right: -w * 0.45,
            child: Container(
              width: w * 1.15,
              height: w * 1.15,
              decoration: const BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Peach shape, left, behind the headline
          Positioned(
            top: size.height * 0.2,
            left: -w * 0.45,
            child: Container(
              width: w * 0.95,
              height: w * 0.95,
              decoration: const BoxDecoration(
                color: AppColors.peach,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            const _BrandHeader(),
                            const Spacer(flex: 3),
                            Text(
                              'Your life ,\nin one place.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 46,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: -1.5,
                                color: AppColors.forest,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Capture today. A calmer\ntomorrow.',
                              style: GoogleFonts.caveat(
                                fontSize: 24,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 36),
                            _AuthButton(
                              label: 'Continue with Google',
                              icon: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CustomPaint(painter: _GoogleGPainter()),
                              ),
                              background: AppColors.forest,
                              foreground: Colors.white,
                              onPressed: () { _navigateToAuth(context); },
                              iconBackground: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            _AuthButton(
                              label: 'Continue with Apple',
                              icon: const Icon(
                                Icons.apple,
                                color: Colors.black,
                                size: 24,
                              ),
                              background: const Color(0xFFFEFEFC),
                              foreground: AppColors.forest,
                              borderColor: AppColors.border,
                              onPressed: () { _navigateToAuth(context); },
                            ),
                            const SizedBox(height: 24),
                            const _PrivacyNote(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 34,
          height: 34,
          child: CustomPaint(painter: _NestLogoPainter()),
        ),
        const SizedBox(width: 14),
        Text(
          'LifeNest',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.forest,
          ),
        ),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.borderColor,
    this.iconBackground,
  });

  final String label;
  final Widget icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final Color? iconBackground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: borderColor != null
              ? BorderSide(color: borderColor!, width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: icon,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 16,
          color: AppColors.forest,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'We only access the files you choose.\nYour data stays private.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.mutedText,
            ),
          ),
        ),
      ],
    );
  }
}

/// Nest logo: forest-green arc, peach dot, tiny green dot.
class _NestLogoPainter extends CustomPainter {
  const _NestLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    final arc = Paint()
      ..color = AppColors.forest
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.5, s * 0.52), radius: s * 0.34),
      0.25,
      2.65,
      false,
      arc,
    );

    canvas.drawCircle(
      Offset(s * 0.5, s * 0.22),
      s * 0.11,
      Paint()..color = AppColors.accentPeach,
    );
    canvas.drawCircle(
      Offset(s * 0.2, s * 0.4),
      s * 0.05,
      Paint()..color = AppColors.accentGreen,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Multicolor Google "G".
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  double _rad(double deg) => deg * 3.1415926535 / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final r = s * 0.38;
    final c = Offset(s / 2, s / 2);
    final rect = Rect.fromCircle(center: c, radius: r);

    Paint p(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, _rad(-45), _rad(-105), false, p(_red));
    canvas.drawArc(rect, _rad(-150), _rad(-60), false, p(_yellow));
    canvas.drawArc(rect, _rad(-210), _rad(-110), false, p(_green));
    canvas.drawArc(rect, _rad(-320), _rad(-40), false, p(_blue));

    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r + stroke / 2, c.dy),
      p(_blue),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
