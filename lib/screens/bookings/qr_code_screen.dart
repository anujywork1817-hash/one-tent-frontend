import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kMaroon = Color(0xFF4A1000);
const Color _kGold = Color(0xFFD4891A);
const Color _kBodyBg = Color(0xFFFFFFFF);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kTextDark = Color(0xFF2D0F05);
const Color _kTextMuted = Color(0xFF7A4A30);
const Color _kBorder = Color(0xFFDDD0C4);
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
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _kMaroon.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      const Icon(Icons.confirmation_number_outlined,
                          color: _kGold, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking #${b.bookingRef}',
                              style: const TextStyle(
                                color: _kTextDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${fmt.format(b.checkInDateTime)} → ${fmt.format(b.checkOutDateTime)}',
                              style: const TextStyle(
                                  color: _kTextMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: b.status == 'confirmed'
                              ? const Color(0xFFE8F5E9)
                              : _kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.status.toUpperCase(),
                          style: TextStyle(
                              color: b.status == 'confirmed'
                                  ? const Color(0xFF2E7D32)
                                  : _kGold,
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
                                color: _kGold,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Retry',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Actual QR code — plain white card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _kMaroon.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: _qrContent ?? b.id,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square, color: _kTextDark),
                            dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: _kMaroon),
                          ),
                          const SizedBox(height: 12),
                          Text('One Tent',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: _kGold.withValues(alpha: 0.85),
                              )),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Instruction text ───────────────────────────────
                  if (_qrContent != null) ...[
                    const Text(
                      'Show this QR code at check-in',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                      textAlign: TextAlign.center,
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
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _kMaroon.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(children: [
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
                      const Divider(color: _kBorder, height: 20),
                      _detailRow('Ref', b.bookingRef),
                      const Divider(color: _kBorder, height: 20),
                      _detailRow('Check-in', fmt.format(b.checkInDateTime)),
                      const Divider(color: _kBorder, height: 20),
                      _detailRow('Check-out', fmt.format(b.checkOutDateTime)),
                      const Divider(color: _kBorder, height: 20),
                      _detailRow('Guests', '${b.numGuests}'),
                      const Divider(color: _kBorder, height: 20),
                      if (b.gstRate > 0) ...[
                        _detailRow('Room Charge',
                            '₹${b.baseAmount.toStringAsFixed(2)}'),
                        const Divider(color: _kBorder, height: 20),
                        _detailRow('CGST (${b.gstRate.toStringAsFixed(0)}%)',
                            '₹${b.cgstAmount.toStringAsFixed(2)}'),
                        const Divider(color: _kBorder, height: 20),
                        _detailRow('SGST (${b.gstRate.toStringAsFixed(0)}%)',
                            '₹${b.sgstAmount.toStringAsFixed(2)}'),
                        const Divider(color: _kBorder, height: 20),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Paid',
                                style:
                                    TextStyle(color: _kTextMuted, fontSize: 13)),
                            Text(
                              '₹${b.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: _kTextDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
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

                  if (_otherGuests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kMaroon.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
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
                          const Divider(color: _kBorder, height: 20),
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

// ── Header — same plain white chrome as every other screen ─────────────────
class _QRHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: _kTextDark, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  'Check-in QR Code',
                  style: TextStyle(
                    color: _kTextDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
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
