import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';

// ─── One Tent Design Tokens — same brand palette as every other screen ────
const _kBodyBg     = Color(0xFFFFFFFF);
const _kFieldFill  = Color(0xFFF3EEE7);
const _kBorder     = Color(0xFFDDD0C4);
const _kGold       = Color(0xFFD4891A);
const _kMaroon     = Color(0xFF4A1000);
const _kTextDark   = Color(0xFF2D0F05);
const _kTextMid    = Color(0xFF7A4A30);
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
  String? _errorMsg;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
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
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

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
    final errorMsg = _errorMsg;

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  const _LogoMark(),
                  const SizedBox(height: 28),

                  Text('Welcome Back',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _kTextDark, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Sign in to your One Tent account',
                      style: TextStyle(color: _kTextMid, fontSize: 14)),

                  const SizedBox(height: 36),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuthField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _AuthField(
                          controller: _passCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscure,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _kTextMid,
                              size: 20,
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Minimum 6 characters'
                              : null,
                        ),

                        if (errorMsg != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _kErrorColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: _kErrorColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(errorMsg,
                                    style: const TextStyle(
                                        color: _kErrorColor, fontSize: 13)),
                              ),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Forgot Password?',
                                style: TextStyle(
                                    color: _kGold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGold,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _kGold.withValues(alpha: 0.4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Sign In',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(children: [
                    const Expanded(child: Divider(color: _kBorder)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(color: _kTextMid, fontSize: 13)),
                    ),
                    const Expanded(child: Divider(color: _kBorder)),
                  ]),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text.rich(
                      TextSpan(
                        text: "Don't have an account?  ",
                        style: TextStyle(color: _kTextMid, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Register',
                            style: TextStyle(
                                color: _kGold,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
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
    );
  }
}

// ─── Logo ───────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 76, height: 76,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kFieldFill,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _kMaroon.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.cabin, color: _kGold, size: 34)),
        ),
      ),
      const SizedBox(height: 14),
      const Text.rich(
        TextSpan(
          text: 'One ',
          style: TextStyle(
              color: _kTextDark, fontSize: 19, fontWeight: FontWeight.w500),
          children: [
            TextSpan(
                text: 'Tent',
                style: TextStyle(color: _kGold, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ]);
  }
}

// ─── Themed text field ────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  const _AuthField({
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
      style: const TextStyle(color: _kTextDark, fontSize: 14),
      cursorColor: _kGold,
      validator: validator,
      decoration: InputDecoration(
        labelText:          label,
        labelStyle:         const TextStyle(color: _kTextMid, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _kGold, fontSize: 12),
        prefixIcon: Icon(icon, color: _kTextMid, size: 20),
        suffixIcon: suffixIcon,
        filled:    true,
        fillColor: _kFieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
