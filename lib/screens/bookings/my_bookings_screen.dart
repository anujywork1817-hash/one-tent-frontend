import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/handcrafted.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kBgDeep = Color(0xFF0D0401); // near-black maroon (hero/appbar bg)
const Color _kMaroon = Color(0xFF4A1000); // deep maroon
const Color _kSurface = Color(0xFF1C0906); // card surface (dark)
const Color _kBorder = Color(0xFF3D1A0D); // subtle border
const Color _kGold = Color(0xFFD4891A); // primary accent
const Color _kGoldLight = Color(0xFFE8A93A); // lighter gold
const Color _kCream = Color(0xFFF5E6C8); // primary text on dark
const Color _kBodyBg = Color(0xFFF2EAE0); // light cream body background
const Color _kCardBg = Color(0xFFFFFFFF); // white cards on cream
const Color _kTextDark = Color(0xFF2C1A0E); // dark brown text on light bg
const Color _kTextMuted = Color(0xFF8A6A50); // muted brown
const Color _kGreen = Color(0xFF2E7D32);
const Color _kRed = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<TentProvider>().loadMyBookings());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TentProvider>();

    final active = prov.bookings.where((b) => b.status == 'confirmed').toList();
    final pending = prov.bookings.where((b) => b.status == 'pending').toList();
    final past = prov.bookings
        .where((b) => b.status == 'cancelled' || b.status == 'completed')
        .toList();

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: Column(
        children: [
          // ── Dark maroon hero header ────────────────────────────────────────
          _BookingsHeader(
              tabs: _tabs, active: active, pending: pending, past: past),
          // ── Cream body with tab content ────────────────────────────────────
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator(color: _kGold))
                : prov.error != null
                    ? _ErrorState(prov: prov)
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _BookingList(bookings: active),
                          _BookingList(bookings: pending),
                          _BookingList(bookings: past),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Dark Maroon Hero Header ────────────────────────────────────────────────────
class _BookingsHeader extends StatelessWidget {
  final TabController tabs;
  final List<TentBooking> active, pending, past;

  const _BookingsHeader({
    required this.tabs,
    required this.active,
    required this.pending,
    required this.past,
  });

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
        child: Column(
          children: [
            // App bar row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  // This screen doubles as the "Bookings" bottom-nav tab
                  // (nothing to pop back to) and as a screen pushed from
                  // Profile (something to pop back to) — canPop() tells them
                  // apart, so the button only appears, and only does
                  // something, when it actually can. An unconditional
                  // context.pop() here used to sit dead on the tab.
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: _kCream, size: 20),
                      onPressed: () => context.pop(),
                    )
                  else
                    const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'My Bookings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _kCream,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  // Gold temple icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: _kGold, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.temple_hindu, color: _kGold, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Custom tab bar on dark bg
            TabBar(
              controller: tabs,
              labelColor: _kGold,
              unselectedLabelColor: _kCream.withValues(alpha: 0.55),
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(color: _kGold, width: 2.5),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: [
                Tab(text: 'Active (${active.length})'),
                Tab(text: 'Pending (${pending.length})'),
                Tab(text: 'Past (${past.length})'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Booking List ───────────────────────────────────────────────────────────────
class _BookingList extends StatelessWidget {
  final List<TentBooking> bookings;
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    // The empty state is inside the RefreshIndicator on purpose: "no bookings
    // yet" is precisely when someone pulls to check for a new one.
    return RefreshIndicator(
      color: _kGold,
      backgroundColor: _kCardBg,
      onRefresh: () => context.read<TentProvider>().loadMyBookings(),
      child: bookings.isEmpty
          ? _empty()
          : ListView.builder(
              // Without this the pull is ignored whenever the list is too
              // short to scroll.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: bookings.length,
              itemBuilder: (_, i) =>
                  _BookingCard(booking: bookings[i], index: i),
            ),
    );
  }

  Widget _empty() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                ),
                child:
                    const Icon(Icons.inbox_outlined, size: 38, color: _kGold),
              ),
              const SizedBox(height: 16),
              const Text('No bookings here',
                  style: TextStyle(
                      color: _kTextMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text('Your bookings will appear here',
                  style: TextStyle(color: _kTextMuted, fontSize: 13)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Booking Card ───────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final TentBooking booking;
  final int index;
  const _BookingCard({required this.booking, this.index = 0});

  String _fmtDate(String raw) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Status colors — warm palette on cream bg
    final Color statusColor;
    final Color statusBg;
    switch (booking.status) {
      case 'confirmed':
        statusColor = _kGreen;
        statusBg = const Color(0xFFE8F5E9);
        break;
      case 'cancelled':
        statusColor = _kRed;
        statusBg = const Color(0xFFFFEBEE);
        break;
      case 'completed':
        statusColor = _kTextMuted;
        statusBg = const Color(0xFFEFEBE9);
        break;
      case 'pending':
        statusColor = _kGold;
        statusBg = const Color(0xFFFFF8E1);
        break;
      default:
        statusColor = _kTextMuted;
        statusBg = const Color(0xFFEFEBE9);
    }

    return GestureDetector(
      onTap: () =>
          context.push('/booking-detail/${booking.id}', extra: booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 2),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: handDrawnRadius(base: 16, seed: index),
          border: Border.all(color: _kGold.withValues(alpha: 0.18)),
          boxShadow: stickerShadow(_kMaroon.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // ── Card header bar (maroon accent) ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _kMaroon.withValues(alpha: 0.06),
                border: Border(
                    bottom: BorderSide(color: _kGold.withValues(alpha: 0.12))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Booking ref
                  Expanded(
                    child: Row(children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 14, color: _kGold),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          booking.bookingRefStr ?? booking.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _kTextDark,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                  // Status badge
                  Tilt(
                    degrees: 2.5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: handDrawnRadius(base: 6, seed: index),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                        boxShadow: stickerShadow(
                            statusColor.withValues(alpha: 0.15),
                            dx: 2,
                            dy: 2),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Card body ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 14, color: _kGold),
                    const SizedBox(width: 8),
                    Text(
                      '${_fmtDate(booking.checkInDate)}  →  ${_fmtDate(booking.checkOutDate)}',
                      style: const TextStyle(color: _kTextDark, fontSize: 13),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  // Nights / guests + price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.nights_stay, size: 14, color: _kGold),
                        const SizedBox(width: 8),
                        Text(
                          '${booking.nights} night(s)  •  ${booking.numGuests} guest(s)',
                          style:
                              const TextStyle(color: _kTextMuted, fontSize: 13),
                        ),
                      ]),
                      // Price in gold
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _kGold.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          '₹${booking.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: _kGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // QR code button (confirmed only)
                  if (booking.status == 'confirmed') ...[
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFEDE0D4), height: 1),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/booking-qr/${booking.id}',
                            extra: booking),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _kMaroon,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _kGold.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code, size: 15, color: _kGold),
                              SizedBox(width: 6),
                              Text('View QR Code',
                                  style: TextStyle(
                                      color: _kGold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final TentProvider prov;
  const _ErrorState({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _kRed.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.error_outline, size: 36, color: _kRed),
          ),
          const SizedBox(height: 16),
          Text(
            prov.error ?? 'Failed to load bookings',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kTextDark, fontSize: 14),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => prov.loadMyBookings(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _kMaroon,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGold.withValues(alpha: 0.6)),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: _kGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }
}
