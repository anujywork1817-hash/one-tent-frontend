import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _kMaroon      = Color(0xFF4A1000);
const _kBodyBg      = Color(0xFFFFFFFF);
const _kCardBg      = Color(0xFFFFFFFF);
const _kBorderLight = Color(0xFFDDD0C4);
const _kGold        = Color(0xFFD4891A);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextMid     = Color(0xFF7A4A30);
const _kTextLight   = Color(0xFFA07050);
const _kSuccess     = Color(0xFF2E7D32);

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String supportEmail = 'jayashriinfotechpvtltd@gmail.com';
  static const String supportPhone = '+919699488429';
  static const String supportPhoneDisplay = '+91 96994 88429';

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: supportPhone);
    if (!await launchUrl(uri)) _showError(context, 'Could not open the dialer');
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
        title: const Text('Help & Support',
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kSuccess.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Icon(Icons.support_agent, color: _kSuccess, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Need help with a booking, payment or passport upload? '
                    'Reach out and our team will assist you.',
                    style: TextStyle(
                        color: _kTextMid, fontSize: 13.5, height: 1.5),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Instant answers without waiting on a human — the Call option
            // below is still there for anything account-specific.
            GestureDetector(
              onTap: () => context.push('/ai-chat'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kMaroon, Color(0xFF6B1A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _kMaroon.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_outlined,
                        color: _kGold, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chat with AI Support',
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Get instant answers about booking, GST & more',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _kGold),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Contact Us',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark)),
            const SizedBox(height: 14),

            _ContactCard(
              icon: Icons.phone_outlined,
              label: 'Support',
              value: 'Tap Call to reach our team',
              actionIcon: Icons.call,
              actionLabel: 'Call',
              onAction: () => _call(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionIcon,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final IconData actionIcon;
  final String   actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _kMaroon.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kGold, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: _kTextLight)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _kGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(actionIcon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(actionLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}
