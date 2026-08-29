import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

// ─────────────────────────────────────────────
//  One Tent — Split Theme Tokens
// ─────────────────────────────────────────────
const _kHeroBg      = Color(0xFF3D0F05);
const _kBodyBg      = Color(0xFFF2EAE0);
const _kCardBg      = Color(0xFFFFFFFF);
const _kChipBg      = Color(0xFFEDE0D4);
const _kBorderLight = Color(0xFFDDD0C4);
const _kGold        = Color(0xFFD4891A);
const _kGoldLight   = Color(0xFFE8A93A);
const _kMaroon      = Color(0xFF5C1A08);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextMid     = Color(0xFF7A4A30);
const _kTextLight   = Color(0xFFA07050);
const _kCream       = Color(0xFFF5E6C8);
const _kErrorColor  = Color(0xFFC0392B);

/// What the photo bottom sheet returned. `remove` is why this isn't just an
/// ImageSource.
enum _PhotoAction { gallery, camera, remove }

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  File?   _pickedImage;
  /// Set when the guest chose "Remove photo". Applied on save, so backing out
  /// with Cancel leaves the stored picture untouched.
  bool    _removeImage = false;
  bool    _loading  = false;
  String? _errorMsg;

  /// Whether anything would render in the avatar right now — drives the
  /// "Remove photo" option, which is pointless when there's nothing to remove.
  bool _hasPhoto(dynamic visitor) {
    if (_pickedImage != null) return true;
    if (_removeImage) return false;
    return visitor?.profileImageUrl?.isNotEmpty == true;
  }

  @override
  void initState() {
    super.initState();
    final v         = context.read<AuthProvider>().visitor;
    _nameCtrl.text  = v?.fullName ?? '';
    _phoneCtrl.text = v?.phone    ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ────────────────────────────────────────────
  Future<void> _pickImage() async {
    final action = await _showImageSourceDialog();
    if (action == null) return;

    if (action == _PhotoAction.remove) {
      setState(() {
        _pickedImage = null;
        _removeImage = true;
      });
      return;
    }

    final picked = await ImagePicker().pickImage(
        source: action == _PhotoAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800);
    if (picked != null && mounted) {
      setState(() {
        _pickedImage = File(picked.path);
        // Choosing a new photo supersedes a pending removal.
        _removeImage = false;
      });
    }
  }

  Future<_PhotoAction?> _showImageSourceDialog() {
    final canRemove = _hasPhoto(context.read<AuthProvider>().visitor);

    return showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: _kBorderLight, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Profile Photo',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _kTextDark)),
          const SizedBox(height: 16),
          _sourceOption(ctx, Icons.photo_library_outlined,
              'Photo Library', _PhotoAction.gallery),
          const SizedBox(height: 10),
          _sourceOption(ctx, Icons.camera_alt_outlined,
              'Take Photo', _PhotoAction.camera),
          if (canRemove) ...[
            const SizedBox(height: 10),
            _sourceOption(ctx, Icons.delete_outline,
                'Remove Photo', _PhotoAction.remove, danger: true),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextMid)),
          ),
        ]),
      ),
    );
  }

  Widget _sourceOption(
      BuildContext ctx, IconData icon, String label, _PhotoAction action,
      {bool danger = false}) {
    final tint = danger ? _kErrorColor : _kMaroon;
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: danger ? _kErrorColor.withValues(alpha: 0.06) : _kBodyBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: danger
                  ? _kErrorColor.withValues(alpha: 0.30)
                  : _kBorderLight),
        ),
        child: Row(children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  color: danger ? _kErrorColor : _kTextDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────
  // Single call — providers.dart handles the merge so existing
  // fields (nationality, country, passport) are never wiped.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    final success = await context.read<AuthProvider>().updateProfile(
      name:               _nameCtrl.text.trim(),
      phone:              _phoneCtrl.text.trim(),
      profileImageFile:   _pickedImage,
      removeProfileImage: _removeImage && _pickedImage == null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated successfully'),
        backgroundColor: _kMaroon,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      context.pop();
    } else {
      final providerError = context.read<AuthProvider>().error;
      setState(() {
        _errorMsg = providerError ?? 'Update failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v        = context.watch<AuthProvider>().visitor;
    final errorMsg = _errorMsg;

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: CustomScrollView(
        slivers: [

          // ── App Bar ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _kHeroBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _kCream, size: 18),
              onPressed: () => context.pop(),
            ),
            title: const Text('Edit Profile',
                style: TextStyle(
                    color: _kCream, fontSize: 17, fontWeight: FontWeight.w600)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5C1A08), Color(0xFF3D0F05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 36),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(children: [
                              Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  color: _kChipBg,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                      color: _kGold.withValues(alpha: 0.5),
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: _pickedImage != null
                                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                      : (!_removeImage &&
                                              v?.profileImageUrl?.isNotEmpty == true
                                          ? Image.network(
                                              AppConstants.fileUrl(v!.profileImageUrl!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _avatarFallback(v.fullName))
                                          : _avatarFallback(v?.fullName ?? '?')),
                                ),
                              ),
                              Positioned(
                                right: 0, bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _kGold,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _kHeroBg, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Text('Tap to change photo',
                              style: TextStyle(
                                  color: _kCream.withValues(alpha: 0.6),
                                  fontSize: 11)),
                          if (_pickedImage != null || _removeImage) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _removeImage
                                    ? _kErrorColor.withValues(alpha: 0.25)
                                    : _kGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                  _removeImage
                                      ? 'Photo will be removed on save'
                                      : 'New photo selected',
                                  style: TextStyle(
                                      color: _removeImage
                                          ? _kCream
                                          : _kGoldLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── Form ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: _kBodyBg,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text('Basic Details',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kTextDark)),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kBorderLight),
                        boxShadow: [
                          BoxShadow(
                              color: _kMaroon.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        _EditField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        _EditPhoneField(controller: _phoneCtrl),
                      ]),
                    ),

                    const SizedBox(height: 14),

                    // Info note — locked fields
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline, color: _kGold, size: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nationality, Country and Passport details '
                            'cannot be changed after registration.',
                            style: TextStyle(
                                color: _kTextMid, fontSize: 12, height: 1.5),
                          ),
                        ),
                      ]),
                    ),

                    // Error message
                    if (errorMsg != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _kErrorColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _kErrorColor.withValues(alpha: 0.35)),
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

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kMaroon,
                          disabledBackgroundColor: _kMaroon.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                            side: BorderSide(color: _kGold.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: _kCream, strokeWidth: 2))
                            : const Text('Save Changes',
                                style: TextStyle(
                                    color: _kCream,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: _kTextMid,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
        color: _kChipBg,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.w700, color: _kGold),
          ),
        ),
      );
}

// ── Themed editable field ─────────────────────────────────
// ── Phone field with world country-code picker ─────────────
class _EditPhoneField extends StatelessWidget {
  const _EditPhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final existing = controller.text.trim();
    return IntlPhoneField(
      style: const TextStyle(color: _kTextDark, fontSize: 14),
      cursorColor: _kGold,
      dropdownTextStyle: const TextStyle(color: _kTextDark, fontSize: 14),
      dropdownIconPosition: IconPosition.trailing,
      dropdownIcon: const Icon(Icons.arrow_drop_down, color: _kMaroon),
      initialCountryCode: existing.startsWith('+') ? null : 'IN',
      initialValue: existing.isEmpty ? null : existing,
      disableLengthCheck: true,
      flagsButtonPadding: const EdgeInsets.only(left: 12),
      decoration: InputDecoration(
        labelText:          'Phone Number',
        labelStyle:         const TextStyle(color: _kTextLight, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _kGold, fontSize: 12),
        filled:    true,
        fillColor: _kBodyBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorderLight),
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
      dropdownDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _kCardBg,
      ),
      onChanged: (phone) => controller.text = phone.completeNumber,
      validator: (phone) {
        if (phone == null || phone.number.trim().isEmpty) {
          return 'Phone is required';
        }
        return null;
      },
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController      controller;
  final String                     label;
  final IconData                   icon;
  final TextInputType?             keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _kTextDark, fontSize: 14),
      cursorColor: _kGold,
      validator: validator,
      decoration: InputDecoration(
        labelText:          label,
        labelStyle:         const TextStyle(color: _kTextLight, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _kGold, fontSize: 12),
        prefixIcon: Icon(icon, color: _kMaroon, size: 20),
        filled:    true,
        fillColor: _kBodyBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorderLight),
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