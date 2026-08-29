import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/handcrafted.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kBgDeep = Color(0xFF0D0401);
const Color _kMaroon = Color(0xFF4A1000);
const Color _kGold = Color(0xFFD4891A);
const Color _kGoldLight = Color(0xFFE8A93A);
const Color _kCream = Color(0xFFF5E6C8);
const Color _kBodyBg = Color(0xFFF2EAE0);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kTextDark = Color(0xFF2C1A0E);
const Color _kTextMuted = Color(0xFF8A6A50);
const Color _kDivider = Color(0xFFEDE0D4);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kRed = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

class QRCodeScreen extends StatefulWidget {
  final TentBooking booking;
  const QRCodeScreen({super.key, required this.booking});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String? _qrContent;
  bool _loading = true;
  String? _error;
  List<AdditionalGuest> _otherGuests = [];

  @override
  void initState() {
    super.initState();
    _loadQR();
  }

  Future<void> _loadQR() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tentProv = context.read<TentProvider>();
      final data = await tentProv.getQRCode(widget.booking.id);
      final rawGuests = data?['additional_guests'] as List<dynamic>? ?? [];
      setState(() {
        _qrContent = data?['qr_content'] as String? ??
            data?['qr_token'] as String? ??
            widget.booking.id;
        _otherGuests = rawGuests
            .map((g) => AdditionalGuest.fromJson(g as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final fmt = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: Column(
        children: [
          // ── Dark maroon hero header ──────────────────────────────────
          _QRHeader(),

          // ── Scrollable cream body ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                children: [
                  // ── Booking info banner ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kMaroon,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: _kMaroon.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: _kGold.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.confirmation_number_outlined,
                            color: _kGold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking #${b.bookingRef}',
                              style: const TextStyle(
                                color: _kCream,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${fmt.format(b.checkInDateTime)} → ${fmt.format(b.checkOutDateTime)}',
                              style: TextStyle(
                                  color: _kCream.withValues(alpha: 0.65),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Status badge — an ink-stamped circle for a confirmed
                      // booking (the common case), a plain pill otherwise.
                      if (b.status == 'confirmed')
                        InkStamp(
                          text: 'Confirmed',
                          color: _kGold,
                          size: 52,
                          degrees: -7,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _kGold.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            b.status.toUpperCase(),
                            style: const TextStyle(
                                color: _kGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8),
                          ),
                        ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // ── QR Code box ────────────────────────────────────
                  if (_loading)
                    _QRBox(
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: _kGold, strokeWidth: 2.5),
                      ),
                    )
                  else if (_error != null)
                    _QRBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _kRed.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _kRed.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.error_outline,
                                color: _kRed, size: 26),
                          ),
                          const SizedBox(height: 12),
                          const Text('Could not load QR',
                              style: TextStyle(
                                  color: _kRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _loadQR,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 7),
                              decoration: BoxDecoration(
                                color: _kMaroon,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _kGold.withValues(alpha: 0.5)),
                              ),
                              child: const Text('Retry',
                                  style: TextStyle(
                                      color: _kGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Actual QR code — white card with gold border
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _kGold.withValues(alpha: 0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _kMaroon.withValues(alpha: 0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Gold decorative top strip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: _kGold.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.temple_hindu,
                                  color: _kGold, size: 16),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: _kGold.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _qrContent ?? b.id,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square, color: _kBgDeep),
                            dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: _kMaroon),
                          ),
                          const SizedBox(height: 8),
                          // One Tent label below QR — hand-lettered rather
                          // than tracked-out caps, like a stamp added by hand.
                          Tilt(
                            degrees: -2,
                            child: Text(
                              'One Tent',
                              style: AppFonts.handwritten(
                                fontSize: 22,
                                color: _kGold.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Instruction text ───────────────────────────────
                  if (_qrContent != null) ...[
                    Tilt(
                      degrees: -1,
                      child: Text(
                        'Show this QR code at check-in',
                        style: AppFonts.handwritten(
                          fontSize: 20,
                          color: _kTextDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Staff will scan this to verify your booking',
                      style: TextStyle(fontSize: 13, color: _kTextMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Booking details card ───────────────────────────
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: handDrawnRadius(base: 16, seed: 9),
                      border: Border.all(color: _kGold.withValues(alpha: 0.18)),
                      boxShadow: [
                        BoxShadow(
                          color: _kMaroon.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(children: [
                      const PaperGrain(color: _kMaroon, opacity: 0.035),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          // Card header
                          Row(children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 15, color: _kGold),
                            const SizedBox(width: 8),
                            const Text('Stay Details',
                                style: TextStyle(
                                    color: _kTextDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ]),
                          const SizedBox(height: 12),
                          const WavyDivider(color: _kDivider, height: 8),
                          const SizedBox(height: 4),
                          _detailRow('Ref', b.bookingRef),
                          const WavyDivider(color: _kDivider, height: 8),
                          _detailRow('Check-in', fmt.format(b.checkInDateTime)),
                          const WavyDivider(color: _kDivider, height: 8),
                          _detailRow(
                              'Check-out', fmt.format(b.checkOutDateTime)),
                          const WavyDivider(color: _kDivider, height: 8),
                          _detailRow('Guests', '${b.numGuests}'),
                          const WavyDivider(color: _kDivider, height: 8),
                          if (b.gstRate > 0) ...[
                            _detailRow('Room Charge',
                                '₹${b.baseAmount.toStringAsFixed(2)}'),
                            const WavyDivider(color: _kDivider, height: 8),
                            _detailRow(
                                'CGST (${b.gstRate.toStringAsFixed(0)}%)',
                                '₹${b.cgstAmount.toStringAsFixed(2)}'),
                            const WavyDivider(color: _kDivider, height: 8),
                            _detailRow(
                                'SGST (${b.gstRate.toStringAsFixed(0)}%)',
                                '₹${b.sgstAmount.toStringAsFixed(2)}'),
                            const WavyDivider(color: _kDivider, height: 8),
                          ],
                          // Total paid — gold highlight
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Paid',
                                    style: TextStyle(
                                        color: _kTextMuted, fontSize: 13)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _kGold.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: _kGold.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    '₹${b.totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: _kGold,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (b.displayCurrency != 'INR' &&
                              b.foreignAmount != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '≈ ${b.foreignAmount!.toStringAsFixed(2)} ${b.displayCurrency}',
                                style: const TextStyle(
                                    color: _kTextMuted,
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                        ]),
                      ),
                    ]),
                  ),

                  if (_otherGuests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: _kGold.withValues(alpha: 0.18)),
                        boxShadow: [
                          BoxShadow(
                            color: _kMaroon.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.people_outline,
                                size: 15, color: _kGold),
                            const SizedBox(width: 8),
                            const Text('Other Guests',
                                style: TextStyle(
                                    color: _kTextDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ]),
                          const SizedBox(height: 10),
                          const WavyDivider(color: _kDivider, height: 8),
                          ..._otherGuests.map((g) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(g.name,
                                        style: const TextStyle(
                                            color: _kTextDark,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    Text(g.phone,
                                        style: const TextStyle(
                                            color: _kTextMuted, fontSize: 13)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _detailRow(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: _kTextMuted, fontSize: 13)),
            Text(value,
                style: TextStyle(
                  color: valueColor ?? _kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      );
}

// ── Dark Maroon Hero Header ────────────────────────────────────────────────────
class _QRHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kMaroon,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: _kCream, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  'Check-in QR Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kCream,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Gold QR badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: _kGold, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.qr_code_rounded, color: _kGold, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── QR placeholder box (loading / error states) ───────────────────────────────
class _QRBox extends StatelessWidget {
  final Widget child;
  const _QRBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: 260,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kMaroon.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: child,
    );
  }
}
