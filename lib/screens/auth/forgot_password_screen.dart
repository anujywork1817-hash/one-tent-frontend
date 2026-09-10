import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kGold = Color(0xFFD4891A);
const Color _kBodyBg = Color(0xFFFFFFFF);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kFieldFill = Color(0xFFF3EEE7);
const Color _kTextDark = Color(0xFF2D0F05);
const Color _kTextMuted = Color(0xFF7A4A30);
const Color _kDivider = Color(0xFFDDD0C4);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kRed = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  bool _resetDone = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.forgotPassword(email);
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // A clickable email link has nowhere to land in a mobile app, so this
  // reads the 6-digit code back from the user instead — same pattern as
  // email verification.
  Future<void> _submitReset() async {
    final code = _codeCtrl.text.trim();
    final newPass = _newPassCtrl.text;
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (!newPass.contains(RegExp(r'[A-Z]'))) {
      setState(() => _error = 'Add at least one uppercase letter');
      return;
    }
    if (!newPass.contains(RegExp(r'[!-/:-@\[-`{-~]'))) {
      setState(() =>
          _error = 'Add at least one special character (e.g. !@#\$%)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(token: code, newPassword: newPass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      setState(() => _resetDone = true);
    } else {
      setState(() => _error = auth.error ?? 'Could not reset password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      body: Column(
        children: [
          _ForgotHeader(),

          // ── Scrollable cream body ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: _resetDone
                  ? _buildDone()
                  : _sent
                      ? _buildCodeForm()
                      : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lock icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: _kGold, size: 30),
        ),
        const SizedBox(height: 22),

        // Heading
        const Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email and we\'ll send you a code to reset your password.',
          style: TextStyle(fontSize: 14, color: _kTextMuted, height: 1.5),
        ),
        const SizedBox(height: 28),

        // Email field
        Container(
          decoration: BoxDecoration(
            color: _kFieldFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _kTextDark, fontSize: 14),
            decoration: InputDecoration(
              filled: false,
              labelText: 'Email Address',
              labelStyle: const TextStyle(color: _kTextMuted, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.email_outlined, color: _kTextMuted, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              floatingLabelStyle: const TextStyle(color: _kGold, fontSize: 12),
            ),
          ),
        ),

        // Error container
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: _kRed, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_error!,
                    style: const TextStyle(color: _kRed, fontSize: 13)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 28),

        // Submit button
        _KumbhButton(
          label: 'Send Reset Link',
          isLoading: _loading,
          onTap: _loading ? null : _submit,
        ),

        const SizedBox(height: 16),

        // Back to login
        Center(
          child: GestureDetector(
            onTap: () => context.go('/login'),
            child: const Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: 'Remembered it? ',
                    style: TextStyle(color: _kTextMuted, fontSize: 13)),
                TextSpan(
                  text: 'Back to Login',
                  style: TextStyle(
                    color: _kGold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: _kGold, size: 30),
        ),
        const SizedBox(height: 22),

        const Text(
          'Enter Reset Code',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: _kTextDark),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style:
                const TextStyle(fontSize: 14, color: _kTextMuted, height: 1.5),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _emailCtrl.text.trim(),
                style: const TextStyle(
                    color: _kTextDark, fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '. Enter it below with your new password.'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Code field
        Container(
          decoration: BoxDecoration(
            color: _kFieldFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
            decoration: const InputDecoration(
              filled: false,
              counterText: '',
              hintText: '••••••',
              hintStyle:
                  TextStyle(color: _kDivider, fontSize: 22, letterSpacing: 10),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // New password field
        Container(
          decoration: BoxDecoration(
            color: _kFieldFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _newPassCtrl,
            obscureText: true,
            style: const TextStyle(color: _kTextDark, fontSize: 14),
            decoration: InputDecoration(
              filled: false,
              labelText: 'New Password',
              labelStyle: const TextStyle(color: _kTextMuted, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.lock_outline, color: _kTextMuted, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              floatingLabelStyle: const TextStyle(color: _kGold, fontSize: 12),
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: _kRed, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_error!,
                    style: const TextStyle(color: _kRed, fontSize: 13)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 28),

        _KumbhButton(
          label: 'Reset Password',
          isLoading: _loading,
          onTap: _loading ? null : _submitReset,
        ),
        const SizedBox(height: 16),

        Center(
          child: GestureDetector(
            onTap: _loading ? null : _submit,
            child: const Text("Didn't get it? Resend code",
                style: TextStyle(
                    color: _kGold, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            
          ),
          child:
              const Icon(Icons.check_circle_outline, color: _kGreen, size: 46),
        ),
        const SizedBox(height: 24),
        const Text(
          'Password Updated',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _kTextDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Your password has been reset. You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: _kTextMuted, height: 1.5),
        ),
        const SizedBox(height: 32),
        _KumbhButton(
          label: 'Back to Login',
          isLoading: false,
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }
}

// ── Header — same plain white chrome as every other screen ─────────────────
class _ForgotHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: _kTextDark, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: _kTextDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Primary Button ────────────────────────────────────────────────────
class _KumbhButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  const _KumbhButton(
      {required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap == null ? _kGold.withValues(alpha: 0.4) : _kGold,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
