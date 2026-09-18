import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/tap_scale.dart';

// ─── One Tent Design Tokens — same brand palette as the rest of the app ────
const Color _kInk = Color(0xFF2D0F05);       // matches _kTextDark elsewhere
const Color _kMuted = Color(0xFF7A4A30);     // matches _kTextMid elsewhere
const Color _kFaint = Color(0xFFF3EEE7);     // matches the amenity-pill fill
const Color _kBorder = Color(0xFFDDD0C4);    // matches _kBorderLight elsewhere
const Color _kOrange = Color(0xFFD4891A);    // the app's actual gold
const Color _kOrangeDeep = Color(0xFF4A1000); // the app's actual maroon
const Color _kBodyBg = Color(0xFFFFFFFF);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kError = Color(0xFFC0392B);
const Color _kRangeBlue = Color(0xFF2E6E9E); // nights between check-in/out
// ─────────────────────────────────────────────────────────────────────────────

const _maxTents = 5;

class BookingScreen extends StatefulWidget {
  final CapsuleTent tent;
  const BookingScreen({super.key, required this.tent});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // ── Guest details ─────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final String _idProofType = 'passport'; // Passport is the only ID proof accepted here.

  // ── Dates ──────────────────────────────────────────────────────────────
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  late DateTime _calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  // Real per-day green/yellow/red occupancy for the currently shown month,
  // keyed by "YYYY-MM-DD" — empty until it loads, so the calendar just
  // falls back to its default undyed look rather than blocking on it.
  Map<String, DayAvailability> _dayAvailability = {};
  bool _availabilityLoading = false;

  // ── Preferences ────────────────────────────────────────────────────────
  // Bed type sets how many adults each tent actually holds — Single is 1
  // person per tent, Double is 2 — not just a cosmetic preference.
  String _bedType = 'single'; // 'single' | 'double'
  int get _adultsPerTent => _bedType == 'single' ? 1 : 2;
  int _guests = 1;
  int _tents = 1;
  bool _travelingWithChildren = false;
  int _childrenUnder5 = 0;
  int _childrenAbove5 = 0;
  static const _childFeePerHead = 500.0; // flat, once per booking

  // ── Coupon ─────────────────────────────────────────────────────────────
  final _couponCtrl = TextEditingController();
  CouponPreview? _couponResult;
  bool _couponLoading = false;
  List<CouponPreview> _suggestedCoupons = [];

  bool _isLoading = false;
  final List<TextEditingController> _guestNameCtrls = [];
  final List<TextEditingController> _guestPhoneCtrls = [];

  // Capped by the tent's real capacity too, so a Double selection never
  // asks the backend for more adults than the tent can actually hold.
  int get _maxGuestsForTents =>
      (_adultsPerTent < widget.tent.maxOccupancy
              ? _adultsPerTent
              : widget.tent.maxOccupancy) *
      _tents;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TentProvider>().loadExchangeRates();
      final visitor = context.read<AuthProvider>().visitor;
      if (visitor != null) {
        _nameCtrl.text = visitor.fullName;
        // The profile stores the number as entered at signup, which for
        // most guests includes a country code (e.g. "+919699488429"). This
        // field is India-only and digits-only with a 10-digit cap, so a
        // code left in front just got truncated from the wrong end (e.g.
        // "9199488429" — the last real digit chopped off, not the "91").
        // Strip it here so what's prefilled is already the clean local
        // number the field actually expects.
        _phoneCtrl.text = _localTenDigits(visitor.phone);
        if (visitor.passportNumber.isNotEmpty) {
          _idNumberCtrl.text = visitor.passportNumber;
        }
      }
      context.read<TentProvider>().activeCoupons().then((coupons) {
        if (mounted) setState(() => _suggestedCoupons = coupons);
      });
      _loadDayAvailability();
    });
  }

  /// Strips a leading country code and returns just the last 10 digits —
  /// "+919699488429", "919699488429" and "9699488429" all become
  /// "9699488429". Digits-only input already ≤10 long is returned as-is.
  String _localTenDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  Future<void> _loadDayAvailability() async {
    setState(() => _availabilityLoading = true);
    final month = DateFormat('yyyy-MM').format(_calendarMonth);
    final data = await context
        .read<TentProvider>()
        .dayAvailability(tentId: widget.tent.id, month: month);
    if (!mounted) return;
    setState(() {
      _dayAvailability = data;
      _availabilityLoading = false;
    });
  }

  void _syncGuestControllers() {
    final want = _guests - 1;
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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _idNumberCtrl.dispose();
    _couponCtrl.dispose();
    for (final c in _guestNameCtrls) {
      c.dispose();
    }
    for (final c in _guestPhoneCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  int get _duration {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  double get _baseAmount => widget.tent.price1Day * _duration * _tents;
  double get _gstRate => widget.tent.price1Day < 7500 ? 12 : 18;

  double get _discountAmount =>
      _couponResult?.discountFor(_baseAmount) ?? 0;
  double get _taxableAmount => _baseAmount - _discountAmount;
  double get _cgstAmount => _taxableAmount * _gstRate / 100 / 2;
  double get _sgstAmount => _taxableAmount * _gstRate / 100 / 2;
  // Untaxed, flat, once per booking — mirrors the backend exactly (see
  // childFeePerHead in internal/booking/handler.go) so what's shown here
  // is what actually gets charged.
  double get _childFee => _childrenAbove5 * _childFeePerHead;
  double get _totalPrice =>
      _taxableAmount + _cgstAmount + _sgstAmount + _childFee;

  bool get _readyToBook =>
      _checkInDate != null && _checkOutDate != null && _duration > 0;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyUtils.currencyForCountry(
        context.watch<AuthProvider>().visitor?.country);
    final rates = context.watch<TentProvider>().exchangeRates;
    final priceLabel = CurrencyUtils.formatPrice(widget.tent.price1Day,
        currency: currency, rates: rates);
    final totalLabel = CurrencyUtils.formatPrice(_totalPrice,
        currency: currency, rates: rates);

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(tent: widget.tent),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TentSummaryCard(tent: widget.tent, priceLabel: priceLabel),
                    const SizedBox(height: 22),

                    _sectionLabel('Guest Details'),
                    const SizedBox(height: 10),
                    _card(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Full name'),
                        _textField(_nameCtrl, hint: 'Enter your full name'),
                        const SizedBox(height: 14),
                        _fieldLabel('Mobile number'),
                        _textField(_phoneCtrl,
                            hint: '10-digit mobile number',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 10),
                        const SizedBox(height: 16),
                        _fieldLabel('Passport number'),
                        _textField(_idNumberCtrl, hint: 'Passport number'),
                      ],
                    )),
                    const SizedBox(height: 22),

                    _sectionLabel('Select Dates'),
                    const SizedBox(height: 10),
                    _card(child: Column(children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                            child: _dateBox('CHECK-IN', _checkInDate)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _dateBox('CHECK-OUT', _checkOutDate,
                                nights: _duration)),
                      ]),
                      const SizedBox(height: 14),
                      _availabilityLegend(),
                      const SizedBox(height: 14),
                      _calendar(),
                    ])),
                    const SizedBox(height: 22),

                    _sectionLabel('Preferences'),
                    const SizedBox(height: 10),
                    _card(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bed type',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _kInk)),
                        const SizedBox(height: 10),
                        _bedTypeToggle(),
                      ],
                    )),
                    const SizedBox(height: 14),

                    // ── Guests ──────────────────────────────────────────
                    // Follows the bed type directly — Single is 1 adult per
                    // tent, Double is 2 — so this is a readout, not an
                    // independent stepper that could drift from it. Its own
                    // labeled section (rather than sharing a card with
                    // Tents below) so the guest count is the first thing
                    // seen after choosing a bed type, not buried under it.
                    _sectionLabel('Guests'),
                    const SizedBox(height: 10),
                    _card(child: Row(children: [
                      const Icon(Icons.people_outline,
                          size: 20, color: _kOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Guests',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _kInk)),
                            const SizedBox(height: 2),
                            Text(
                              '${_bedType == 'single' ? 'Single' : 'Double'} bed × $_tents tent${_tents == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  fontSize: 12, color: _kMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$_guests adult${_guests == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _kInk),
                      ),
                    ])),
                    const SizedBox(height: 14),

                    // ── Tents ───────────────────────────────────────────
                    // How many tents of this type to book in one go — capped
                    // at _maxTents (5) per booking. Bumping this recomputes
                    // Guests above via _maxGuestsForTents, so the two never
                    // drift out of sync.
                    _sectionLabel('Tents'),
                    const SizedBox(height: 10),
                    _card(child: _stepperRow(
                      title: 'Tents',
                      subtitle: 'Units to book (up to $_maxTents per person)',
                      value: _tents,
                      onMinus: _tents > 1
                          ? () => setState(() {
                                _tents--;
                                _guests = _maxGuestsForTents;
                                _syncGuestControllers();
                              })
                          : null,
                      onPlus: _tents < _maxTents
                          ? () => setState(() {
                                _tents++;
                                _guests = _maxGuestsForTents;
                                _syncGuestControllers();
                              })
                          : null,
                    )),
                    const SizedBox(height: 14),

                    _sectionLabel('Traveling With Children?'),
                    const SizedBox(height: 10),
                    _card(child: Column(children: [
                      Row(children: [
                        const Expanded(
                          child: Text('Are any guests children?',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _kInk)),
                        ),
                        Switch(
                          value: _travelingWithChildren,
                          activeThumbColor: _kOrange,
                          onChanged: (v) => setState(() {
                            _travelingWithChildren = v;
                            if (!v) {
                              _childrenUnder5 = 0;
                              _childrenAbove5 = 0;
                            }
                          }),
                        ),
                      ]),
                      if (_travelingWithChildren) ...[
                        const Divider(height: 26, color: _kBorder),
                        _stepperRow(
                          title: '5 years & under',
                          subtitle: 'Free — up to 2 per booking',
                          value: _childrenUnder5,
                          onMinus: _childrenUnder5 > 0
                              ? () => setState(() => _childrenUnder5--)
                              : null,
                          onPlus: _childrenUnder5 < 2
                              ? () => setState(() => _childrenUnder5++)
                              : null,
                        ),
                        const Divider(height: 26, color: _kBorder),
                        _stepperRow(
                          title: 'Above 5 years',
                          subtitle:
                              '₹${_childFeePerHead.toStringAsFixed(0)} per child, up to 2 per booking',
                          value: _childrenAbove5,
                          onMinus: _childrenAbove5 > 0
                              ? () => setState(() => _childrenAbove5--)
                              : null,
                          onPlus: _childrenAbove5 < 2
                              ? () => setState(() => _childrenAbove5++)
                              : null,
                        ),
                      ],
                    ])),
                    const SizedBox(height: 22),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel('Coupon Code'),
                        GestureDetector(
                          onTap: _showAllCoupons,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.local_offer_outlined,
                                size: 15, color: _kOrange),
                            const SizedBox(width: 4),
                            Text('View All',
                                style: TextStyle(
                                    color: _kOrange,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_suggestedCoupons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Try: ${_suggestedCoupons.map((c) => c.code).join(' · ')}',
                          style: const TextStyle(
                              fontSize: 12, color: _kMuted, height: 1.4),
                        ),
                      ),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _couponCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontSize: 14, color: _kInk),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Enter coupon code',
                            hintStyle:
                                const TextStyle(color: _kMuted, fontSize: 13),
                            filled: true,
                            fillColor: _kFaint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _couponLoading ? null : _applyCoupon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 22),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _couponLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('APPLY',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5)),
                        ),
                      ),
                    ]),
                    if (_couponResult != null) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(
                          _couponResult!.valid
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 15,
                          color: _couponResult!.valid ? _kGreen : _kError,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_couponResult!.message,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: _couponResult!.valid
                                      ? _kGreen
                                      : _kError,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 22),

                    if (_guests > 1) ...[
                      _sectionLabel("Other Guests' Details"),
                      const SizedBox(height: 10),
                      _OtherGuestsForm(
                        nameCtrls: _guestNameCtrls,
                        phoneCtrls: _guestPhoneCtrls,
                      ),
                      const SizedBox(height: 22),
                    ],

                    _sectionLabel('Price Breakdown'),
                    const SizedBox(height: 10),
                    _PriceBreakdownCard(
                      pricePerNight: widget.tent.price1Day,
                      nights: _duration,
                      tents: _tents,
                      guests: _guests,
                      childrenAbove5: _childrenAbove5,
                      childrenUnder5: _childrenUnder5,
                      baseAmount: _baseAmount,
                      discountAmount: _discountAmount,
                      couponCode: _couponResult?.valid == true
                          ? _couponResult?.code
                          : null,
                      gstRate: _gstRate,
                      cgstAmount: _cgstAmount,
                      sgstAmount: _sgstAmount,
                      childFee: _childFee,
                      total: _totalPrice,
                    ),
                  ],
                ),
              ),
            ),
            _BottomBar(
              totalLabel: _readyToBook ? totalLabel : null,
              enabled: _readyToBook && !_isLoading,
              isLoading: _isLoading,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  // ── Small building blocks ────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _kMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: 0.6,
        ),
      );

  Widget _fieldLabel(String text, {bool center = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 12.5, color: _kMuted)),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: child,
      );

  Widget _textField(TextEditingController ctrl,
      {required String hint,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      int? maxLength}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14.5, color: _kInk),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: _kMuted, fontSize: 13.5),
        filled: true,
        fillColor: _kFaint,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }

  Widget _bedTypeToggle() {
    return Row(children: [
      Expanded(
        child: _pillToggle(
            'Single', _bedType == 'single', () => _setBedType('single')),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _pillToggle(
            'Double', _bedType == 'double', () => _setBedType('double')),
      ),
    ]);
  }

  // Single always means exactly 1 adult per tent, Double exactly 2 — the
  // Guests count follows the bed type directly rather than being a free
  // stepper that can drift from what was actually selected.
  void _setBedType(String type) {
    setState(() {
      _bedType = type;
      _guests = _maxGuestsForTents;
      _syncGuestControllers();
    });
  }

  Widget _pillToggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_kOrange, _kOrangeDeep])
              : null,
          color: selected ? null : _kFaint,
          borderRadius: BorderRadius.circular(28),
          border: selected ? null : Border.all(color: _kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : _kInk,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
    );
  }

  Widget _stepperRow({
    required String title,
    required String subtitle,
    required int value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
  }) {
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: _kInk)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: _kMuted)),
          ],
        ),
      ),
      _stepperBtn(Icons.remove, onMinus),
      SizedBox(
        width: 32,
        child: Text('$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: _kInk)),
      ),
      _stepperBtn(Icons.add, onPlus, filled: true),
    ]);
  }

  Widget _stepperBtn(IconData icon, VoidCallback? onTap, {bool filled = false}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled && enabled ? _kOrange : _kFaint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 16,
            color: filled && enabled
                ? Colors.white
                : (enabled ? _kInk : _kMuted.withValues(alpha: 0.5))),
      ),
    );
  }

  /// [nights] is only passed for the check-out box — shown as an extra line
  /// under the weekday once both dates are picked, so the stay length is
  /// visible right where the range was just chosen instead of only lower
  /// down the screen.
  Widget _dateBox(String label, DateTime? date, {int? nights}) {
    final dateFmt = DateFormat('MMM d, yyyy');
    final dayFmt = DateFormat('EEE');
    final picked = date != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kFaint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: picked ? _kOrange : _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10.5,
                  color: _kMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(picked ? dateFmt.format(date) : 'Select',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: picked ? _kInk : _kMuted)),
          if (picked) ...[
            const SizedBox(height: 2),
            Text(dayFmt.format(date),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kOrange)),
          ],
          if (picked && nights != null && nights > 0) ...[
            const SizedBox(height: 2),
            Text('$nights night${nights == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kOrange)),
          ],
        ],
      ),
    );
  }

  Widget _availabilityLegend() {
    // Real per-day occupancy from the backend — how many tents of this
    // type are actually free on each date.
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _legendDot(_kGreen, 'Available'),
      _legendDot(const Color(0xFFE0A106), 'Few left'),
      _legendDot(_kError, 'Booked'),
    ]);
  }

  Widget _legendDot(Color color, String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11.5, color: _kMuted)),
        ]),
      );

  Widget _calendar() {
    final firstOfMonth = _calendarMonth;
    final daysInMonth =
        DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7; // Sun=0 .. Sat=6
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: _kInk),
          onPressed: () {
            setState(() {
              _calendarMonth =
                  DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
            });
            _loadDayAvailability();
          },
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(DateFormat('MMMM yyyy').format(_calendarMonth),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (_availabilityLoading) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.6, color: _kOrange),
            ),
          ],
        ]),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: _kInk),
          onPressed: () {
            setState(() {
              _calendarMonth =
                  DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
            });
            _loadDayAvailability();
          },
        ),
      ]),
      const SizedBox(height: 4),
      Row(
        children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
            .asMap()
            .entries
            .map((e) => Expanded(
                  child: Center(
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: e.key == 0 || e.key == 6
                                ? _kOrange
                                : _kMuted)),
                  ),
                ))
            .toList(),
      ),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7),
        itemCount: leadingBlanks + daysInMonth,
        itemBuilder: (context, i) {
          if (i < leadingBlanks) return const SizedBox.shrink();
          final day = i - leadingBlanks + 1;
          final date =
              DateTime(_calendarMonth.year, _calendarMonth.month, day);
          final isPast = date.isBefore(today);
          final isCheckIn = _checkInDate != null &&
              date.difference(_checkInDate!).inDays == 0;
          final isCheckOut = _checkOutDate != null &&
              date.difference(_checkOutDate!).inDays == 0;
          final inRange = _checkInDate != null &&
              _checkOutDate != null &&
              date.isAfter(_checkInDate!) &&
              date.isBefore(_checkOutDate!);
          final selected = isCheckIn || isCheckOut;

          final avail = _dayAvailability[DateFormat('yyyy-MM-dd').format(date)];
          final isFullyBooked = avail?.status == 'booked';
          final dayDisabled = isPast || isFullyBooked;

          // Base fill from real per-day occupancy when it's loaded; falls
          // back to the plain "open" look while it's still loading. A fully
          // booked day is a solid dark red — a faint tint made it easy to
          // miss that the date isn't actually selectable. "limited" used to
          // be a near-white pale yellow (0xFFFFF3D6) that was barely
          // distinguishable from an empty cell on a white background —
          // guests read those dates as blank/missing rather than "a few
          // left". Matched to the legend dot's actual amber instead.
          Color baseFill = const Color(0xFFE3F2E1); // green — available
          if (avail != null) {
            baseFill = switch (avail.status) {
              'booked' => const Color(0xFF8E1D1D), // dark red — fully booked
              'limited' => const Color(0xFFF5C344), // amber — few remain
              _ => const Color(0xFFE3F2E1),
            };
          }

          final bold = selected || inRange || isFullyBooked;

          return GestureDetector(
            onTap: dayDisabled ? null : () => _onDayTapped(date),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? _kOrange
                      : inRange
                          ? _kRangeBlue
                          : (isPast ? Colors.transparent : baseFill),
                  shape: BoxShape.circle,
                ),
                child: Text('$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: bold
                          ? Colors.white
                          : (isPast ? _kMuted.withValues(alpha: 0.4) : _kInk),
                    )),
              ),
            ),
          );
        },
      ),
    ]);
  }

  void _onDayTapped(DateTime date) {
    setState(() {
      if (_checkInDate == null || (_checkOutDate != null)) {
        // Starting a fresh selection.
        _checkInDate = date;
        _checkOutDate = null;
      } else if (date.isAfter(_checkInDate!)) {
        _checkOutDate = date;
      } else {
        // Tapped an earlier date than the current check-in — restart from it.
        _checkInDate = date;
        _checkOutDate = null;
      }
    });
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _couponLoading = true);
    try {
      final result = await context.read<TentProvider>().validateCoupon(code);
      if (!mounted) return;
      setState(() => _couponResult = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _couponResult = const CouponPreview(
          valid: false, message: 'Could not check that code — try again'));
    } finally {
      if (mounted) setState(() => _couponLoading = false);
    }
  }

  void _showAllCoupons() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available coupons',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            if (_suggestedCoupons.isEmpty)
              const Text('No active coupons right now.',
                  style: TextStyle(color: _kMuted))
            else
              ..._suggestedCoupons.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      const Icon(Icons.local_offer, size: 16, color: _kOrange),
                      const SizedBox(width: 8),
                      Text(c.code ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(
                        c.discountType == 'percent'
                            ? '${c.discountValue.toStringAsFixed(0)}% off'
                            : '₹${c.discountValue.toStringAsFixed(0)} off',
                        style: const TextStyle(color: _kMuted, fontSize: 13),
                      ),
                    ]),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (!_readyToBook) return;

    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      _snack('Enter a valid 10-digit mobile number');
      return;
    }

    final additionalGuests = <AdditionalGuest>[];
    for (var i = 0; i < _guestNameCtrls.length; i++) {
      final name = _guestNameCtrls[i].text.trim();
      final guestPhone = _guestPhoneCtrls[i].text.trim();
      if (name.isEmpty || guestPhone.isEmpty) {
        _snack('Please enter name and phone for guest ${i + 2}');
        return;
      }
      if (guestPhone.length != 10) {
        _snack('Enter a valid 10-digit phone number for guest ${i + 2}');
        return;
      }
      additionalGuests.add(AdditionalGuest(name: name, phone: guestPhone));
    }

    setState(() => _isLoading = true);
    final tentProv = context.read<TentProvider>();

    final specialRequest = [
      'Preferred bed type: ${_bedType == 'single' ? 'Single' : 'Double'}',
      if (_travelingWithChildren)
        'Traveling with children ($_childrenUnder5 under 5, $_childrenAbove5 above 5)',
    ].join(' · ');

    final booking = await tentProv.createBooking(
      tentId: widget.tent.id,
      checkInDate: DateFormat('yyyy-MM-dd').format(_checkInDate!),
      duration: _duration,
      numGuests: _guests,
      additionalGuests: additionalGuests,
      roomCount: _tents,
      specialRequests: specialRequest,
      couponCode: _couponResult?.valid == true ? _couponResult?.code : null,
      childrenUnder5: _childrenUnder5,
      childrenAbove5: _childrenAbove5,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (booking == null) {
      _snack(tentProv.error ?? 'Booking failed. Please try again.');
      return;
    }

    context.push('/payment', extra: booking);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: _kError,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ── Header ───────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final CapsuleTent tent;
  const _Header({required this.tent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: _kInk, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Column(children: [
            const Text('Book Your Tent',
                style: TextStyle(
                    color: _kInk, fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 2),
            const Text('KUMBH MELA · NASHIK 2027',
                style: TextStyle(
                    color: _kMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ]),
        ),
        const SizedBox(width: 32),
      ]),
    );
  }
}

// ── Tent summary card ──────────────────────────────────────────────────
class _TentSummaryCard extends StatelessWidget {
  final CapsuleTent tent;
  final String priceLabel;
  const _TentSummaryCard({required this.tent, required this.priceLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 64,
            height: 64,
            child: (tent.imageUrl == null || tent.imageUrl!.isEmpty)
                ? Container(
                    color: _kFaint,
                    child: const Icon(Icons.cabin, color: _kOrange),
                  )
                : Image.network(
                    AppConstants.fileUrl(tent.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _kFaint,
                      child: const Icon(Icons.cabin, color: _kOrange),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tent.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15.5, color: _kInk)),
              const SizedBox(height: 3),
              Text(tent.location,
                  style: const TextStyle(fontSize: 12.5, color: _kMuted)),
              const SizedBox(height: 4),
              Text('$priceLabel / night',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _kOrangeDeep)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Other Guests Form ──────────────────────────────────────────────────
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guest ${i + 2}',
                  style: const TextStyle(
                      color: _kInk, fontWeight: FontWeight.bold, fontSize: 12.5)),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrls[i],
                style: const TextStyle(color: _kInk, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Full name',
                  hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
                  filled: true,
                  fillColor: _kFaint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrls[i],
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                style: const TextStyle(color: _kInk, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  hintText: 'Phone number',
                  hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
                  filled: true,
                  fillColor: _kFaint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
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

// ── Price breakdown ─────────────────────────────────────────────────────
class _PriceBreakdownCard extends StatelessWidget {
  final double pricePerNight;
  final int nights, tents, guests, childrenAbove5, childrenUnder5;
  final double baseAmount, discountAmount, gstRate, cgstAmount, sgstAmount,
      childFee, total;
  final String? couponCode;
  const _PriceBreakdownCard({
    required this.pricePerNight,
    required this.nights,
    required this.tents,
    required this.guests,
    this.childrenAbove5 = 0,
    this.childrenUnder5 = 0,
    required this.baseAmount,
    required this.discountAmount,
    this.couponCode,
    required this.gstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    this.childFee = 0,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final totalChildren = childrenAbove5 + childrenUnder5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(children: [
        // Real headcount for this booking — adults plus any children,
        // called out separately since only those above 5 add to the bill.
        _row(
          'Guests',
          '$guests adult${guests == 1 ? '' : 's'}'
              '${totalChildren > 0 ? ' + $totalChildren child${totalChildren == 1 ? '' : 'ren'}' : ''}',
        ),
        if (childrenAbove5 > 0)
          _row('  · above 5 years', '$childrenAbove5 (chargeable)'),
        if (childrenUnder5 > 0)
          _row('  · 5 years & under', '$childrenUnder5 (free)'),
        const Divider(height: 22, color: _kBorder),
        _row('₹${pricePerNight.toStringAsFixed(0)} × $nights night${nights == 1 ? '' : 's'} × $tents tent${tents == 1 ? '' : 's'}',
            '₹${baseAmount.toStringAsFixed(0)}'),
        if (discountAmount > 0)
          _row('Coupon${couponCode != null ? ' ($couponCode)' : ''}',
              '-₹${discountAmount.toStringAsFixed(0)}',
              valueColor: _kGreen),
        _row('CGST (${(gstRate / 2).toStringAsFixed(0)}%)',
            '₹${cgstAmount.toStringAsFixed(0)}'),
        _row('SGST (${(gstRate / 2).toStringAsFixed(0)}%)',
            '₹${sgstAmount.toStringAsFixed(0)}'),
        if (childFee > 0)
          _row('Child charge ($childrenAbove5 above 5 yrs)',
              '₹${childFee.toStringAsFixed(0)}'),
        const Divider(height: 22, color: _kBorder),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total payable',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('₹${total.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: _kOrangeDeep)),
        ]),
      ]),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: _kMuted, fontSize: 12.5)),
          ),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? _kInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

// ── Bottom sticky bar ────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final String? totalLabel;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;
  const _BottomBar({
    required this.totalLabel,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TOTAL PAYABLE',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: _kMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Text(totalLabel ?? '—',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: _kInk)),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: TapScale(
            onTap: enabled ? onPressed : null,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(colors: [_kOrange, _kOrangeDeep])
                    : null,
                color: enabled ? null : _kBorder,
                borderRadius: BorderRadius.circular(26),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      enabled ? 'Proceed to Payment' : 'Select dates to continue',
                      style: TextStyle(
                        color: enabled ? Colors.white : _kMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
        ),
      ]),
    );
  }
}
