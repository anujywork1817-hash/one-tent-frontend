import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const _kHeroBg = Color(0xFF4A1000);
const _kBodyBg = Color(0xFFFFFFFF);
const _kCardBg = Color(0xFFFFFFFF);
const _kGold = Color(0xFFD4891A);
const _kBorderLight = Color(0xFFDDD0C4);
const _kTextDark = Color(0xFF2D0F05);
const _kTextMid = Color(0xFF7A4A30);
const _kTextLight = Color(0xFFA07050);
const _kSuccess = Color(0xFF2E7D32);
const _kError = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

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

    final visitor = context.read<AuthProvider>().visitor;
    final options = {
      'key': keyId,
      'amount': amount,
      'currency': currency,
      'order_id': orderId,
      'name': 'One Tent',
      'description': 'Booking Ref: ${widget.booking.bookingRef}',
      'prefill': {
        'contact': visitor?.phone ?? '',
        'email': visitor?.email ?? '',
      },
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
    // Leaving an unpaid checkout drops the guest back to Home, in step with
    // the app-wide back behaviour, rather than to the now-stale booking form.
    if (mounted) context.go('/home');
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
            const Text('Payment Successful',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            Text('Ref: ${widget.booking.bookingRef}',
                style: const TextStyle(color: _kTextMid, fontSize: 13)),
            const SizedBox(height: 10),
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

        // ── App bar — same plain white chrome as every other screen ──────
        appBar: AppBar(
          backgroundColor: _kCardBg,
          surfaceTintColor: _kCardBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: _kTextDark, size: 28),
            onPressed: _cancelAndLeave,
          ),
          title: const Text('Payment',
              style: TextStyle(
                  color: _kTextDark, fontSize: 17, fontWeight: FontWeight.w700)),
          centerTitle: false,
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
              const SizedBox(height: 4),

              // ── Booking summary ────────────────────────────────────────
              // Plain text, no boxed card — this is the same "screen title"
              // weight everywhere else in the app, not a separate widget
              // fighting the price card below it for attention.
              Text(booking.bookingRef,
                  style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${booking.duration} night${booking.duration == 1 ? '' : 's'} · ${booking.numGuests} guest${booking.numGuests == 1 ? '' : 's'}',
                  style: const TextStyle(color: _kTextMid, fontSize: 13.5)),
              const SizedBox(height: 24),

              // ── Price breakdown ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _kHeroBg.withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price Breakdown',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _kTextDark)),
                    const SizedBox(height: 12),
                    // Real headcount for this booking — the same guest and
                    // children counts the child charge below is based on.
                    _breakdownRow(
                      'Guests',
                      null,
                      valueText: '${booking.numGuests} adult${booking.numGuests == 1 ? '' : 's'}'
                          '${(booking.childrenUnder5 + booking.childrenAbove5) > 0 ? ' + ${booking.childrenUnder5 + booking.childrenAbove5} child${(booking.childrenUnder5 + booking.childrenAbove5) == 1 ? '' : 'ren'}' : ''}',
                    ),
                    // Per-tax figures only add up cleanly for a single-tent
                    // booking — a multi-room checkout's group total is the
                    // real sum across all rooms, so it gets a plain total
                    // instead of a breakdown that wouldn't actually match.
                    if (booking.roomCount > 1) ...[
                      _breakdownRow(
                          'Combined charge · ${booking.roomCount} tents',
                          booking.amountDue),
                    ] else ...[
                      _breakdownRow('Room charge', booking.baseAmount),
                      if (booking.discountAmount > 0)
                        _breakdownRow(
                          booking.couponCode != null
                              ? 'Coupon (${booking.couponCode})'
                              : 'Discount',
                          -booking.discountAmount,
                          valueColor: _kSuccess,
                        ),
                      _breakdownRow(
                          'CGST (${(booking.gstRate / 2).toStringAsFixed(0)}%)',
                          booking.cgstAmount),
                      _breakdownRow(
                          'SGST (${(booking.gstRate / 2).toStringAsFixed(0)}%)',
                          booking.sgstAmount),
                      if (booking.childFee > 0)
                        _breakdownRow(
                            'Child charge (${booking.childrenAbove5} above 5 yrs)',
                            booking.childFee),
                    ],
                    const Divider(height: 22, color: _kBorderLight),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total payable',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('₹${booking.amountDue.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: _kGold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Payment methods ────────────────────────────────────────
              const Text('Pay via',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: _kTextMid,
                      letterSpacing: 0.3)),
              const SizedBox(height: 12),
              const _PayMethod(
                  icon: Icons.credit_card_outlined,
                  label: 'Credit / Debit Card'),
              const _PayMethod(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'UPI (GPay, PhonePe, Paytm)'),
              const _PayMethod(
                  icon: Icons.account_balance_outlined, label: 'Net Banking'),

              // ── Error ─────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kError.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: _kError, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: _kError, fontSize: 13))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // ── Pay button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    disabledBackgroundColor: _kGold.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Pay ₹${booking.amountDue.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Secure note ────────────────────────────────────────────
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_outline, size: 13, color: _kTextLight),
                  const SizedBox(width: 4),
                  Text('Secured by Razorpay',
                      style: TextStyle(color: _kTextLight, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// [value] renders as a ₹ amount; pass null with [valueText] instead for
  /// a non-money row like a headcount.
  Widget _breakdownRow(String label, double? value,
      {Color? valueColor, String? valueText}) {
    final display = valueText ??
        () {
          final v = value ?? 0;
          final isNegative = v < 0;
          return '${isNegative ? '-' : ''}₹${v.abs().toStringAsFixed(0)}';
        }();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: _kTextMid, fontSize: 12.5)),
          ),
          Text(display,
              style: TextStyle(
                  color: valueColor ?? _kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: _kTextMid, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: _kTextDark, fontSize: 13.5)),
      ]),
    );
  }
}
