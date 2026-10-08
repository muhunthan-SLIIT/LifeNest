import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Onboarding screen.dart';

class _C {
  static const forest = Color(0xFF16402B);
  static const cream = Color(0xFFFAF8F3);
  static const field = Color(0xFFFFFFFF);
  static const segment = Color(0xFFF0EEE8);
  static const border = Color(0xFFE4E4E0);
  static const muted = Color(0xFF6E7F75);
  static const peach = Color(0xFFE9795A);
  static const leaf = Color(0xFF5E9B6F);
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController(text: 'alex@example.com');
  // Demo value so the masked dots show. Clear this in production.
  final _password = TextEditingController(text: 'password1234');

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () {
        /* TODO: open Terms */
      };
    _privacyTap = TapGestureRecognizer()
      ..onTap = () {
        /* TODO: open Privacy */
      };
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    final name = _firstName.text.trim().isNotEmpty
        ? _firstName.text.trim()
        : (_isSignIn ? 'Alex' : 'New User');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(userName: name),
      ),
    );
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    // Simulate auth network response
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    _navigateToOnboarding();
  }

  Future<void> _google() async {
    if (_loading) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    _navigateToOnboarding();
  }

  Future<void> _apple() async {
    if (_loading) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    _navigateToOnboarding();
  }

  Future<void> _faceId() async {
    if (_loading) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
    _navigateToOnboarding();
  }

  void _forgot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset instructions sent to your email.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    final gap = compact ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: _C.cream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const _TopBar(),
                        SizedBox(height: compact ? 20 : 28),
                        Text(
                          'Welcome to your nest.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -1,
                            color: _C.forest,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Capture today. A calmer tomorrow.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.caveat(
                            fontSize: 21,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: _C.muted,
                          ),
                        ),
                        SizedBox(height: gap + 4),
                        _ModeSwitch(
                          isSignIn: _isSignIn,
                          onChanged: (v) => setState(() {
                            if (_isSignIn && !v) {
                              _email.clear();
                              _password.clear();
                            }
                            _isSignIn = v;
                          }),
                        ),
                        SizedBox(height: gap),
                        _PillButton(
                          label: 'Continue with Google',
                          background: _C.forest,
                          foreground: Colors.white,
                          iconBackground: Colors.white,
                          icon: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(painter: _GoogleGPainter()),
                          ),
                          onPressed: _google,
                        ),
                        const SizedBox(height: 8),
                        _PillButton(
                          label: 'Continue with Apple',
                          background: _C.field,
                          foreground: _C.forest,
                          borderColor: _C.border,
                          icon: const Icon(
                            Icons.apple,
                            color: Colors.black,
                            size: 22,
                          ),
                          onPressed: _apple,
                        ),
                        SizedBox(height: gap),
                        const _OrDivider(),
                        SizedBox(height: gap),
                        if (!_isSignIn) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('FIRST NAME'),
                                    const SizedBox(height: 6),
                                    _InputField(
                                      controller: _firstName,
                                      hint: 'Alex',
                                      keyboardType: TextInputType.name,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.givenName,
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('LAST NAME'),
                                    const SizedBox(height: 6),
                                    _InputField(
                                      controller: _lastName,
                                      hint: 'Morgan',
                                      keyboardType: TextInputType.name,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.familyName,
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: gap),
                        ],
                        const _FieldLabel('EMAIL ADDRESS'),
                        const SizedBox(height: 6),
                        _InputField(
                          controller: _email,
                          hint: 'alex@example.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          suffix: const Icon(
                            Icons.mail_outline_rounded,
                            size: 20,
                            color: _C.muted,
                          ),
                        ),
                        SizedBox(height: gap),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _FieldLabel('PASSWORD'),
                            if (_isSignIn)
                              InkWell(
                                onTap: _forgot,
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Forgot?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _C.forest,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        _InputField(
                          controller: _password,
                          hint: _isSignIn
                              ? 'Your password'
                              : 'Create a password',
                          obscure: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: _C.muted,
                            ),
                          ),
                        ),
                        SizedBox(height: gap - 2),
                        if (_isSignIn)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () =>
                                    setState(() => _remember = !_remember),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _CheckBox(checked: _remember),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember me on this device',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          color: _C.forest,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _faceId,
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.face_unlock_outlined,
                                        size: 18,
                                        color: _C.forest,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Face ID',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: _C.forest,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: _isSignIn ? gap - 4 : gap),
                        _PillButton(
                          label: _isSignIn ? 'Sign In →' : 'Create Account →',
                          background: _C.forest,
                          foreground: Colors.white,
                          centered: true,
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const Spacer(),
                        SizedBox(height: gap),
                        _SecurityFooter(
                          termsTap: _termsTap,
                          privacyTap: _privacyTap,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: _C.field,
              shape: const CircleBorder(side: BorderSide(color: _C.border)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.maybePop(context),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: _C.forest,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CustomPaint(painter: _NestLogoPainter()),
              ),
              const SizedBox(width: 8),
              Text(
                'LifeNest',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: _C.forest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isSignIn, required this.onChanged});

  final bool isSignIn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _C.segment,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _segment('Sign In', isSignIn, () => onChanged(true)),
          _segment('Create Account', !isSignIn, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            border: selected ? Border.all(color: _C.border) : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? _C.forest : _C.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.icon,
    this.iconBackground,
    this.borderColor,
    this.centered = false,
    this.loading = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;
  final Widget? icon;
  final Color? iconBackground;
  final Color? borderColor;
  final bool centered;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: centered ? FontWeight.w700 : FontWeight.w600,
        color: foreground,
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: loading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: foreground,
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      if (icon != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: iconBackground,
                              shape: BoxShape.circle,
                            ),
                            child: icon,
                          ),
                        ),
                      text,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(height: 1, thickness: 1, color: _C.border),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR EMAIL',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: _C.muted,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: _C.muted,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    this.suffix,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final Widget? suffix;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        obscuringCharacter: '•',
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onSubmitted: onSubmitted,
        cursorColor: _C.forest,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _C.forest),
        decoration: InputDecoration(
          filled: true,
          fillColor: _C.field,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: _C.muted.withValues(alpha: 0.6),
          ),
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: suffix,
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          enabledBorder: _border(_C.border),
          focusedBorder: _border(_C.forest, 1.4),
          border: _border(_C.border),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? _C.forest : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: checked ? _C.forest : _C.muted, width: 1.3),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter({required this.termsTap, required this.privacyTap});

  final TapGestureRecognizer termsTap;
  final TapGestureRecognizer privacyTap;

  @override
  Widget build(BuildContext context) {
    final small = GoogleFonts.plusJakartaSans(fontSize: 11.5, color: _C.muted);
    final link = small.copyWith(
      color: _C.forest,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: _C.forest.withValues(alpha: 0.4),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 14, color: _C.forest),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'End-to-end encrypted. We never train on your data.',
                textAlign: TextAlign.center,
                style: small.copyWith(color: _C.forest),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: small,
            children: [
              const TextSpan(text: "By continuing, you agree to LifeNest's "),
              TextSpan(text: 'Terms', style: link, recognizer: termsTap),
              const TextSpan(text: ' & '),
              TextSpan(text: 'Privacy', style: link, recognizer: privacyTap),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
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
      Paint()..color = _C.peach,
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
      ..strokeWidth = stroke;

    canvas.drawArc(rect, _rad(-45), _rad(-105), false, p(_red));
    canvas.drawArc(rect, _rad(-150), _rad(-60), false, p(_yellow));
    canvas.drawArc(rect, _rad(-210), _rad(-110), false, p(_green));
    canvas.drawArc(rect, _rad(-320), _rad(-40), false, p(_blue));
    canvas.drawLine(c, Offset(c.dx + r + stroke / 2, c.dy), p(_blue));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
