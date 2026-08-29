import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const _kHeroBg = Color(0xFF4A1000);
const _kMaroonMid = Color(0xFF6B1A00);
const _kBodyBg = Color(0xFFF2EAE0);
const _kCardBg = Color(0xFFFFFFFF);
const _kGold = Color(0xFFD4891A);
const _kGoldLight = Color(0xFFE8A93A);
const _kBorderLight = Color(0xFFDDD0C4);
const _kTextDark = Color(0xFF2D0F05);
const _kTextMid = Color(0xFF7A4A30);
const _kTextLight = Color(0xFFA07050);
const _kCream = Color(0xFFF5E6C8);
const _kSuccess = Color(0xFF2E7D32);
const _kError = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

const _capsuleHighlights = [
  {'icon': Icons.privacy_tip_rounded, 'label': 'Private & Peaceful'},
  {'icon': Icons.health_and_safety_rounded, 'label': 'Secure & Hygienic'},
  {'icon': Icons.solar_power_rounded, 'label': 'Solar Powered'},
  {'icon': Icons.support_agent_rounded, 'label': 'On-call Assist'},
];

class PaymentScreen extends StatefulWidget {
  final TentBooking booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final tentProv = context.read<TentProvider>();
    final data = await tentProv.createPaymentOrder(widget.booking.id);

    if (!mounted) return;

    if (data == null) {
      setState(() {
        _error = tentProv.error ?? 'Failed to create payment order';
        _isLoading = false;
      });
      return;
    }

    final orderId = data['razorpay_order_id'] as String? ?? '';
    final amount = data['amount'] as int? ?? 0;
    final currency = data['currency'] as String? ?? 'INR';
    final keyId = data['key_id'] as String? ?? '';

    final options = {
      'key': keyId,
      'amount': amount,
      'currency': currency,
      'order_id': orderId,
      'name': 'One Tent',
      'description': 'Booking Ref: ${widget.booking.bookingRef}',
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#4A1000'},
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay']
      },
    };

    setState(() => _isLoading = false);
    _razorpay.open(options);
  }

  void _onSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);

    final tentProv = context.read<TentProvider>();
    final ok = await tentProv.verifyPayment(
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _showSuccess(response.paymentId ?? '');
    } else {
      setState(() {
        _error =
            'Payment received but verification failed. Contact support with ref: ${widget.booking.bookingRef}';
      });
    }
  }

  void _onError(PaymentFailureResponse response) {
    setState(() {
      _error = response.message ?? 'Payment failed. Please try again.';
      _isLoading = false;
    });
  }

  // Backing out of an unpaid booking used to leave it sitting as 'pending'
  // for up to 15 minutes (the server's abandoned-checkout hold window),
  // blocking these dates for everyone else the whole time. Cancelling here
  // releases them immediately instead of making the guest wait it out.
  Future<void> _cancelAndLeave() async {
    if (!context.mounted) return;
    final tentProv = context.read<TentProvider>();
    final booking = widget.booking;
    unawaited(tentProv.cancelBooking(booking.id, reason: 'Left before paying'));
    if (mounted) context.pop();
  }

  void _onWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
        backgroundColor: _kHeroBg,
      ),
    );
  }

  void _showSuccess(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kSuccess.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _kSuccess.withValues(alpha: 0.35), width: 2),
              ),
              child: const Icon(Icons.check_circle, color: _kSuccess, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Payment Successful!',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _kTextDark)),
            const SizedBox(height: 4),
            const Text(
              'Stay. Inspire. Remember.',
              style: TextStyle(
                  color: _kGold,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text('Ref: ${widget.booking.bookingRef}',
                style: const TextStyle(color: _kTextMid, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGold.withValues(alpha: 0.35)),
              ),
              child: Text(
                  '₹${widget.booking.amountDue.toStringAsFixed(0)} paid',
                  style: const TextStyle(
                      color: _kGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(height: 6),
            Text('Payment ID: $paymentId',
                style: const TextStyle(fontSize: 11, color: _kTextLight)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGold.withValues(alpha: 0.20)),
              ),
              child: const Text(
                'One Tent is more than a stay — it\'s part of your journey.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _kTextMid, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/my-bookings');
            },
            child: const Text('View My Bookings',
                style: TextStyle(color: _kGold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelAndLeave();
      },
      child: Scaffold(
        backgroundColor: _kBodyBg,

        // ── Hero App Bar ────────────────────────────────────────────────
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
              onPressed: _cancelAndLeave,
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
              child: const Icon(Icons.payment, color: _kGold, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Payment',
                style: TextStyle(
                    color: _kCream, fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // ── Booking summary card ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kHeroBg, _kMaroonMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kGold.withValues(alpha: 0.30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.receipt_long, color: _kGold, size: 16),
                      const SizedBox(width: 8),
                      Text('Booking Summary',
                          style: TextStyle(
                              color: _kCream.withValues(alpha: 0.70),
                              fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    Text('Ref: ${booking.bookingRef}',
                        style: const TextStyle(
                            color: _kCream,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        '${booking.duration} day(s)  •  ${booking.numGuests} guest(s)',
                        style: TextStyle(
                            color: _kCream.withValues(alpha: 0.70),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Capsule highlights ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGold.withValues(alpha: 0.20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What\'s waiting for you',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _kTextDark)),
                    const SizedBox(height: 10),
                    Row(
                      children: _capsuleHighlights
                          .map((h) => Expanded(
                                child: Column(children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _kGold.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(h['icon'] as IconData,
                                        size: 16, color: _kGold),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(h['label'] as String,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: _kTextMid,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 2),
                                ]),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Total amount ──────────────────────────────────────────
              Center(
                child: Column(children: [
                  Text(
                      booking.roomCount > 1
                          ? 'Total Amount · ${booking.roomCount} Rooms'
                          : 'Total Amount',
                      style: const TextStyle(color: _kTextMid, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('₹${booking.amountDue.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _kGold)),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Payment methods card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorderLight),
                  boxShadow: [
                    BoxShadow(
                        color: _kHeroBg.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            const Icon(Icons.payment, color: _kGold, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('Pay via',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _kTextDark)),
                    ]),
                    const SizedBox(height: 14),
                    const _PayMethod(
                        icon: Icons.credit_card, label: 'Credit / Debit Card'),
                    const SizedBox(height: 10),
                    const _PayMethod(
                        icon: Icons.account_balance_wallet,
                        label: 'UPI (GPay, PhonePe, Paytm)'),
                    const SizedBox(height: 10),
                    const _PayMethod(
                        icon: Icons.account_balance, label: 'Net Banking'),
                  ],
                ),
              ),

              // ── Error ─────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kError.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kError.withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: _kError, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(color: _kError))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // ── Pay button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kHeroBg,
                    disabledBackgroundColor: _kHeroBg.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: BorderSide(color: _kGold.withValues(alpha: 0.55)),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: _kGold, strokeWidth: 2))
                      : Text(
                          'Pay ₹${booking.amountDue.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: _kCream,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Secure + eco note ─────────────────────────────────────
              Center(
                child: Column(children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock, size: 14, color: _kTextLight),
                    const SizedBox(width: 4),
                    Text('Secured by Razorpay',
                        style: TextStyle(color: _kTextLight, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.eco_rounded, size: 13, color: _kSuccess),
                    const SizedBox(width: 4),
                    Text('Your stay is solar powered & eco-friendly',
                        style: TextStyle(
                            color: _kTextLight,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PayMethod({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _kGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _kGold, size: 16),
      ),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: _kTextMid, fontSize: 13)),
    ]);
  }
}
