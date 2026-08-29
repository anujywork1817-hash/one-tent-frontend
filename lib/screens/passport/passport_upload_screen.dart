import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const _kHeroBg      = Color(0xFF4A1000);
const _kMaroonMid   = Color(0xFF6B1A00);
const _kBodyBg      = Color(0xFFF2EAE0);
const _kCardBg      = Color(0xFFFFFFFF);
const _kGold        = Color(0xFFD4891A);
const _kGoldLight   = Color(0xFFE8A93A);
const _kBorderLight = Color(0xFFDDD0C4);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextMid     = Color(0xFF7A4A30);
const _kTextLight   = Color(0xFFA07050);
const _kCream       = Color(0xFFF5E6C8);
const _kSuccess     = Color(0xFF2E7D32);
const _kError       = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

class PassportUploadScreen extends StatefulWidget {
  const PassportUploadScreen({super.key});

  @override
  State<PassportUploadScreen> createState() => _PassportUploadScreenState();
}

class _PassportUploadScreenState extends State<PassportUploadScreen> {
  XFile?     _selectedFile;
  Uint8List? _webImageBytes;
  bool       _loading  = false;
  bool       _uploaded = false;
  bool       _statusLoading = true;
  String?    _error;

  // Status vocabulary must match the backend exactly: none | uploaded |
  // verified | rejected. It previously checked for 'approved'/'pending',
  // which no endpoint ever returns, so a verified passport fell through to
  // the default and displayed "Not Uploaded".
  String  _passportStatus = 'none';
  String  _rejectNote     = '';
  String  _statusMessage  = '';
  String? _passportUrl;

  final _picker = ImagePicker();

  bool get _isVerified => _passportStatus == 'verified';
  bool get _isRejected => _passportStatus == 'rejected';
  bool get _isPending  => _passportStatus == 'uploaded';

  static bool _isPdf(String path) => path.toLowerCase().endsWith('.pdf');

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final auth = context.read<AuthProvider>();
      final result = await auth.getPassportStatus();
      if (!mounted) return;
      setState(() {
        _passportStatus = (result['passport_status'] as String?) ?? 'none';
        _rejectNote     = (result['passport_reject_note'] as String?) ?? '';
        _statusMessage  = (result['message'] as String?) ?? '';
        _passportUrl    = result['passport_url'] as String?;
        _statusLoading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFile  = null;
      _webImageBytes = null;
      _error         = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1200);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedFile  = picked;
          _webImageBytes = bytes;
          _error         = null;
        });
      } else {
        setState(() {
          _selectedFile  = picked;
          _webImageBytes = null;
          _error         = null;
        });
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _kBorderLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('Upload Passport Photo',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark)),
              const SizedBox(height: 20),
              _pickerTile(Icons.camera_alt, 'Take Photo', () {
                context.pop();
                _pickImage(ImageSource.camera);
              }),
              const SizedBox(height: 12),
              _pickerTile(Icons.photo_library, 'Choose from Gallery', () {
                context.pop();
                _pickImage(ImageSource.gallery);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.07),
            border: Border.all(color: _kGold.withValues(alpha: 0.30)),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _kGold, size: 20),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(
                  fontSize: 15, color: _kTextDark, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Future<void> _upload() async {
    if (_selectedFile == null) {
      setState(() => _error = 'Please select a passport photo first');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      if (kIsWeb) {
        await Future.delayed(const Duration(seconds: 1));
      } else {
        await auth.uploadPassport(_selectedFile!.path);
      }
      if (!mounted) return;
      setState(() {
        _uploaded       = true;
        _loading        = false;
        _selectedFile   = null;
        _webImageBytes  = null;
        // A fresh upload always re-enters review and clears the old verdict.
        _passportStatus = 'uploaded';
        _rejectNote     = '';
      });
      // Pull the server's authoritative status and the stored file URL.
      _loadStatus();
    } catch (e) {
      setState(() {
        _error   = 'Upload failed: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified': return _kSuccess;
      case 'rejected': return _kError;
      case 'uploaded': return _kGold;
      default:         return _kTextLight;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'verified': return Icons.verified;
      case 'rejected': return Icons.cancel_outlined;
      case 'uploaded': return Icons.hourglass_top;
      default:         return Icons.upload_file;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified': return 'Verified';
      case 'rejected': return 'Rejected — please re-upload';
      case 'uploaded': return 'Under Review';
      default:         return 'Not Uploaded';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,

      // ── Hero App Bar ──────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kHeroBg,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kGold.withValues(alpha: 0.40)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: _kCream, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kGold.withValues(alpha: 0.45)),
            ),
            child: const Icon(Icons.badge_outlined, color: _kGold, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Passport Upload',
              style: TextStyle(
                  color: _kCream, fontWeight: FontWeight.w600, fontSize: 17)),
        ]),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),

      body: RefreshIndicator(
        color: _kGold,
        // Pulls the latest verification verdict — the status changes on the
        // admin side, so refreshing here is how a guest sees it.
        onRefresh: _loadStatus,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // ── Web notice ──────────────────────────────────────────────
            if (kIsWeb) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kGold.withValues(alpha: 0.25))),
                child: const Row(children: [
                  Icon(Icons.phone_android, color: _kGold, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For best results, upload your passport photo using the mobile app.',
                      style: TextStyle(color: _kTextMid, fontSize: 13),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // ── Status banner ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _statusColor(_passportStatus).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _statusColor(_passportStatus).withValues(alpha: 0.30))),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _statusColor(_passportStatus).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(_passportStatus),
                      color: _statusColor(_passportStatus), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Passport Status',
                            style: TextStyle(fontSize: 12, color: _kTextLight)),
                        Text(
                          _statusLoading
                              ? 'Checking…'
                              : _statusLabel(_passportStatus),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(_passportStatus)),
                        ),
                        if (!_statusLoading && _statusMessage.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_statusMessage,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _kTextMid,
                                  height: 1.4)),
                        ],
                      ]),
                ),
              ]),
            ),

            // ── Rejection reason ────────────────────────────────────────
            if (_isRejected && _rejectNote.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _kError.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kError.withValues(alpha: 0.30))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: _kError, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reason for rejection',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4,
                                      color: _kError)),
                              const SizedBox(height: 3),
                              Text(_rejectNote,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: _kTextDark,
                                      height: 1.4)),
                            ]),
                      ),
                    ]),
              ),
            ],

            // ── What the guest already sent ─────────────────────────────
            if (_passportUrl != null &&
                _passportUrl!.isNotEmpty &&
                _selectedFile == null) ...[
              const SizedBox(height: 20),
              Row(children: [
                Container(width: 3, height: 16, color: _kGold,
                    margin: const EdgeInsets.only(right: 8)),
                const Text('Your Submitted Passport',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _isPdf(_passportUrl!)
                    ? Container(
                        height: 90,
                        width: double.infinity,
                        color: _kCardBg,
                        padding: const EdgeInsets.all(16),
                        child: const Row(children: [
                          Icon(Icons.picture_as_pdf, color: _kError, size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('PDF document submitted',
                                style: TextStyle(
                                    color: _kTextDark,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ]),
                      )
                    : Image.network(
                        AppConstants.fileUrl(_passportUrl!),
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 90,
                          color: _kCardBg,
                          alignment: Alignment.center,
                          child: const Text('Preview unavailable',
                              style: TextStyle(color: _kTextLight)),
                        ),
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    height: 190,
                                    color: _kCardBg,
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                        color: _kGold, strokeWidth: 2),
                                  ),
                      ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Verified: nothing left to do ────────────────────────────
            if (_isVerified) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: _kSuccess.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: _kSuccess.withValues(alpha: 0.30))),
                child: const Row(children: [
                  Icon(Icons.verified, color: _kSuccess, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your passport is verified. No further action is needed.',
                      style: TextStyle(
                          color: _kSuccess,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // ── Upload / re-upload (hidden once verified) ───────────────
            if (!_isVerified) ...[
            // ── Section header ──────────────────────────────────────────
            Row(children: [
              Container(width: 3, height: 16, color: _kGold,
                  margin: const EdgeInsets.only(right: 8)),
              Text(
                  _isRejected
                      ? 'Upload a New Passport Photo'
                      : _isPending
                          ? 'Replace Your Passport Photo'
                          : 'Upload Passport Photo',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark)),
            ]),
            const SizedBox(height: 6),
            Text(
                _isRejected
                    ? 'Fix the issue above and send a clear photo of your '
                        'passport\'s main page.'
                    : 'Upload a clear photo of your passport\'s main page.',
                style: const TextStyle(
                    fontSize: 13, color: _kTextMid, height: 1.5)),
            const SizedBox(height: 20),

            // ── Image picker / preview ──────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _selectedFile == null ? _showPickerOptions : null,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _selectedFile != null
                                ? _kGold
                                : _kBorderLight,
                            width: _selectedFile != null ? 2 : 1),
                        boxShadow: [
                          BoxShadow(
                              color: _kHeroBg.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ]),
                    child: _selectedFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  color: _kGold.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _kGold.withValues(alpha: 0.30)),
                                ),
                                child: const Icon(Icons.add_photo_alternate_outlined,
                                    size: 28, color: _kGold),
                              ),
                              const SizedBox(height: 12),
                              const Text('Tap to upload passport photo',
                                  style: TextStyle(
                                      color: _kTextDark,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              const Text('JPG or PNG, max 5MB',
                                  style: TextStyle(
                                      color: _kTextLight, fontSize: 12)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: kIsWeb && _webImageBytes != null
                                ? Image.memory(_webImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200)
                                : Image.file(File(_selectedFile!.path),
                                    fit: BoxFit.cover),
                          ),
                  ),
                ),

                // Cancel the currently selected (not-yet-submitted) photo —
                // sits over the top-right corner of its preview.
                if (_selectedFile != null)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: GestureDetector(
                      onTap: _clearSelection,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _kHeroBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kCream, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.close,
                            color: _kCream, size: 18),
                      ),
                    ),
                  ),
              ],
            ),

            if (_selectedFile != null) ...[
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _showPickerOptions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kGold.withValues(alpha: 0.35)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.refresh, size: 15, color: _kGold),
                      SizedBox(width: 6),
                      Text('Change Photo',
                          style: TextStyle(color: _kGold, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ],

            // ── Error ───────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _kError.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kError.withValues(alpha: 0.25))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: _kError, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: _kError, fontSize: 13))),
                ]),
              ),
            ],

            // ── Uploaded success ────────────────────────────────────────
            if (_uploaded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _kSuccess.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kSuccess.withValues(alpha: 0.25))),
                child: const Row(children: [
                  Icon(Icons.check_circle_outline,
                      color: _kSuccess, size: 18),
                  SizedBox(width: 8),
                  Text('Passport uploaded! Under review by admin.',
                      style: TextStyle(color: _kSuccess, fontSize: 13)),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // ── Tips card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kGold.withValues(alpha: 0.20))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.tips_and_updates_outlined,
                        color: _kGold, size: 18),
                    SizedBox(width: 8),
                    Text('Tips for a good photo',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _kTextDark,
                            fontSize: 14)),
                  ]),
                  const SizedBox(height: 10),
                  ...[
                    'All 4 corners of the passport must be visible',
                    'Ensure good lighting — no shadows or glare',
                    'Photo must be in focus and clearly readable',
                    'Upload the photo page (with your face)',
                  ].map((tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: _kGold,
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(tip,
                                  style: TextStyle(
                                      color: _kTextMid, fontSize: 13)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Submit / Done button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _uploaded
                  ? ElevatedButton(
                      onPressed: () =>
                          Navigator.canPop(context) ? context.pop() : context.go('/profile'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kSuccess,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          )),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: _kCream, size: 20),
                          SizedBox(width: 8),
                          Text('Done',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _kCream)),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _loading ? null : _upload,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kHeroBg,
                          disabledBackgroundColor: _kBorderLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                            side: BorderSide(color: _kGold.withValues(alpha: 0.55)),
                          )),
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: _kGold, strokeWidth: 2))
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _kCream)),
                    ),
            ),
            ], // end !_isVerified
            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }
}