// ignore_for_file: file_names
// LifeNest onboarding (4 screens) + completion storage.
// Save as lib/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Home.dart';

class _C {
  static const forest = Color(0xFF16402B);
  static const cream = Color(0xFFFAF8F3);
  static const mint = Color(0xFFDDEEE3);
  static const skyBlue = Color(0xFFDCE9F7);
  static const skyIcon = Color(0xFF3C4F66);
  static const peach = Color(0xFFFCE4DC);
  static const peachAccent = Color(0xFFE9795A);
  static const leaf = Color(0xFF5E9B6F);
  static const muted = Color(0xFF6E7F75);
  static const script = Color(0xFF35503F);
  static const inactive = Color(0xFFE3E2DC);
}

// ---------------------------------------------------------------------------
// Storage + routing
// ---------------------------------------------------------------------------

class OnboardingStore {
  static const _key = 'onboardingCompleted';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

// ---------------------------------------------------------------------------
// Onboarding flow
// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.onFinish,
    this.userName = 'Alex',
  });

  /// Called after Skip or "Let's get started" (completion already saved).
  final VoidCallback? onFinish;
  final String userName;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 4;

  final _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  bool get _isLast => _index == _pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await OnboardingStore.complete();
    if (!mounted) return;
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userName: widget.userName),
        ),
      );
    }
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: small logo (screens 2-4) + Skip (all screens)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _index == 0 ? 0 : 1,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CustomPaint(painter: _NestLogoPainter()),
                      ),
                    ),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(56, 44),
                        foregroundColor: _C.muted,
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _C.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _IntroPage(),
                  _KeepPage(),
                  _FindPage(),
                  _YourWayPage(),
                ],
              ),
            ),
            _ProgressDots(count: _pageCount, active: _index),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.forest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _isLast ? "Let's get started" : 'Continue',
                      key: ValueKey(_isLast),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? _C.forest : _C.inactive,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Lets a page scroll on very small screens while keeping its content
/// vertically placed on larger ones.
class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.builder});

  final Widget Function(BuildContext context, double height) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: builder(context, constraints.maxHeight),
            ),
          ),
        );
      },
    );
  }
}

TextStyle _heading(double size) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: FontWeight.w800,
  height: 1.1,
  letterSpacing: -1,
  color: _C.forest,
);

// ---------------------------------------------------------------------------
// Screen 1: Introduction
// ---------------------------------------------------------------------------

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      builder: (context, h) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: h),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CustomPaint(painter: _NestLogoPainter()),
                ),
                const SizedBox(width: 12),
                Text(
                  'LifeNest',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: _C.forest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Capture today.\nA calmer tomorrow.',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 36,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: _C.script,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

// ---------------------------------------------------------------------------
// Screen 2: Keep what matters
// ---------------------------------------------------------------------------

class _KeepPage extends StatelessWidget {
  const _KeepPage();

  static const _items = <(IconData, String)>[
    (Icons.photo_camera_outlined, 'Photos'),
    (Icons.description_outlined, 'Documents'),
    (Icons.link_rounded, 'Links'),
    (Icons.menu_book_outlined, 'Notes'),
    (Icons.location_on_outlined, 'Places'),
    (Icons.lightbulb_outline_rounded, 'Ideas'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      builder: (context, h) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Keep what matters.', style: _heading(32)),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 1.35,
            children: [
              for (final item in _items) _CategoryTile(item.$1, item.$2),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _C.mint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 28, color: _C.forest),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.forest,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 3: Find it when you need it
// ---------------------------------------------------------------------------

class _FindPage extends StatelessWidget {
  const _FindPage();

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      builder: (context, h) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h * 0.1),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: _C.skyBlue,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 40,
              color: _C.skyIcon,
            ),
          ),
          const SizedBox(height: 32),
          Text('Find it when\nyou need it.', style: _heading(36)),
          const SizedBox(height: 16),
          Text(
            'Categories, collections and reminders\nkeep everything within a tap or two.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.5,
              color: _C.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 4: Your life, your way
// ---------------------------------------------------------------------------

class _YourWayPage extends StatelessWidget {
  const _YourWayPage();

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      builder: (context, h) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h * 0.1),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: _C.peach,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(48),
                topRight: Radius.circular(48),
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 36,
              color: _C.peachAccent,
            ),
          ),
          const SizedBox(height: 32),
          Text('Your life, your way.', style: _heading(34)),
          const SizedBox(height: 12),
          Text(
            "Give it to LifeNest, so you don't have\nto keep thinking about it.",
            style: GoogleFonts.caveat(
              fontSize: 23,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: _C.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo painter
// ---------------------------------------------------------------------------

class _NestLogoPainter extends CustomPainter {
  const _NestLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.5, s * 0.52), radius: s * 0.34),
      0.25,
      2.65,
      false,
      Paint()
        ..color = _C.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.22),
      s * 0.11,
      Paint()..color = _C.peachAccent,
    );
    canvas.drawCircle(
      Offset(s * 0.2, s * 0.4),
      s * 0.05,
      Paint()..color = _C.leaf,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
