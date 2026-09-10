import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/tent_card.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const _kHeroBg = Color(0xFF4A1000);
const _kBodyBg = Color(0xFFFFFFFF);
const _kCardBg = Color(0xFFFFFFFF);
const _kGold = Color(0xFFD4891A);
const _kBorderLight = Color(0xFFDDD0C4);
const _kTextDark = Color(0xFF2D0F05);
const _kTextMid = Color(0xFF7A4A30);
const _kTextLight = Color(0xFFA07050);
// ─────────────────────────────────────────────────────────────────────────────

// ─── Filtering (pure, unit-tested in test/search_filter_test.dart) ───────────

/// The cheapest and dearest tent actually on offer, rounded outwards to tidy
/// ₹500 steps. The price slider is built from these so its whole travel is
/// useful: a hardcoded ₹500–₹50,000 range left ~90% of the slider doing
/// nothing against real prices of ₹1,500–₹5,000, which read as "filter broken".
({double min, double max}) tentPriceBounds(List<CapsuleTent> tents) {
  final prices = tents.map((t) => t.price1Day).where((p) => p > 0).toList();
  if (prices.isEmpty) return (min: 0, max: 10000);

  var lo = prices.first, hi = prices.first;
  for (final p in prices) {
    if (p < lo) lo = p;
    if (p > hi) hi = p;
  }
  lo = (lo / 500).floor() * 500;
  hi = (hi / 500).ceil() * 500;
  // Guarantee a usable span even when every tent costs the same.
  if (hi <= lo) hi = lo + 500;
  return (min: lo, max: hi);
}

/// Applies the search box and every filter. [maxPrice] of null means no price
/// limit. A numeric [query] such as "2500" or "₹2,500" is treated as a budget,
/// so searching by amount returns tents at or under it.
List<CapsuleTent> filterTents({
  required List<CapsuleTent> tents,
  String query = '',
  String? type,
  double? maxPrice,
  bool acOnly = false,
  bool bathroomOnly = false,
  bool wifiOnly = false,
  bool availableOnly = false,
}) {
  final q = query.trim().toLowerCase();
  final queryAmount =
      q.isEmpty ? null : double.tryParse(q.replaceAll(RegExp(r'[₹,\s]'), ''));

  return tents.where((t) {
    if (q.isNotEmpty) {
      final matchesText = t.name.toLowerCase().contains(q) ||
          t.location.toLowerCase().contains(q) ||
          t.tentType.toLowerCase().contains(q);
      final matchesAmount = queryAmount != null && t.price1Day <= queryAmount;
      if (!matchesText && !matchesAmount) return false;
    }
    if (type != null && t.tentType.toLowerCase() != type.toLowerCase()) {
      return false;
    }
    if (maxPrice != null && t.price1Day > maxPrice) return false;
    if (acOnly && !t.hasAC) return false;
    if (bathroomOnly && !t.hasBathroom) return false;
    if (wifiOnly && !t.hasWifi) return false;
    if (availableOnly && !t.isAvailable) return false;
    return true;
  }).toList();
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedType;

  /// null means "no price filter". Using null rather than a sentinel max keeps
  /// the active-filter chip and the reset logic honest.
  double? _maxPrice;
  bool _acOnly = false;
  bool _bathroomOnly = false;
  bool _wifiOnly = false;
  bool _availableOnly = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTents());
  }

  Future<void> _loadTents() async {
    if (mounted) context.read<TentProvider>().loadTents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ({double min, double max}) get _priceBounds =>
      tentPriceBounds(context.read<TentProvider>().tents);

  List<CapsuleTent> get _filtered => filterTents(
        tents: context.read<TentProvider>().tents,
        query: _searchCtrl.text,
        type: _selectedType,
        maxPrice: _maxPrice,
        acOnly: _acOnly,
        bathroomOnly: _bathroomOnly,
        wifiOnly: _wifiOnly,
        availableOnly: _availableOnly,
      );

  void _clearAllFilters() {
    setState(() {
      _selectedType = null;
      _acOnly = false;
      _bathroomOnly = false;
      _wifiOnly = false;
      _maxPrice = null;
      _searchCtrl.clear();
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(
        selectedType: _selectedType,
        maxPrice: _maxPrice,
        priceMin: _priceBounds.min,
        priceMax: _priceBounds.max,
        acOnly: _acOnly,
        bathroomOnly: _bathroomOnly,
        wifiOnly: _wifiOnly,
        availableOnly: _availableOnly,
        onApply: (type, price, ac, bath, wifi, avail) {
          setState(() {
            _selectedType = type;
            _maxPrice = price;
            _acOnly = ac;
            _bathroomOnly = bath;
            _wifiOnly = wifi;
            _availableOnly = avail;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TentProvider>();
    final results = _filtered;

    return Scaffold(
      backgroundColor: _kBodyBg,
      // ── App bar — same plain white chrome as every other screen ────────
      appBar: AppBar(
        backgroundColor: _kCardBg,
        surfaceTintColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Search is always a bottom-nav tab, never a screen pushed on top of
        // something else — there is nothing to pop back to, so a back arrow
        // here used to sit dead on-screen no matter how hard it was tapped.
        automaticallyImplyLeading: false,
        title: const Text('Search Tents',
            style: TextStyle(
                color: _kTextDark, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: _kTextDark, size: 22),
            onPressed: _showFilters,
            tooltip: 'Filters',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorderLight),
        ),
      ),

      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14, color: _kTextDark),
                cursorColor: _kGold,
                decoration: InputDecoration(
                  // The global theme sets filled:true with a near-black
                  // fillColor, which painted over this container and left the
                  // typed text unreadable. Opt out so the container's own
                  // rounded background is what shows.
                  filled: false,
                  hintText: 'Search by name, location, type...',
                  hintStyle: TextStyle(
                      color: _kTextLight.withValues(alpha: 0.9), fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search, color: _kTextMid, size: 20),
                  // IconButton rather than a bare GestureDetector: it fills
                  // the suffix box, so taps landing just off the 20px glyph
                  // still register.
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close,
                              color: _kTextLight, size: 20),
                          tooltip: 'Clear search',
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // ── Active filter chips ────────────────────────────────────────
          if (_selectedType != null ||
              _maxPrice != null ||
              _acOnly ||
              _bathroomOnly ||
              _wifiOnly)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                if (_selectedType != null)
                  _chip(_selectedType!.toUpperCase(),
                      () => setState(() => _selectedType = null)),
                if (_maxPrice != null)
                  _chip('Under ₹${_maxPrice!.toInt()}',
                      () => setState(() => _maxPrice = null)),
                if (_acOnly) _chip('AC', () => setState(() => _acOnly = false)),
                if (_bathroomOnly)
                  _chip(
                      'Bathroom', () => setState(() => _bathroomOnly = false)),
                if (_wifiOnly)
                  _chip('WiFi', () => setState(() => _wifiOnly = false)),
              ]),
            ),

          // ── Result count ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Text.rich(TextSpan(
                text: '${results.length} ',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: _kGold),
                children: const [
                  TextSpan(
                      text: 'tents found',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: _kTextMid)),
                ],
              )),
            ]),
          ),

          // ── Scarcity banner ────────────────────────────────────────────
          // Reflects the whole inventory (not just the current filtered
          // view), so "Filling Fast" means the property overall, not "only
          // 1 tent matches your AC filter".
          _ScarcityBanner(tents: prov.tents),

          // ── Results ────────────────────────────────────────────────────
          Expanded(
            child: prov.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: _kGold, strokeWidth: 2.5))
                : RefreshIndicator(
                    color: _kGold,
                    onRefresh: _loadTents,
                    child: results.isEmpty
                        ? _emptyResults()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: results.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TentCard(
                                tent: results[i],
                                index: i,
                                onTap: () => context.push(
                                    '/tent/${results[i].id}',
                                    extra: results[i]),
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  /// The "nothing matched" state, made scrollable so it can still be pulled
  /// down to refresh — a Center alone gives RefreshIndicator nothing to hook
  /// onto, which is exactly when a guest is most likely to try refreshing.
  Widget _emptyResults() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off, size: 34, color: _kGold),
                ),
                const SizedBox(height: 14),
                const Text('No tents match your filters',
                    style: TextStyle(
                        color: _kTextMid, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _clearAllFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kGold,
                    side: const BorderSide(color: _kGold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Clear all filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: const TextStyle(
                  color: _kGold, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 14, color: _kGold)),
        ]),
      );
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String? selectedType;
  final double? maxPrice;
  final double priceMin, priceMax;
  final bool acOnly, bathroomOnly, wifiOnly, availableOnly;
  final void Function(String?, double?, bool, bool, bool, bool) onApply;

  const _FilterSheet({
    required this.selectedType,
    required this.maxPrice,
    required this.priceMin,
    required this.priceMax,
    required this.acOnly,
    required this.bathroomOnly,
    required this.wifiOnly,
    required this.availableOnly,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _type;
  late double _price;
  late bool _ac, _bath, _wifi, _avail;

  /// True while the slider sits at the top of the range, i.e. no price limit.
  bool get _priceUnset => _price >= widget.priceMax;

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    // An unset filter parks the slider at the top of the real price range.
    _price = (widget.maxPrice ?? widget.priceMax)
        .clamp(widget.priceMin, widget.priceMax)
        .toDouble();
    _ac = widget.acOnly;
    _bath = widget.bathroomOnly;
    _wifi = widget.wifiOnly;
    _avail = widget.availableOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _kBorderLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Filters',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark)),
              TextButton(
                  onPressed: () => setState(() {
                        _type = null;
                        _price = widget.priceMax;
                        _ac = false;
                        _bath = false;
                        _wifi = false;
                        _avail = true;
                      }),
                  child: const Text('Reset',
                      style: TextStyle(
                          color: _kGold, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 16),

            // Tent Type
            const Text('Tent Type',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _typeChip(null, 'All'),
              ...AppConstants.tentTypes.map(
                  (t) => _typeChip(t, t[0].toUpperCase() + t.substring(1))),
            ]),
            const SizedBox(height: 16),

            // Price slider — bounded by what tents actually cost
            Text(
                _priceUnset
                    ? 'Max Price per Day: Any'
                    : 'Max Price per Day: ₹${_price.toInt()}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _kGold,
                inactiveTrackColor: _kBorderLight,
                thumbColor: _kGold,
                overlayColor: _kGold.withValues(alpha: 0.15),
                valueIndicatorColor: _kHeroBg,
              ),
              child: Slider(
                  value: _price,
                  min: widget.priceMin,
                  max: widget.priceMax,
                  divisions: ((widget.priceMax - widget.priceMin) / 500)
                      .round()
                      .clamp(1, 100),
                  label: _priceUnset ? 'Any' : '₹${_price.toInt()}',
                  onChanged: (v) => setState(() => _price = v)),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹${widget.priceMin.toInt()}',
                  style: const TextStyle(fontSize: 11, color: _kTextLight)),
              Text('₹${widget.priceMax.toInt()}+',
                  style: const TextStyle(fontSize: 11, color: _kTextLight)),
            ]),
            const SizedBox(height: 8),

            // Amenities
            const Text('Amenities',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _amenityChip('AC', _ac, (v) => setState(() => _ac = v)),
              _amenityChip('Bathroom', _bath, (v) => setState(() => _bath = v)),
              _amenityChip('WiFi', _wifi, (v) => setState(() => _wifi = v)),
              _amenityChip(
                  'Available Only', _avail, (v) => setState(() => _avail = v)),
            ]),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Parked at the top of the range means "no price limit".
                  widget.onApply(_type, _priceUnset ? null : _price, _ac, _bath,
                      _wifi, _avail);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    )),
                child: const Text('Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ]),
    );
  }

  Widget _typeChip(String? value, String label) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kGold.withValues(alpha: 0.14) : _kBodyBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _kGold : _kBorderLight,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? _kGold : _kTextMid)),
      ),
    );
  }

  Widget _amenityChip(
      String label, bool selected, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kGold.withValues(alpha: 0.14) : _kBodyBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _kGold : _kBorderLight,
              width: selected ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (selected) ...[
            const Icon(Icons.check, size: 13, color: _kGold),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? _kGold : _kTextMid)),
        ]),
      ),
    );
  }
}

// ── Scarcity banner ─────────────────────────────────────────────────────────
// A guest browsing a near-empty inventory has no way to tell "5 tents shown
// because that's all there is" apart from "5 tents shown because the rest
// just got booked" — this makes the second case visible instead of silent.
class _ScarcityBanner extends StatelessWidget {
  final List<CapsuleTent> tents;
  const _ScarcityBanner({required this.tents});

  // Below this fraction of the total inventory still available, it's worth
  // calling out — above it, availability is a non-issue and the banner would
  // just be noise.
  static const _fillingFastThreshold = 0.2;

  @override
  Widget build(BuildContext context) {
    final total = tents.length;
    if (total == 0) return const SizedBox.shrink();

    final available = tents.where((t) => t.isAvailable).length;
    final isFull = available == 0;
    final isFillingFast = !isFull &&
        available <= (total * _fillingFastThreshold).ceil().clamp(1, total);

    if (!isFull && !isFillingFast) return const SizedBox.shrink();

    final color = isFull ? const Color(0xFFC0392B) : _kGold;
    final icon = isFull ? Icons.event_busy_rounded : Icons.local_fire_department_rounded;
    final message = isFull
        ? 'Booking Full — all tents are currently booked'
        : 'Filling Fast — only $available tent${available == 1 ? '' : 's'} left!';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ]),
      ),
    );
  }
}
