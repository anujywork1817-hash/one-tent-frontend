import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../core/utils/countries_data.dart';
import '../../core/utils/passport_validator.dart';
import '../../providers/providers.dart';

// ─── One Tent Design Tokens — same brand palette as every other screen ────
const _kBodyBg     = Color(0xFFFFFFFF);
const _kFieldFill  = Color(0xFFF3EEE7);
const _kBorder     = Color(0xFFDDD0C4);
const _kGold       = Color(0xFFD4891A);
const _kMaroon     = Color(0xFF4A1000);
const _kTextDark   = Color(0xFF2D0F05);
const _kTextMid    = Color(0xFF7A4A30);
const _kErrorCol   = Color(0xFFC0392B);

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
      child: _AuthField(
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
            color: _kGold,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: _kBorder, thickness: 1)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      appBar: AppBar(
        backgroundColor: _kBodyBg,
        surfaceTintColor: _kBodyBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _kTextDark, size: 28),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(children: [
              const _LogoMark(),
              const SizedBox(height: 20),

              Text('Create Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _kTextDark, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Register for your One Tent stay',
                  style: TextStyle(color: _kTextMid, fontSize: 14)),

              const SizedBox(height: 28),

              Form(
                key: _formKey,
                autovalidateMode: _autovalidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      child: _AuthPhoneField(controller: _phoneCtrl),
                    ),

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
                          color: _kTextMid, size: 20,
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

                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _kErrorCol.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              color: _kErrorCol, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: _kErrorCol, fontSize: 13)),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
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
                            : const Text('Create Account',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'By registering you agree to our Terms of Service\n'
                      'and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _kTextMid.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.6),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text.rich(
                  TextSpan(
                    text: 'Already have an account?  ',
                    style: TextStyle(color: _kTextMid, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                            color: _kGold,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
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
        width: 64, height: 64,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kFieldFill,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _kMaroon.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.cabin, color: _kGold, size: 28)),
        ),
      ),
      const SizedBox(height: 12),
      const Text.rich(
        TextSpan(
          text: 'One ',
          style: TextStyle(
              color: _kTextDark, fontSize: 17, fontWeight: FontWeight.w500),
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

  final TextEditingController      controller;
  final String                     label;
  final IconData                   icon;
  final TextInputType?             keyboardType;
  final bool                       obscureText;
  final Widget?                    suffixIcon;
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
        prefixIcon:  Icon(icon, color: _kTextMid, size: 20),
        suffixIcon:  suffixIcon,
        filled:      true,
        fillColor:   _kFieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: const BorderSide(color: _kErrorCol),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kErrorCol, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _kErrorCol, fontSize: 11),
      ),
    );
  }
}

// ─── Phone field with world country-code picker ────────────────────────────
class _AuthPhoneField extends StatelessWidget {
  const _AuthPhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      style: const TextStyle(color: _kTextDark, fontSize: 14),
      cursorColor: _kGold,
      dropdownTextStyle: const TextStyle(color: _kTextDark, fontSize: 14),
      dropdownIconPosition: IconPosition.trailing,
      dropdownIcon: const Icon(Icons.arrow_drop_down, color: _kTextMid),
      initialCountryCode: 'IN',
      disableLengthCheck: true,
      flagsButtonPadding: const EdgeInsets.only(left: 12),
      decoration: InputDecoration(
        labelText:          'Phone Number',
        labelStyle:         const TextStyle(color: _kTextMid, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _kGold, fontSize: 12),
        filled:      true,
        fillColor:   _kFieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: const BorderSide(color: _kErrorCol),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kErrorCol, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _kErrorCol, fontSize: 11),
      ),
      dropdownDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _kFieldFill,
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
