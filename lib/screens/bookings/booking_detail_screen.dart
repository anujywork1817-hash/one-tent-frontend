import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/handcrafted.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kBgDeep = Color(0xFF0D0401);
const Color _kMaroon = Color(0xFF4A1000);
const Color _kGold = Color(0xFFD4891A);
const Color _kCream = Color(0xFFF5E6C8);
const Color _kBodyBg = Color(0xFFF2EAE0);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kTextDark = Color(0xFF2C1A0E);
const Color _kTextMuted = Color(0xFF8A6A50);
const Color _kDivider = Color(0xFFEDE0D4);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kRed = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

const _confirmedAmenities = [
  {'icon': Icons.bed_rounded, 'label': 'Ergonomic Bed'},
  {'icon': Icons.ac_unit_rounded, 'label': 'AC / Heating'},
  {'icon': Icons.wifi_rounded, 'label': 'WiFi & Charging'},
  {'icon': Icons.shower_rounded, 'label': 'Private Bathroom'},
  {'icon': Icons.lock_rounded, 'label': 'Smart Lock'},
  {'icon': Icons.cleaning_services_rounded, 'label': 'Daily Housekeeping'},
];

const _safetyPoints = [
  '24/7 Security Personnel on site',
  'CCTV Monitoring throughout campus',
  'Smart Lock with personal access code',
  'On-call Assistance anytime',
];

class BookingDetailScreen extends StatefulWidget {
  final TentBooking booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  /// Deliberately named `booking` so the rest of build() reads unchanged.
  /// Seeded from the record the list passed in, then replaced by whatever the
  /// server returns on refresh.
  late TentBooking booking = widget.booking;

  Future<void> _refresh() async {
    final fresh = await context.read<TentProvider>().fetchBooking(booking.id);
    if (fresh != null && mounted) {
      setState(() => booking = fresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, yyyy');
    final isConfirmed = booking.status == 'confirmed';
    final isPending = booking.status == 'pending';
    final isCancelled = booking.status == 'cancelled';

    // Status palette
    final Color statusColor = isConfirmed
        ? _kGreen
        : isCancelled
            ? _kRed
            : _kGold;
    final Color statusBg = isConfirmed
        ? const Color(0xFFE8F5E9)
        : isCancelled
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF8E1);

    DateTime? checkIn;
    DateTime? checkOut;
    try {
      checkIn = DateTime.parse(booking.checkInDate);
    } catch (_) {}
    try {
      checkOut = DateTime.parse(booking.checkOutDate);
    } catch (_) {}

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: Column(
        children: [
          // ── Dark maroon hero header ──────────────────────────────────
          _DetailHeader(
            isConfirmed: isConfirmed,
            onQrTap: () =>
                context.push('/booking-qr/${booking.id}', extra: booking),
          ),

          // ── Scrollable cream body ────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: _kGold,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status banner ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: handDrawnRadius(base: 12, seed: 2),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.35)),
                        boxShadow: stickerShadow(
                            statusColor.withValues(alpha: 0.1),
                            dx: 3,
                            dy: 3),
                      ),
                      child: Row(children: [
                        Icon(
                          isConfirmed
                              ? Icons.check_circle_rounded
                              : isCancelled
                                  ? Icons.cancel_rounded
                                  : Icons.access_time_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          booking.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Booking reference ──────────────────────────────
                    _sectionLabel('Booking Reference'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      seed: 1,
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _kMaroon,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.confirmation_number_outlined,
                              color: _kGold, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking.bookingRefStr ?? booking.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _kTextDark,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Tent info ──────────────────────────────────────
                    _sectionLabel('Tent'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      seed: 2,
                      child: Column(children: [
                        _detailRow('Name', booking.tentName ?? 'N/A'),
                        const WavyDivider(color: _kDivider),
                        _detailRow('Tent ID', booking.tentId),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Stay details ───────────────────────────────────
                    _sectionLabel('Stay Details'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      seed: 3,
                      child: Column(children: [
                        _detailRow(
                            'Check-in',
                            checkIn != null
                                ? fmt.format(checkIn)
                                : booking.checkInDate),
                        const WavyDivider(color: _kDivider),
                        _detailRow(
                            'Check-out',
                            checkOut != null
                                ? fmt.format(checkOut)
                                : booking.checkOutDate),
                        const WavyDivider(color: _kDivider),
                        _detailRow('Nights', '${booking.nights}'),
                        if (booking.roomCount > 1) ...[
                          const WavyDivider(color: _kDivider),
                          _detailRow('Rooms', '${booking.roomCount}'),
                        ],
                        const WavyDivider(color: _kDivider),
                        _detailRow('Guests', '${booking.numGuests}'),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Other guests ───────────────────────────────────
                    if (booking.additionalGuests.isNotEmpty) ...[
                      _sectionLabel('Other Guests'),
                      const SizedBox(height: 8),
                      _InfoCard(
                        seed: 4,
                        child: Column(
                          children: [
                            for (var i = 0;
                                i < booking.additionalGuests.length;
                                i++) ...[
                              if (i > 0) const WavyDivider(color: _kDivider),
                              _detailRow(
                                booking.additionalGuests[i].name,
                                booking.additionalGuests[i].phone,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Payment ────────────────────────────────────────
                    _sectionLabel('Payment'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      seed: 5,
                      child: Column(
                        children: [
                          if (booking.gstRate > 0) ...[
                            _detailRow('Room Charge',
                                '₹${booking.baseAmount.toStringAsFixed(2)}'),
                            const WavyDivider(color: _kDivider),
                            _detailRow(
                                'CGST (${booking.gstRate.toStringAsFixed(0)}%)',
                                '₹${booking.cgstAmount.toStringAsFixed(2)}'),
                            const WavyDivider(color: _kDivider),
                            _detailRow(
                                'SGST (${booking.gstRate.toStringAsFixed(0)}%)',
                                '₹${booking.sgstAmount.toStringAsFixed(2)}'),
                            const WavyDivider(color: _kDivider),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount',
                                  style: TextStyle(
                                      color: _kTextMuted, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _kGold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _kGold.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '₹${booking.amountDue.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: _kGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (booking.displayCurrency != 'INR' &&
                              booking.foreignAmount != null) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '≈ ${booking.foreignAmount!.toStringAsFixed(2)} ${booking.displayCurrency}',
                                style: const TextStyle(
                                    color: _kTextMuted,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Refund status (cancelled bookings) ─────────────
                    if (isCancelled) ...[
                      _RefundStatusCard(bookingId: booking.id),
                    ],

                    // ── Confirmed-only sections ────────────────────────
                    if (isConfirmed) ...[
                      // Amenities grid
                      _sectionLabel('Your Capsule Includes'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.07),
                          borderRadius: handDrawnRadius(base: 14, seed: 7),
                          border:
                              Border.all(color: _kGold.withValues(alpha: 0.22)),
                        ),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 3.5,
                          children: _confirmedAmenities
                              .asMap()
                              .entries
                              .map((entry) => Row(children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _kMaroon,
                                        borderRadius: handDrawnRadius(
                                            base: 7, seed: entry.key),
                                      ),
                                      child: Icon(
                                          entry.value['icon'] as IconData,
                                          size: 13,
                                          color: _kGold),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                          entry.value['label'] as String,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _kTextMuted,
                                              fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ]))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Safety info
                      _sectionLabel('Safe, Secure & Worry-Free'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        seed: 6,
                        child: Column(
                          children: _safetyPoints
                              .map((point) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: _kGreen.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: _kGreen.withValues(
                                                  alpha: 0.3)),
                                        ),
                                        child: Icon(Icons.check_rounded,
                                            size: 12, color: _kGreen),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(point,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _kTextDark))),
                                    ]),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Eco note
                      Tilt(
                        degrees: -1.4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.07),
                            borderRadius: handDrawnRadius(base: 12, seed: 8),
                            border: Border.all(
                                color: _kGreen.withValues(alpha: 0.2)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.eco_rounded,
                                size: 18, color: _kGreen),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Solar powered · Water saving · Low waste living',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _kGreen,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // QR button
                      _ActionButton(
                        label: 'View QR Code',
                        icon: Icons.qr_code_rounded,
                        onTap: () => context.push('/booking-qr/${booking.id}',
                            extra: booking),
                      ),
                      const SizedBox(height: 12),

                      // Review — in-app now instead of opening an email
                      // draft, and visible to other guests on this tent's
                      // detail page while they browse or book.
                      _ActionButton(
                        label: 'Rate & Review This Stay',
                        icon: Icons.star_outline_rounded,
                        onTap: () => context.push('/review', extra: {
                          'bookingId': booking.id,
                          'tentName': booking.tentName ?? 'Your stay',
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Cancel button (pending or confirmed) ───────────
                    if (isPending || isConfirmed) ...[
                      _CancelButton(booking: booking, isConfirmed: isConfirmed),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Top-level so the other widgets in this file can use them: they are pure
// layout helpers with no state, and the screen is now a StatefulWidget.
Widget _sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: _kTextMuted,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );

Widget _detailRow(String label, String value, {bool bold = false}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _kTextMuted, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: bold ? _kGold : _kTextDark,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 16 : 13,
            ),
          ),
        ),
      ],
    );

// ── Dark Maroon Hero Header ────────────────────────────────────────────────────
class _DetailHeader extends StatelessWidget {
  final bool isConfirmed;
  final VoidCallback onQrTap;
  const _DetailHeader({required this.isConfirmed, required this.onQrTap});

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
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text(
                  'Booking Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kCream,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (isConfirmed)
                GestureDetector(
                  onTap: onQrTap,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: _kGold, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_rounded,
                        color: _kGold, size: 18),
                  ),
                )
              else
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border.all(color: _kGold, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.temple_hindu, color: _kGold, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable white info card ───────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Widget child;
  final int seed;
  const _InfoCard({required this.child, this.seed = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: handDrawnRadius(base: 14, seed: seed),
        border: Border.all(color: _kGold.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
              color: _kMaroon.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

// ── Primary Action Button ──────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _kMaroon,
          borderRadius: handDrawnRadius(base: 14, seed: 10),
          border: Border.all(color: _kGold.withValues(alpha: 0.6)),
          boxShadow: stickerShadow(_kMaroon.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _kGold, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  color: _kCream,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Cancel Button ──────────────────────────────────────────────────────────────
class _CancelButton extends StatefulWidget {
  final TentBooking booking;
  final bool isConfirmed;
  const _CancelButton({required this.booking, required this.isConfirmed});

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _isLoading = false;
  String _busyLabel = 'Cancelling...';

  Future<void> _cancel() async {
    final prov = context.read<TentProvider>();

    // Ask the backend exactly what this cancellation refunds before we show
    // the guest any numbers — never promise money the policy will not return.
    setState(() {
      _isLoading = true;
      _busyLabel = 'Checking refund...';
    });
    final preview = await prov.refundPreview(widget.booking.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (preview == null) {
      _snack(prov.error ?? 'Could not load refund details', _kRed);
      return;
    }
    if (preview['cancellable'] == false) {
      _snack(
          preview['reason']?.toString() ?? 'This booking cannot be cancelled',
          _kRed);
      return;
    }

    final paidOnline = preview['paid_online'] == true;
    final eligible = preview['refund_eligible'] == true;
    final refundAmount = (preview['refund_amount'] as num?)?.toDouble() ?? 0;
    final fee = (preview['cancellation_fee'] as num?)?.toDouble() ?? 0;
    final amountPaid = (preview['amount_paid'] as num?)?.toDouble() ?? 0;
    final daysMin = (preview['expected_days_min'] as num?)?.toInt() ?? 3;
    final daysMax = (preview['expected_days_max'] as num?)?.toInt() ?? 4;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking',
            style: TextStyle(color: _kTextDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this booking? '
              'This cannot be undone.',
              style: TextStyle(color: _kTextMuted, fontSize: 13),
            ),
            if (paidOnline && eligible) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REFUND SUMMARY',
                        style: TextStyle(
                          color: _kGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        )),
                    const SizedBox(height: 10),
                    _amountRow('Amount paid', amountPaid),
                    if (fee > 0) ...[
                      const SizedBox(height: 6),
                      _amountRow('Cancellation charge', -fee),
                    ],
                    const WavyDivider(color: _kDivider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('You get back',
                            style: TextStyle(
                                color: _kTextDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text('₹${refundAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: _kGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: _kGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'You will receive the money in your original '
                            'payment method within $daysMin to $daysMax '
                            'working days.',
                            style: const TextStyle(
                                color: _kTextMuted,
                                fontSize: 11.5,
                                height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (paidOnline && !eligible) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 15, color: _kRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        preview['reason']?.toString() ??
                            'No amount is refundable under our cancellation policy.',
                        style: const TextStyle(
                            color: _kRed, fontSize: 11.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Booking',
                style: TextStyle(color: _kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: Text(
                paidOnline && eligible ? 'Cancel & Refund' : 'Cancel Booking',
                style:
                    const TextStyle(color: _kRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _busyLabel = 'Cancelling...';
    });
    final result = await prov.cancelBooking(widget.booking.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (prov.error != null) {
      _snack(prov.error!, _kRed);
      return;
    }

    // Refunds now go through an admin approval step rather than being sent to
    // Razorpay the instant a guest cancels — so cancellation never means
    // "money is already on its way," only that a request was raised.
    final awaitingApproval = result?['refund_pending_approval'] == true;
    final paidBack = (result?['refund_amount'] as num?)?.toStringAsFixed(0);

    _snack(
      awaitingApproval
          ? 'Booking cancelled. Your refund request of ₹$paidBack has been '
              'submitted for approval.'
          : 'Booking cancelled successfully',
      _kMaroon,
    );
    context.pop();
  }

  void _snack(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // bg is always a dark brand color (maroon/red) here — without an
        // explicit text color this fell back to the default near-black
        // text, which is unreadable against it. Same failure mode as the
        // earlier back-button and passport-upload dark-on-dark fixes.
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static Widget _amountRow(String label, double value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _kTextMuted, fontSize: 12)),
          Text(
            '${value < 0 ? '− ' : ''}₹${value.abs().toStringAsFixed(0)}',
            style: TextStyle(
              color: value < 0 ? _kRed : _kTextDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _cancel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: handDrawnRadius(base: 14, seed: 11),
          border: Border.all(color: _kRed.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kRed),
              )
            else
              const Icon(Icons.cancel_outlined, color: _kRed, size: 18),
            const SizedBox(width: 8),
            Text(
              _isLoading ? _busyLabel : 'Cancel Booking',
              style: const TextStyle(
                color: _kRed,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Refund Status Card ─────────────────────────────────────────────────────────
/// Shows the refund raised against a cancelled booking. Renders nothing when
/// the booking was never paid online (there is no refund to report).
class _RefundStatusCard extends StatefulWidget {
  final String bookingId;
  const _RefundStatusCard({required this.bookingId});

  @override
  State<_RefundStatusCard> createState() => _RefundStatusCardState();
}

class _RefundStatusCardState extends State<_RefundStatusCard> {
  Map<String, dynamic>? _refund;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data =
        await context.read<TentProvider>().bookingRefund(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _refund = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kGold),
          ),
        ),
      );
    }

    final r = _refund;
    if (r == null) return const SizedBox.shrink();

    final status = (r['status'] ?? 'pending').toString();
    final amount = (r['amount'] as num?)?.toDouble() ?? 0;
    final fee = (r['cancellation_fee'] as num?)?.toDouble() ?? 0;
    final hasGatewayRef =
        r['razorpay_refund_id']?.toString().isNotEmpty ?? false;
    final reference = hasGatewayRef
        ? r['razorpay_refund_id'].toString()
        : r['id']?.toString() ?? '';
    // Server-computed via refundMessage() in internal/refund/service.go — the
    // single source of truth for wording across every status combination
    // (awaiting approval / admin-declined / gateway-failed / in-flight /
    // completed), so it isn't duplicated and re-derived here.
    final message = r['message']?.toString() ?? '';

    final isProcessed = status == 'processed';
    final isFailed = status == 'failed';
    // Pending with no gateway id yet means it was never submitted — it's
    // sitting in the admin queue, distinct from a pending refund already
    // in flight with the gateway.
    final isAwaitingApproval = status == 'pending' && !hasGatewayRef;
    final isAdminDeclined = isFailed &&
        (r['failure_reason']?.toString().startsWith('Declined by admin') ??
            false);

    final Color accent = isProcessed
        ? _kGreen
        : isFailed
            ? _kRed
            : isAwaitingApproval
                ? _kGold
                : _kGold;
    final IconData icon = isProcessed
        ? Icons.check_circle_rounded
        : isFailed
            ? Icons.error_outline_rounded
            : isAwaitingApproval
                ? Icons.hourglass_top_rounded
                : Icons.schedule_rounded;
    final String heading = isProcessed
        ? 'Refund Completed'
        : isAdminDeclined
            ? 'Refund Request Declined'
            : isFailed
                ? 'Refund Needs Attention'
                : isAwaitingApproval
                    ? 'Awaiting Approval'
                    : 'Refund In Progress';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Refund'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: handDrawnRadius(base: 14, seed: 12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 10),
                Text(
                  heading,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                    color: _kTextMuted, fontSize: 12, height: 1.4),
              ),
              const WavyDivider(color: _kDivider, height: 22),
              if (fee > 0) ...[
                _detailRow('Cancellation charge', '₹${fee.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
              ],
              _detailRow('Status', status.toUpperCase()),
              if (reference.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow('Reference', reference),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
