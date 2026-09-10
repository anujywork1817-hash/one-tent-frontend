import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'help_support_screen.dart' show HelpSupportScreen;

const _kBodyBg      = Color(0xFFFFFFFF);
const _kCardBg      = Color(0xFFFFFFFF);
const _kBorderLight = Color(0xFFDDD0C4);
const _kGold        = Color(0xFFD4891A);
const _kMaroon      = Color(0xFF4A1000);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextMid     = Color(0xFF7A4A30);
const _kTextLight   = Color(0xFFA07050);

/// Real app-store package id — must match android/app/build.gradle.kts'
/// applicationId, or the Play Store deep link opens the wrong listing.
const _packageId = 'com.kumbh.one_tent';

/// A standard "rate our app" gate: pick a star rating first. 4-5 stars sends
/// the guest straight to the Play Store listing (where a rating actually
/// counts publicly); 1-3 stars asks for what went wrong instead, since a
/// frustrated guest venting in a public store review helps no one — routing
/// that feedback to us directly, via email (there's no in-app feedback
/// inbox on the backend), is what actually gets it read and acted on.
class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;
  final _feedbackCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  static const _labels = {
    1: 'Poor',
    2: 'Fair',
    3: 'Okay',
    4: 'Good',
    5: 'Excellent',
  };

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  bool get _isHighRating => _rating >= 4;

  Future<void> _openPlayStore() async {
    final marketUri = Uri.parse('market://details?id=$_packageId');
    final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$_packageId');
    final opened =
        await launchUrl(marketUri, mode: LaunchMode.externalApplication)
            .catchError((_) => false);
    if (!opened) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
    if (mounted) context.pop();
  }

  Future<void> _sendFeedback() async {
    if (_feedbackCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);

    final subject = Uri.encodeComponent('One Tent app feedback ($_rating★)');
    final body = Uri.encodeComponent(_feedbackCtrl.text.trim());
    final mailUri = Uri.parse(
        'mailto:${HelpSupportScreen.supportEmail}?subject=$subject&body=$body');

    final opened =
        await launchUrl(mailUri).catchError((_) => false);

    if (!mounted) return;
    setState(() => _sending = false);

    if (opened) {
      setState(() => _sent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Could not open your email app — reach us at ${HelpSupportScreen.supportEmail}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        surfaceTintColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _kTextDark, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text('Rate One Tent',
            style: TextStyle(
                color: _kTextDark, fontWeight: FontWeight.w700, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: _kMaroon.withValues(alpha: 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cabin, color: _kGold, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text('How would you rate One Tent?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark)),
                  const SizedBox(height: 4),
                  const Text(
                      'Your feedback helps us improve the app for every guest.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: _kTextLight)),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return IconButton(
                        onPressed: () => setState(() {
                          _rating = starIndex;
                          _sent = false;
                        }),
                        icon: Icon(
                          starIndex <= _rating
                              ? Icons.star
                              : Icons.star_border,
                          color: _kGold,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 2),
                    Text(_labels[_rating]!,
                        style: const TextStyle(
                            color: _kGold,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── High rating: send to Play Store ─────────────────────────
            if (_isHighRating) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openPlayStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.storefront_outlined, size: 20),
                  label: const Text('Rate us on Play Store',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Thanks — this takes you to the Play Store to post it.',
                  style: const TextStyle(fontSize: 12, color: _kTextLight),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // ── Low/mid rating: ask what went wrong, in-app ─────────────
            if (_rating > 0 && !_isHighRating) ...[
              const Text("What could we do better?",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark)),
              const SizedBox(height: 10),
              TextField(
                controller: _feedbackCtrl,
                maxLines: 5,
                enabled: !_sent,
                style: const TextStyle(color: _kTextDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Tell us what went wrong — booking, payment, the app itself…',
                  hintStyle: const TextStyle(
                      color: _kTextLight, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF3EEE7),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_sent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle_outline,
                        color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thanks for the feedback — our team will follow up.',
                        style: TextStyle(
                            color: Color(0xFF2E7D32), fontSize: 13),
                      ),
                    ),
                  ]),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kMaroon,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _kMaroon.withValues(alpha: 0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Send Feedback',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Opens your email app, addressed to our support team.',
                  style: const TextStyle(fontSize: 11.5, color: _kTextLight),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
