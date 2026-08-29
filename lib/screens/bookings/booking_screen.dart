import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_utils.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/tap_scale.dart';
import '../../widgets/handcrafted.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kBgDeep = Color(0xFF0D0401);
const Color _kMaroon = Color(0xFF4A1000);
const Color _kSurface = Color(0xFF1C0906);
const Color _kBorder = Color(0xFF3D1A0D);
const Color _kGold = Color(0xFFD4891A);
const Color _kGoldLight = Color(0xFFE8A93A);
const Color _kCream = Color(0xFFF5E6C8);
const Color _kBodyBg = Color(0xFFF2EAE0);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kTextDark = Color(0xFF2C1A0E);
const Color _kTextMuted = Color(0xFF8A6A50);
const Color _kDivider = Color(0xFFEDE0D4);
const Color _kGreen = Color(0xFF2E7D32);
// ─────────────────────────────────────────────────────────────────────────────

const _quickAmenities = [
  {'icon': Icons.bed_rounded, 'label': 'Ergonomic Bed'},
  {'icon': Icons.ac_unit_rounded, 'label': 'AC / Heating'},
  {'icon': Icons.wifi_rounded, 'label': 'High-Speed WiFi'},
  {'icon': Icons.shower_rounded, 'label': 'Private Bathroom'},
  {'icon': Icons.lock_rounded, 'label': 'Smart Lock'},
  {'icon': Icons.solar_power_rounded, 'label': 'Solar Powered'},
  {'icon': Icons.cleaning_services_rounded, 'label': 'Housekeeping'},
  {'icon': Icons.support_agent_rounded, 'label': 'On-call Assist'},
];

const _trustBadges = [
  {'icon': Icons.security_rounded, 'label': '24/7 Security'},
  {'icon': Icons.eco_rounded, 'label': 'Eco-Friendly'},
  {'icon': Icons.verified_rounded, 'label': 'Verified Capsule'},
];

class BookingScreen extends StatefulWidget {
  final CapsuleTent tent;
  const BookingScreen({super.key, required this.tent});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _rooms = 1;
  int _adults = 1;
  int _children = 0;
  bool _isLoading = false;
  String _selectedCurrency = 'INR';

  /// Total headcount across all rooms — what the backend's "guests" column
  /// and the additional-guest roster are keyed on.
  int get _numGuests => _adults + _children;

  // One name+phone controller pair per additional guest (numGuests - 1).
  final List<TextEditingController> _guestNameCtrls = [];
  final List<TextEditingController> _guestPhoneCtrls = [];

  @override
  void initState() {
    super.initState();
    // Foreign-currency preview only — the actual Razorpay charge always
    // stays INR regardless of what's picked here. Defaults to whatever the
    // guest's own registered country maps to (US -> USD, UK -> GBP, a
    // eurozone country -> EUR, everything else including India -> INR) so
    // most guests never have to touch the picker below at all — it's still
    // there in case someone wants to preview a different currency.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TentProvider>().loadExchangeRates();
      final country = context.read<AuthProvider>().visitor?.country;
      final defaultCurrency = CurrencyUtils.currencyForCountry(country);
      if (defaultCurrency != 'INR' && mounted) {
        setState(() => _selectedCurrency = defaultCurrency);
      }
    });
  }

  void _syncGuestControllers() {
    final want = _numGuests - 1;
    while (_guestNameCtrls.length < want) {
      _guestNameCtrls.add(TextEditingController());
      _guestPhoneCtrls.add(TextEditingController());
    }
    while (_guestNameCtrls.length > want) {
      _guestNameCtrls.removeLast().dispose();
      _guestPhoneCtrls.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final c in _guestNameCtrls) {
      c.dispose();
    }
    for (final c in _guestPhoneCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  /// Nights between the two chosen dates. 0 until both are picked.
  int get _duration {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  /// Nightly rate × nights × rooms, which is exactly how the server bills it
  /// (nights × price_per_day, once per room). The old tiered priceFor() only
  /// lined up with the fixed 1/3/7/15/30 chips — for an arbitrary range it
  /// would return, say, the 3-day price for a 5-night stay. This is the
  /// room charge before tax, for every room combined.
  double get _baseAmount => widget.tent.price1Day * _duration * _rooms;

  /// India's hotel-accommodation GST slab: under ₹7,500/night is 12%,
  /// ₹7,500/night or above is 18% — checked against the nightly rate, not
  /// the total stay cost. Mirrors gstRateForTent() on the backend, which is
  /// the actual source of truth once the booking is created; this is only a
  /// preview so the guest sees the real total before paying.
  double get _gstRate => widget.tent.price1Day < 7500 ? 12 : 18;
  double get _cgstAmount => _baseAmount * _gstRate / 100 / 2;
  double get _sgstAmount => _baseAmount * _gstRate / 100 / 2;
  double get _totalPrice => _baseAmount + _cgstAmount + _sgstAmount;

  /// The total converted to _selectedCurrency using today's rate, or null
  /// while on INR or before rates have loaded. Preview only — see
  /// TentRepository.exchangeRates.
  double? _foreignTotal(Map<String, double>? rates) {
    if (_selectedCurrency == 'INR' || rates == null) return null;
    final rate = rates[_selectedCurrency];
    if (rate == null || rate <= 0) return null;
    return _totalPrice / rate;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, yyyy');
    final checkOutFmt =
        _checkOutDate != null ? fmt.format(_checkOutDate!) : '--';
    final rates = context.watch<TentProvider>().exchangeRates;
    final foreignTotal = _foreignTotal(rates);

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: Column(
        children: [
          // ── Dark maroon hero header ──────────────────────────────────
          _BookingHeader(
              tentName: widget.tent.name, tentType: widget.tent.tentType),

          // ── Scrollable cream body ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tent info card ─────────────────────────────────
                  _TentInfoCard(tent: widget.tent),
                  const SizedBox(height: 14),

                  // ── Included amenities ─────────────────────────────
                  _AmenitiesCard(),
                  const SizedBox(height: 22),

                  // ── Check-in date ──────────────────────────────────
                  _sectionLabel('Check-in Date'),
                  const SizedBox(height: 8),
                  _DatePickerField(
                    date: _checkInDate,
                    fmt: fmt,
                    onTap: _pickCheckIn,
                  ),
                  const SizedBox(height: 20),

                  // ── Check-out date ─────────────────────────────────
                  _sectionLabel('Check-out Date'),
                  const SizedBox(height: 8),
                  _DatePickerField(
                    date: _checkOutDate,
                    fmt: fmt,
                    onTap: _pickCheckOut,
                    hint: _checkInDate == null
                        ? 'Choose a check-in date first'
                        : 'Select check-out date',
                  ),
                  if (_duration > 0) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.nights_stay_rounded,
                          size: 14, color: _kGold),
                      const SizedBox(width: 6),
                      Text(
                        '$_duration night${_duration == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: _kTextMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 20),

                  // ── Rooms & Guests ──────────────────────────────────
                  _sectionLabel('Rooms & Guests'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openRoomsGuestsSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kDivider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _kMaroon,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.meeting_room_outlined,
                                color: _kGold, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$_rooms Room${_rooms == 1 ? '' : 's'} · '
                              '$_adults Adult${_adults == 1 ? '' : 's'}'
                              '${_children > 0 ? ' · $_children Child${_children == 1 ? '' : 'ren'}' : ''}',
                              style: const TextStyle(
                                  color: _kTextDark, fontSize: 14),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: _kTextMuted.withValues(alpha: 0.5),
                              size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Currency preview ────────────────────────────────
                  _sectionLabel('View Price In'),
                  const SizedBox(height: 8),
                  _CurrencyPicker(
                    selected: _selectedCurrency,
                    available: rates?.keys.toList() ?? const [],
                    onSelect: (cur) => setState(() => _selectedCurrency = cur),
                  ),
                  const SizedBox(height: 22),

                  // ── Other guests' details ───────────────────────────
                  if (_numGuests > 1) ...[
                    _sectionLabel('Other Guests\' Details'),
                    const SizedBox(height: 8),
                    _OtherGuestsForm(
                      nameCtrls: _guestNameCtrls,
                      phoneCtrls: _guestPhoneCtrls,
                    ),
                    const SizedBox(height: 22),
                  ],

                  // ── Summary card ───────────────────────────────────
                  _SummaryCard(
                    checkIn:
                        _checkInDate != null ? fmt.format(_checkInDate!) : '--',
                    checkOut: checkOutFmt,
                    duration: _duration,
                    rooms: _rooms,
                    guests: _numGuests,
                    baseAmount: _baseAmount,
                    gstRate: _gstRate,
                    cgstAmount: _cgstAmount,
                    sgstAmount: _sgstAmount,
                    total: _totalPrice,
                    foreignCurrency:
                        _selectedCurrency == 'INR' ? null : _selectedCurrency,
                    foreignTotal: foreignTotal,
                  ),
                  const SizedBox(height: 18),

                  // ── Trust badges ───────────────────────────────────
                  Row(
                    children: _trustBadges
                        .asMap()
                        .entries
                        .map((entry) => Expanded(
                              child: Tilt(
                                seed: entry.key,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _kCardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _kDivider),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kMaroon.withValues(alpha: 0.05),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Column(children: [
                                    Icon(entry.value['icon'] as IconData,
                                        size: 20, color: _kGold),
                                    const SizedBox(height: 5),
                                    Text(entry.value['label'] as String,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: _kTextMuted,
                                            fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 22),

                  // ── Proceed button ─────────────────────────────────
                  _ProceedButton(
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _confirm,
                  ),

                  // ── Eco note ───────────────────────────────────────
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco_rounded, size: 13, color: _kGreen),
                      const SizedBox(width: 5),
                      Text(
                        'Solar powered · Water saving · Low waste living',
                        style: TextStyle(
                          fontSize: 11,
                          color: _kTextMuted.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: _kTextDark,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );

  Future<DateTime?> _showKumbhDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kMaroon,
            onPrimary: _kCream,
            onSurface: _kTextDark,
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final picked = await _showKumbhDatePicker(
      initialDate: _checkInDate ?? now,
      firstDate: now,
    );
    if (picked == null) return;
    setState(() {
      _checkInDate = picked;
      // A check-out on or before the new check-in no longer makes sense —
      // clear it rather than silently producing a negative or zero stay.
      if (_checkOutDate != null && !_checkOutDate!.isAfter(picked)) {
        _checkOutDate = null;
      }
    });
  }

  Future<void> _openRoomsGuestsSheet() async {
    final result = await showModalBottomSheet<_RoomsGuestsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomsGuestsSheet(
        initialRooms: _rooms,
        initialAdults: _adults,
        initialChildren: _children,
        occupancyPerRoom: widget.tent.maxOccupancy,
      ),
    );
    if (result == null) return;
    setState(() {
      _rooms = result.rooms;
      _adults = result.adults;
      _children = result.children;
      _syncGuestControllers();
    });
  }

  Future<void> _pickCheckOut() async {
    if (_checkInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a check-in date first'),
          backgroundColor: _kMaroon,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final earliestCheckOut = _checkInDate!.add(const Duration(days: 1));
    final picked = await _showKumbhDatePicker(
      initialDate: _checkOutDate ?? earliestCheckOut,
      firstDate: earliestCheckOut,
    );
    if (picked != null) setState(() => _checkOutDate = picked);
  }

  Future<void> _confirm() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_checkInDate == null
              ? 'Please select a check-in date'
              : 'Please select a check-out date'),
          backgroundColor: _kMaroon,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final additionalGuests = <AdditionalGuest>[];
    for (var i = 0; i < _guestNameCtrls.length; i++) {
      final name = _guestNameCtrls[i].text.trim();
      final phone = _guestPhoneCtrls[i].text.trim();
      if (name.isEmpty || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter name and phone for guest ${i + 2}'),
            backgroundColor: _kMaroon,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
      additionalGuests.add(AdditionalGuest(name: name, phone: phone));
    }

    setState(() => _isLoading = true);

    final tentProv = context.read<TentProvider>();

    final booking = await tentProv.createBooking(
      tentId: widget.tent.id,
      checkInDate: DateFormat('yyyy-MM-dd').format(_checkInDate!),
      duration: _duration,
      numGuests: _numGuests,
      additionalGuests: additionalGuests,
      currency: _selectedCurrency,
      roomCount: _rooms,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (booking == null) {
      final errMsg = tentProv.error ?? 'Booking failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: const Color(0xFFC0392B),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    context.push('/payment', extra: booking);
  }
}

// ── Dark Maroon Hero Header ────────────────────────────────────────────────────
class _BookingHeader extends StatelessWidget {
  final String tentName;
  final String tentType;
  const _BookingHeader({required this.tentName, required this.tentType});

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
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Book Your Stay',
                      style: TextStyle(
                        color: _kCream,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      tentName,
                      style: TextStyle(
                        color: _kCream.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Gold temple icon badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: _kGold, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.temple_hindu, color: _kGold, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tent Info Card ─────────────────────────────────────────────────────────────
class _TentInfoCard extends StatelessWidget {
  final CapsuleTent tent;
  const _TentInfoCard({required this.tent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: _kMaroon.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kMaroon,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.cabin, color: _kGold, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tent.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _kTextDark)),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tent.tentType.toUpperCase(),
                    style: const TextStyle(
                        color: _kGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 12, color: _kTextMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(tent.location,
                        style:
                            const TextStyle(color: _kTextMuted, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Amenities Card ─────────────────────────────────────────────────────────────
class _AmenitiesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: _kGold),
            const SizedBox(width: 6),
            const Text(
              'Included with every capsule',
              style: TextStyle(
                  color: _kTextDark, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _quickAmenities
                .map((a) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a['icon'] as IconData, size: 13, color: _kGold),
                        const SizedBox(width: 4),
                        Text(a['label'] as String,
                            style: const TextStyle(
                                fontSize: 11,
                                color: _kTextMuted,
                                fontWeight: FontWeight.w500)),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Date Picker Field ──────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final DateFormat fmt;
  final VoidCallback onTap;
  final String hint;
  const _DatePickerField({
    required this.date,
    required this.fmt,
    required this.onTap,
    this.hint = 'Select check-in date',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? _kGold.withValues(alpha: 0.5) : _kDivider,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _kMaroon,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today, color: _kGold, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              date != null ? fmt.format(date!) : hint,
              style: TextStyle(
                color: date != null ? _kTextDark : _kTextMuted,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: _kTextMuted.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Currency Picker ─────────────────────────────────────────────────────────────
// Preview only — the actual Razorpay charge always stays INR regardless of
// what's picked here. "Available" comes from /exchange-rates; while it's
// still loading, only INR shows and the row is effectively a no-op.
class _CurrencyPicker extends StatelessWidget {
  final String selected;
  final List<String> available;
  final ValueChanged<String> onSelect;
  const _CurrencyPicker({
    required this.selected,
    required this.available,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final currencies = ['INR', ...available];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: currencies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cur = currencies[i];
          final isSelected = cur == selected;
          return GestureDetector(
            onTap: () => onSelect(cur),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _kGold : _kCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? _kGold : _kDivider, width: 1.2),
              ),
              child: Text(
                cur,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _kTextMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


// ── Other Guests Form ──────────────────────────────────────────────────────────
class _OtherGuestsForm extends StatelessWidget {
  final List<TextEditingController> nameCtrls;
  final List<TextEditingController> phoneCtrls;
  const _OtherGuestsForm({required this.nameCtrls, required this.phoneCtrls});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(nameCtrls.length, (i) {
        return Container(
          margin: EdgeInsets.only(bottom: i == nameCtrls.length - 1 ? 0 : 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guest ${i + 2}',
                style: const TextStyle(
                  color: _kTextDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrls[i],
                style: const TextStyle(color: _kTextDark, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Full name',
                  hintStyle: const TextStyle(color: _kTextMuted, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.person_outline, color: _kGold, size: 18),
                  filled: true,
                  fillColor: _kBodyBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrls[i],
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: _kTextDark, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Phone number',
                  hintStyle: const TextStyle(color: _kTextMuted, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.phone_outlined, color: _kGold, size: 18),
                  filled: true,
                  fillColor: _kBodyBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Summary Card ───────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String checkIn, checkOut;
  final int duration, guests, rooms;
  final double baseAmount, gstRate, cgstAmount, sgstAmount, total;
  final String? foreignCurrency;
  final double? foreignTotal;
  const _SummaryCard({
    required this.checkIn,
    required this.checkOut,
    required this.duration,
    required this.rooms,
    required this.guests,
    required this.baseAmount,
    required this.gstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.total,
    this.foreignCurrency,
    this.foreignTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: handDrawnRadius(base: 16, seed: 5),
        border: Border.all(color: _kGold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: _kMaroon.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          const PaperGrain(color: _kMaroon, opacity: 0.035),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 16, color: _kGold),
                  const SizedBox(width: 8),
                  const Text('Booking Summary',
                      style: TextStyle(
                          color: _kTextDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const Spacer(),
                  Tilt(
                    degrees: -3,
                    child: Text('all set?',
                        style: AppFonts.handwritten(
                            fontSize: 14, color: _kTextMuted)),
                  ),
                ]),
                const SizedBox(height: 10),
                const WavyDivider(color: _kDivider),
                const SizedBox(height: 10),
                _row('Check-in', checkIn),
                _row('Check-out', checkOut),
                _row('Duration', '$duration day(s)'),
                _row('Rooms', '$rooms'),
                _row('Guests', '$guests'),
                const SizedBox(height: 6),
                const WavyDivider(color: _kDivider),
                const SizedBox(height: 8),
                _row('Room Charge', '₹${baseAmount.toStringAsFixed(2)}'),
                _row('CGST (${gstRate.toStringAsFixed(0)}%)',
                    '₹${cgstAmount.toStringAsFixed(2)}'),
                _row('SGST (${gstRate.toStringAsFixed(0)}%)',
                    '₹${sgstAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                const WavyDivider(color: _kDivider),
                const SizedBox(height: 8),
                // Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            color: _kTextDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: _kGold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: _kGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                if (foreignCurrency != null && foreignTotal != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '≈ ${foreignTotal!.toStringAsFixed(2)} $foreignCurrency',
                      style: const TextStyle(
                          color: _kTextMuted,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: _kTextMuted, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ── Proceed Button ─────────────────────────────────────────────────────────────
class _ProceedButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _ProceedButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _kMaroon,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kGold.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
                color: _kMaroon.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: _kGold, strokeWidth: 2.5),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      color: _kCream,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: _kGold, size: 18),
                ],
              ),
      ),
    );
  }
}

// ── Rooms & Guests bottom sheet ─────────────────────────────────────────────
class _RoomsGuestsResult {
  final int rooms, adults, children;
  const _RoomsGuestsResult(
      {required this.rooms, required this.adults, required this.children});
}

class _RoomsGuestsSheet extends StatefulWidget {
  final int initialRooms;
  final int initialAdults;
  final int initialChildren;
  final int occupancyPerRoom;
  const _RoomsGuestsSheet({
    required this.initialRooms,
    required this.initialAdults,
    required this.initialChildren,
    required this.occupancyPerRoom,
  });

  @override
  State<_RoomsGuestsSheet> createState() => _RoomsGuestsSheetState();
}

class _RoomsGuestsSheetState extends State<_RoomsGuestsSheet> {
  static const _maxRooms = 5;
  // Children under 7 don't need their own sleeping capacity — they share
  // with a parent — so they're capped independently rather than eating into
  // the room occupancy limit adults are counted against.
  static const _maxChildren = 3;

  late int _rooms = widget.initialRooms;
  late int _adults = widget.initialAdults;
  late int _children = widget.initialChildren;

  int get _maxGuests => widget.occupancyPerRoom * _rooms;

  void _clampGuests() {
    // Rooms shrank below what the current adult headcount needs.
    while (_adults > _maxGuests && _adults > 1) {
      _adults--;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: _kTextMuted),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'ROOMS & GUESTS',
                    style: TextStyle(
                      color: _kTextDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: _kDivider, height: 1),
              const SizedBox(height: 22),

              _sheetRow(
                label: 'Rooms',
                sublabel: 'Up to $_maxRooms rooms of this tent type',
                value: _rooms,
                onMinus: _rooms > 1
                    ? () => setState(() {
                          _rooms--;
                          _clampGuests();
                        })
                    : null,
                onPlus: _rooms < _maxRooms
                    ? () => setState(() => _rooms++)
                    : null,
              ),
              const SizedBox(height: 26),

              _sheetRow(
                label: 'Adults',
                value: _adults,
                onMinus: _adults > 1
                    ? () => setState(() => _adults--)
                    : null,
                onPlus: _adults < _maxGuests
                    ? () => setState(() => _adults++)
                    : null,
              ),
              const SizedBox(height: 26),

              _sheetRow(
                label: 'Children',
                sublabel: 'Below 7 years old',
                value: _children,
                onMinus: _children > 0
                    ? () => setState(() => _children--)
                    : null,
                onPlus: _children < _maxChildren
                    ? () => setState(() => _children++)
                    : null,
              ),
              const SizedBox(height: 24),

              Text(
                '* Max $_maxGuests adult${_maxGuests == 1 ? '' : 's'} across '
                '$_rooms room${_rooms == 1 ? '' : 's'}, plus up to '
                '$_maxChildren children below 7 years — they don\'t count '
                'toward the room limit. To ensure the best options and '
                'prices, kindly provide the accurate number of children and '
                'their respective ages.',
                style: const TextStyle(
                    color: _kTextMuted, fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_RoomsGuestsResult(
                    rooms: _rooms,
                    adults: _adults,
                    children: _children,
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kMaroon,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: BorderSide(color: _kGold.withValues(alpha: 0.6)),
                    ),
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      color: _kCream,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetRow({
    required String label,
    String? sublabel,
    required int value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: _kTextDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(sublabel,
                    style:
                        const TextStyle(color: _kTextMuted, fontSize: 13)),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kDivider),
          ),
          child: Row(
            children: [
              _sheetStepperBtn(Icons.remove, onMinus),
              SizedBox(
                width: 40,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              _sheetStepperBtn(Icons.add, onPlus),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sheetStepperBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Icon(icon,
            size: 18, color: enabled ? _kTextDark : _kDivider),
      ),
    );
  }
}
