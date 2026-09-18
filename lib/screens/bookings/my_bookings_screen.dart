import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';

// ─── One Tent Design Tokens — same brand palette as every other screen ────
const Color _kMaroon = Color(0xFF4A1000);
const Color _kGold = Color(0xFFD4891A);
const Color _kBorder = Color(0xFFDDD0C4);
const Color _kBodyBg = Color(0xFFFFFFFF);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kTextDark = Color(0xFF2D0F05);
const Color _kTextMuted = Color(0xFF7A4A30);
const Color _kTextLight = Color(0xFFA07050);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kRed = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabs;
  Timer? _pollTimer;

  // Polling interval for the quiet background refresh — short enough that a
  // new booking (or a status change like a payment confirming, or a refund
  // going through) shows up on its own without the guest having to know to
  // pull down, but not so tight it hammers the API.
  static const _pollInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<TentProvider>().loadMyBookings());
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      context.read<TentProvider>().refreshMyBookingsQuietly();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause polling while the app is backgrounded (nothing to show anyone,
    // just wasted requests) and catch up with one immediate refresh plus a
    // fresh timer the moment it's foregrounded again.
    if (state == AppLifecycleState.resumed) {
      context.read<TentProvider>().refreshMyBookingsQuietly();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
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

// ── Header — same plain white chrome as every other screen ─────────────────
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
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar row
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
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
                      icon: const Icon(Icons.chevron_left,
                          color: _kTextDark, size: 28),
                      onPressed: () => context.pop(),
                    )
                  else
                    const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'My Bookings',
                      style: TextStyle(
                        color: _kTextDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  // Instant on-demand refresh — the quiet poll already keeps
                  // this list current on its own, but this is the "check
                  // right now" button for right after paying.
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: _kTextDark, size: 22),
                    onPressed: () =>
                        context.read<TentProvider>().loadMyBookings(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tab bar
            TabBar(
              controller: tabs,
              labelColor: _kGold,
              unselectedLabelColor: _kTextMuted,
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
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _kMaroon.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking ref + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.bookingRefStr ?? booking.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: _kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date range
            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: _kTextLight),
              const SizedBox(width: 8),
              Text(
                '${_fmtDate(booking.checkInDate)}  →  ${_fmtDate(booking.checkOutDate)}',
                style: const TextStyle(color: _kTextDark, fontSize: 13),
              ),
            ]),
            const SizedBox(height: 6),

            // Nights / guests + price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${booking.nights} night${booking.nights == 1 ? '' : 's'} · ${booking.numGuests} guest${booking.numGuests == 1 ? '' : 's'}',
                  style: const TextStyle(color: _kTextMuted, fontSize: 13),
                ),
                Text(
                  '₹${booking.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _kTextDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            // QR code button (confirmed only)
            if (booking.status == 'confirmed') ...[
              const SizedBox(height: 12),
              const Divider(color: _kBorder, height: 1),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () =>
                      context.push('/booking-qr/${booking.id}', extra: booking),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code, size: 15, color: Colors.white),
                        SizedBox(width: 6),
                        Text('View QR Code',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
                color: _kGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }
}
