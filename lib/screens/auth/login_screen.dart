import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';

// ─────────────────────────────────────────────
//  One Tent — Design Tokens
// ─────────────────────────────────────────────
//  Primary bg   : #0D0401  (near-black maroon)
//  Surface      : #1C0906
//  Border       : #3D1A0D
//  Gold         : #D4891A
//  Gold light   : #E8A93A
//  Cream        : #F5E6C8
//  Muted        : #A07850
//  Error color  : #C0392B  (use _kErrorColor, not _error)
// ─────────────────────────────────────────────

// Top-level color constants — no naming conflict with instance fields
const _kBgDeep     = Color(0xFF0D0401);
const _kSurface    = Color(0xFF1C0906);
const _kBorder     = Color(0xFF3D1A0D);
const _kGold       = Color(0xFFD4891A);
const _kGoldLight  = Color(0xFFE8A93A);
const _kCream      = Color(0xFFF5E6C8);
const _kMuted      = Color(0xFFA07850);
const _kErrorColor = Color(0xFFC0392B);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool    _obscure = true;
  bool    _loading = false;
  String? _errorMsg; // renamed from _error to avoid any static conflict

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() { _loading = true; _errorMsg = null; });

  final auth = context.read<AuthProvider>();
  final success = await auth.login(
    _emailCtrl.text.trim(),
    _passCtrl.text,
  );

  if (!mounted) return;

  if (success) {
    context.go('/home');
  } else {
    setState(() {
      _errorMsg = auth.error ?? 'Invalid email or password';
      _loading  = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    // Capture nullable to a local final so Dart can promote it inside if-blocks
    final errorMsg = _errorMsg;

    return Scaffold(
      backgroundColor: _kBgDeep,
      body: Stack(
        children: [
          // ── Background image with deep maroon overlay ──
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4'
              '?w=1000&h=1800&fit=crop',
              fit: BoxFit.cover,
              color: const Color(0xCC0D0401),
              colorBlendMode: BlendMode.srcOver,
              errorBuilder: (_, __, ___) => Container(color: _kBgDeep),
            ),
          ),

          // ── Radial gold glow ──
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _kGold.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),

                      const _LogoMark(),

                      const SizedBox(height: 28),

                      Text(
                        'Welcome Back',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                          color: _kCream,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your One Tent account',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: _kMuted),
                      ),

                      const SizedBox(height: 40),

                      // ── Form card ──
                      Container(
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _kBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _KumbhField(
                                controller: _emailCtrl,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                    v == null || !v.contains('@')
                                        ? 'Enter a valid email'
                                        : null,
                              ),

                              const SizedBox(height: 18),

                              _KumbhField(
                                controller: _passCtrl,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscure,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _kGold,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.length < 6
                                        ? 'Minimum 6 characters'
                                        : null,
                              ),

                              // ── Error message ──
                              if (errorMsg != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _kErrorColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _kErrorColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: _kErrorColor, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          errorMsg,
                                          style: const TextStyle(
                                            color: _kErrorColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),

                              // ── Forgot password ──
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: _kGoldLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              _SignInButton(
                                  loading: _loading, onPressed: _login),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Divider ──
                      Row(children: [
                        const Expanded(
                            child: Divider(color: _kBorder, thickness: 1)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(
                                  color: _kMuted, fontSize: 13)),
                        ),
                        const Expanded(
                            child: Divider(color: _kBorder, thickness: 1)),
                      ]),

                      const SizedBox(height: 28),

                      // ── Register link ──
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: const Text.rich(
                          TextSpan(
                            text: "Don't have an account?  ",
                            style: TextStyle(color: _kMuted, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  color: _kGold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Logo Mark
// ─────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 72, height: 72,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _kCream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _kGold.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kGold.withValues(alpha: 0.18),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover),
        ),
      ),
      const SizedBox(height: 14),
      const Text.rich(
        TextSpan(
          text: 'One ',
          style: TextStyle(
              color: _kCream,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5),
          children: [
            TextSpan(
              text: 'Tent',
              style: TextStyle(
                  color: _kGold,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
//  Themed text field
// ─────────────────────────────────────────────
class _KumbhField extends StatelessWidget {
  const _KumbhField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      obscureText:  obscureText,
      style: const TextStyle(color: _kCream, fontSize: 14),
      cursorColor: _kGold,
      validator: validator,
      decoration: InputDecoration(
        labelText:          label,
        labelStyle:         const TextStyle(color: _kMuted, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _kGold, fontSize: 12),
        prefixIcon: Icon(icon, color: _kMuted, size: 20),
        suffixIcon: suffixIcon,
        filled:    true,
        fillColor: _kBgDeep.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kErrorColor, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _kErrorColor, fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sign In button
// ─────────────────────────────────────────────
class _SignInButton extends StatelessWidget {
  const _SignInButton(
      {required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  static const _maroon = Color(0xFF7A1F0A);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _maroon,
          disabledBackgroundColor: _maroon.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(
                color: _kGold.withValues(alpha: 0.5)),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: _kCream, strokeWidth: 2),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  color: _kCream,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }
}