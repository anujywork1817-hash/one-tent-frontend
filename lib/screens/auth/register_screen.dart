import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../core/utils/countries_data.dart';
import '../../core/utils/passport_validator.dart';
import '../../providers/providers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _passportCtrl    = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _countryCtrl     = TextEditingController();
  final _passCtrl        = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _autovalidate = false;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  static const _bgDeep   = Color(0xFF0D0401);
  static const _surface  = Color(0xFF1C0906);
  static const _border   = Color(0xFF3D1A0D);
  static const _gold     = Color(0xFFD4891A);
  static const _cream    = Color(0xFFF5E6C8);
  static const _muted    = Color(0xFFA07850);
  static const _errorCol = Color(0xFFC0392B);

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
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passportCtrl.dispose(); _nationalityCtrl.dispose();
    _countryCtrl.dispose(); _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _autovalidate = true);
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      fullName:       _nameCtrl.text.trim(),
      email:          _emailCtrl.text.trim(),
      password:       _passCtrl.text,
      phone:          _phoneCtrl.text.trim(),
      nationality:    _nationalityCtrl.text.trim(),
      passportNumber: _passportCtrl.text.trim(),
      country:        _countryCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      final verified = auth.visitor?.emailVerified ?? false;
      context.go(verified ? '/home' : '/verify-email');
    } else {
      setState(() => _error = auth.error ?? 'Registration failed');
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _KumbhField(
        controller:   ctrl,
        label:        label,
        icon:         icon,
        keyboardType: keyboardType,
        obscureText:  obscureText,
        suffixIcon:   suffixIcon,
        validator:    validator ??
            (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: _gold,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: _border, thickness: 1)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: Stack(children: [
        // Background image
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4'
            '?w=1000&h=1800&fit=crop',
            fit: BoxFit.cover,
            color: const Color(0xCC0D0401),
            colorBlendMode: BlendMode.srcOver,
            errorBuilder: (_, __, ___) => Container(color: _bgDeep),
          ),
        ),

        // Radial glow
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          right: -80,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _gold.withValues(alpha: 0.10),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(children: [
                const SizedBox(height: 8),
                const _LogoMark(),
                const SizedBox(height: 20),

                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: _cream,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Register for your One Tent stay',
                  style: Theme.of(context)
                      .textTheme.bodyMedium?.copyWith(color: _muted),
                ),

                const SizedBox(height: 28),

                // Form card
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // Personal Info
                        _sectionLabel('Personal Information'),
                        _field(_nameCtrl, 'Full Name', Icons.person_outline),
                        _field(
                          _emailCtrl, 'Email Address',
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _KumbhPhoneField(controller: _phoneCtrl),
                        ),

                        // Travel Details
                        _sectionLabel('Travel Details'),
                        _field(
                          _countryCtrl, 'Country of Residence', Icons.public_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Country of Residence is required';
                            if (!CountriesData.isValidCountry(v)) return 'Please enter a valid country';
                            return null;
                          },
                        ),
                        _field(
                          _passportCtrl, 'Passport Number', Icons.badge_outlined,
                          validator: (v) => PassportValidator.validate(
                              _countryCtrl.text, v ?? ''),
                        ),
                        _field(
                          _nationalityCtrl, 'Nationality', Icons.flag_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Nationality is required';
                            if (!CountriesData.isValidNationality(v)) return 'Please enter a valid nationality';
                            return null;
                          },
                        ),

                        // Security
                        _sectionLabel('Security'),
                        _field(
                          _passCtrl,
                          'Password',
                          Icons.lock_outline,
                          obscureText: _obscure,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _gold, size: 20,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 8) return 'Password must be at least 8 characters';
                            if (!v.contains(RegExp(r'[A-Z]'))) {
                              return 'Add at least one uppercase letter';
                            }
                            if (!v.contains(RegExp(r'[!-/:-@\[-`{-~]'))) {
                              return 'Add at least one special character (e.g. !@#\$%)';
                            }
                            return null;
                          },
                        ),

                        // Error
                        if (_error != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _errorCol.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _errorCol.withValues(alpha: 0.35)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: _errorCol, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: _errorCol, fontSize: 13)),
                              ),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 24),

                        _RegisterButton(loading: _loading, onPressed: _register),

                        const SizedBox(height: 16),

                        Text(
                          'By registering you agree to our Terms of Service\n'
                          'and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _muted.withValues(alpha: 0.7),
                              fontSize: 11,
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already have an account?  ',
                      style: TextStyle(color: _muted, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Logo Mark ─────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  static const _gold    = Color(0xFFD4891A);
  static const _cream   = Color(0xFFF5E6C8);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 68, height: 68,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover),
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('One ',
            style: TextStyle(
                color: _cream, fontSize: 17,
                fontWeight: FontWeight.w400, letterSpacing: 0.4)),
        Text('Tent',
            style: TextStyle(
                color: _gold, fontSize: 17,
                fontWeight: FontWeight.w600, letterSpacing: 0.4)),
      ]),
    ]);
  }
}

// ── Themed text field ─────────────────────────────────────
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

  final TextEditingController      controller;
  final String                     label;
  final IconData                   icon;
  final TextInputType?             keyboardType;
  final bool                       obscureText;
  final Widget?                    suffixIcon;
  final String? Function(String?)? validator;

  static const _gold   = Color(0xFFD4891A);
  static const _cream  = Color(0xFFF5E6C8);
  static const _muted  = Color(0xFFA07850);
  static const _bgDeep = Color(0xFF0D0401);
  static const _border = Color(0xFF3D1A0D);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      obscureText:  obscureText,
      style: const TextStyle(color: _cream, fontSize: 14),
      cursorColor: _gold,
      validator: validator,
      decoration: InputDecoration(
        labelText:          label,
        labelStyle:         const TextStyle(color: _muted, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _gold, fontSize: 12),
        prefixIcon:  Icon(icon, color: _muted, size: 20),
        suffixIcon:  suffixIcon,
        filled:      true,
        fillColor:   _bgDeep.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFC0392B), fontSize: 11),
      ),
    );
  }
}

// ── Phone field with world country-code picker ─────────────
class _KumbhPhoneField extends StatelessWidget {
  const _KumbhPhoneField({required this.controller});

  final TextEditingController controller;

  static const _gold   = Color(0xFFD4891A);
  static const _cream  = Color(0xFFF5E6C8);
  static const _muted  = Color(0xFFA07850);
  static const _bgDeep = Color(0xFF0D0401);
  static const _border = Color(0xFF3D1A0D);

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      style: const TextStyle(color: _cream, fontSize: 14),
      cursorColor: _gold,
      dropdownTextStyle: const TextStyle(color: _cream, fontSize: 14),
      dropdownIconPosition: IconPosition.trailing,
      dropdownIcon: const Icon(Icons.arrow_drop_down, color: _muted),
      initialCountryCode: 'IN',
      disableLengthCheck: true,
      flagsButtonPadding: const EdgeInsets.only(left: 12),
      decoration: InputDecoration(
        labelText:          'Phone Number',
        labelStyle:         const TextStyle(color: _muted, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _gold, fontSize: 12),
        filled:      true,
        fillColor:   _bgDeep.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFC0392B), fontSize: 11),
      ),
      dropdownDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _bgDeep,
      ),
      onChanged: (phone) => controller.text = phone.completeNumber,
      validator: (phone) {
        if (phone == null || phone.number.trim().isEmpty) {
          return 'Phone number is required';
        }
        if (phone.number.trim().length < 6) return 'Enter a valid phone number';
        return null;
      },
    );
  }
}

// ── Register button ───────────────────────────────────────
class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.loading, required this.onPressed});

  final bool          loading;
  final VoidCallback  onPressed;

  static const _maroon = Color(0xFF7A1F0A);
  static const _gold   = Color(0xFFD4891A);
  static const _cream  = Color(0xFFF5E6C8);

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
            side: BorderSide(color: _gold.withValues(alpha: 0.5), width: 1),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: _cream, strokeWidth: 2))
            : const Text(
                'Create Account',
                style: TextStyle(
                  color: _cream,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }
}