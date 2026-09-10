import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kMaroon = Color(0xFF4A1000);
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

/// Shown right after registration (and reachable again from the profile
/// screen) until the guest confirms the 6-digit code emailed to them.
/// Booking is blocked server-side until this happens — this screen is what
/// actually gets them unblocked.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(code);

    if (!mounted) return;
    setState(() => _verifying = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! You can now book a stay.'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/home');
    } else {
      setState(() => _error = auth.error ?? 'Invalid code, please try again');
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerification();

    if (!mounted) return;
    setState(() => _resending = false);

    if (ok) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new code has been sent to your email'),
          backgroundColor: _kMaroon,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _error = auth.error ?? 'Could not resend the code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().visitor?.email ?? '';

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: Column(
        children: [
          _VerifyHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined,
                        color: _kGold, size: 30),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: _kTextMuted, height: 1.5),
                      children: [
                        const TextSpan(text: 'We sent a 6-digit code to '),
                        TextSpan(
                          text: email,
                          style: const TextStyle(
                              color: _kTextDark, fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(
                            text: '. Enter it below to unlock booking.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        color: _kTextDark,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                      ),
                      decoration: const InputDecoration(
                        // Same fix as forgot_password_screen: the global
                        // theme's filled:true paints a near-black fill that
                        // would make this dark text unreadable.
                        filled: false,
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: TextStyle(
                            color: _kDivider, fontSize: 26, letterSpacing: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 20),
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
                              style:
                                  const TextStyle(color: _kRed, fontSize: 13)),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _KumbhButton(
                    label: 'Verify Email',
                    isLoading: _verifying,
                    onTap: _verifying ? null : _verify,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: (_resending || _cooldown > 0) ? null : _resend,
                      child: _resending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: _kGold, strokeWidth: 2),
                            )
                          : Text(
                              _cooldown > 0
                                  ? 'Resend code in ${_cooldown}s'
                                  : "Didn't get it? Resend code",
                              style: TextStyle(
                                color: _cooldown > 0 ? _kTextMuted : _kGold,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
    );
  }
}

// ── Header — same plain white chrome as every other screen ─────────────────
class _VerifyHeader extends StatelessWidget {
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
              // Reached via context.go() right after registration (nothing
              // to pop to) as well as pushed from Profile (something to pop
              // to) — only show a back arrow when it would actually do
              // something.
              if (Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: _kTextDark, size: 28),
                  // Direct pop (not maybePop) so it returns one level to
                  // wherever this was pushed from, rather than being caught
                  // by the app-wide back-to-Home handler.
                  onPressed: () => Navigator.of(context).pop(),
                )
              else
                const SizedBox(width: 12),
              const Text(
                'Email Verification',
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
