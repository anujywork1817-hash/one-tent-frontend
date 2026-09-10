import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/handcrafted.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const _kHeroBg       = Color(0xFF4A1000);   // dark maroon hero
const _kMaroonMid    = Color(0xFF6B1A00);
const _kBodyBg       = Color(0xFFFFFFFF);   // warm cream body
const _kCardBg       = Color(0xFFFFFFFF);
const _kGold         = Color(0xFFD4891A);
const _kBorderLight  = Color(0xFFDDD0C4);
const _kTextDark     = Color(0xFF2D0F05);
const _kTextMid      = Color(0xFF7A4A30);
const _kTextLight    = Color(0xFFA07050);
const _kCream        = Color(0xFFF5E6C8);
const _kSuccess      = Color(0xFF2E7D32);
const _kError        = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

class TentDetailScreen extends StatefulWidget {
  final CapsuleTent tent;
  const TentDetailScreen({super.key, required this.tent});

  @override
  State<TentDetailScreen> createState() => _TentDetailScreenState();
}

class _TentDetailScreenState extends State<TentDetailScreen> {
  TentReviewSummary _reviews = const TentReviewSummary();
  bool _reviewsLoading = true;
  final _photoController = PageController();
  int _photoIndex = 0;

  CapsuleTent get tent => widget.tent;

  // Placeholder gallery used only until a tent has real admin-uploaded
  // photos (image_urls is empty for every tent right now) — bundled local
  // assets so the detail screen shows an actual gallery instead of a bare
  // icon. Each of these paths is recognized in _buildPhoto() and rendered
  // via Image.asset instead of a network fetch.
  static const _fallbackPhotos = [
    'assets/images/tent_gallery_1.png',
    'assets/images/tent_gallery_2.png',
    'assets/images/tent_gallery_3.png',
    'assets/images/tent_gallery_4.png',
    'assets/images/tent_gallery_5.png',
  ];

  List<String> get _photos =>
      tent.imageUrls.isNotEmpty ? tent.imageUrls : _fallbackPhotos;

  Widget _buildPhoto(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: fit);
    }
    return Image.network(
      AppConstants.fileUrl(path),
      fit: fit,
      errorBuilder: (_, __, ___) => _photoPlaceholder(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    final summary = await context.read<TentProvider>().tentReviews(tent.id);
    if (!mounted) return;
    setState(() {
      _reviews = summary;
      _reviewsLoading = false;
    });
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      body: CustomScrollView(
        slivers: [

          // ── Hero photo gallery ─────────────────────────────────────────
          // Every real photo the admin uploaded for this tent — swipeable,
          // with dot indicators and a full-screen zoomable viewer on tap.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: Stack(fit: StackFit.expand, children: [
                _photos.isEmpty
                    ? _photoPlaceholder()
                    : PageView.builder(
                        controller: _photoController,
                        itemCount: _photos.length,
                        onPageChanged: (i) => setState(() => _photoIndex = i),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _openFullPhoto(i),
                          child: _buildPhoto(_photos[i]),
                        ),
                      ),
                // Bottom scrim so the badges/heart stay legible over a
                // bright photo.
                const Positioned(
                  left: 0, right: 0, bottom: 0, height: 80,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0x99000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Photo count / dot indicators — only when there's more
                // than one real photo to page through.
                if (_photos.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_photoIndex + 1}/${_photos.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                // Back button.
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                // VIP badge, bottom-left — real signal: only shown for
                // tents actually typed "luxury".
                if (tent.tentType.toLowerCase() == 'luxury')
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kHeroBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('VIP',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                // Wishlist heart.
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _WishlistHeartButton(tent: tent, light: false),
                  ),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Name + rating ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tent.name,
                          style: AppFonts.display(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _kTextDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.star_rounded,
                                size: 18, color: _kGold),
                            const SizedBox(width: 3),
                            Text(
                              _reviewsLoading
                                  ? '—'
                                  : _reviews.averageRating
                                      .toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: _kTextDark),
                            ),
                          ]),
                          Text(
                            _reviewsLoading
                                ? ''
                                : '${_reviews.totalReviews} reviews',
                            style: const TextStyle(
                                fontSize: 11.5, color: _kTextLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: _kGold.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        tent.tentType.toUpperCase(),
                        style: const TextStyle(
                          color: _kGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(),
                  ]),
                  const SizedBox(height: 12),

                  // ── Location ───────────────────────────────────────────
                  Row(children: [
                    const Icon(Icons.location_on, size: 16, color: _kTextMid),
                    const SizedBox(width: 4),
                    Text(tent.location,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _kTextDark)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('0.1 km from Sangam',
                          style: TextStyle(fontSize: 11.5, color: _kTextMid)),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Surge pricing notice ───────────────────────────────
                  // A heads-up during peak Kumbh dates, not a claim about a
                  // discounted "before" price — the amount shown on the Book
                  // Now bar below is the actual, real price either way.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kError.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kError.withValues(alpha: 0.25)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kError.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_fire_department_rounded,
                            size: 17, color: _kError),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Surge Pricing Active',
                                style: TextStyle(
                                    color: _kError,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              'Prices increase during high-demand Kumbh dates',
                              style: TextStyle(
                                  color: _kError.withValues(alpha: 0.85),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Amenities ─────────────────────────────────────────
                  if (tent.amenities.isNotEmpty) ...[
                    _sectionHeader(context, Icons.check_circle_outline_rounded, 'Amenities'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: tent.amenities
                          .map((a) => _amenityChip(_iconFor(a), a))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Policies ──────────────────────────────────────────
                  _sectionHeader(context, Icons.rule_rounded, 'Policies'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorderLight),
                    ),
                    child: Column(children: [
                      _policyRow(Icons.login_rounded, 'Check-in: 12:00 PM'),
                      Divider(height: 1, color: _kBorderLight),
                      _policyRow(Icons.logout_rounded, 'Check-out: 11:00 AM'),
                      Divider(height: 1, color: _kBorderLight),
                      _policyRow(Icons.cancel_outlined,
                          'Free cancellation before check-in'),
                      Divider(height: 1, color: _kBorderLight),
                      _policyRow(Icons.no_food_outlined,
                          'No outside food allowed'),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Reviews ────────────────────────────────────────────
                  _ReviewsSection(loading: _reviewsLoading, summary: _reviews),
                  const SizedBox(height: 28),

                  if (!tent.isAvailable)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kError.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kError.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          'This tent is currently unavailable',
                          style: TextStyle(
                              color: _kError,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                    ),

                  // Extra space so the sticky price/Book bar below never
                  // covers the last bit of scrollable content.
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBookBar(
        tent: tent,
        onBook: () => context.push('/book', extra: tent),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _photoPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kHeroBg, _kMaroonMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.cabin, size: 48, color: _kGold),
      );

  /// Full-screen swipeable, zoomable view of every real photo for this tent.
  void _openFullPhoto(int startIndex) {
    if (_photos.isEmpty) return;
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullPhotoViewer(
        photos: _photos,
        initialIndex: startIndex,
      ),
    ));
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(children: [
      Container(
        width: 3, height: 18,
        color: _kGold,
        margin: const EdgeInsets.only(right: 10),
      ),
      Icon(icon, size: 16, color: _kGold),
      const SizedBox(width: 6),
      Text(title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold, color: _kTextDark)),
    ]);
  }

  Widget _statusBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: tent.isAvailable
              ? _kSuccess.withValues(alpha: 0.12)
              : _kError.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: tent.isAvailable ? _kSuccess : _kError, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(tent.isAvailable ? Icons.check_circle : Icons.block,
              size: 14,
              color: tent.isAvailable ? _kSuccess : _kError),
          const SizedBox(width: 6),
          Text(tent.isAvailable ? 'Available' : 'Booked',
              style: TextStyle(
                  color: tent.isAvailable ? _kSuccess : _kError,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ]),
      );

  Widget _policyRow(IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: _kGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: _kTextDark,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      );

  Widget _amenityChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEE7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: _kGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  IconData _iconFor(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
      case 'wi-fi':        return Icons.wifi;
      case 'ac':
      case 'air conditioning': return Icons.ac_unit;
      case 'bathroom':     return Icons.bathroom;
      case 'power backup': return Icons.bolt;
      case 'tv':
      case 'television':   return Icons.tv;
      case 'fridge':       return Icons.kitchen;
      case 'sofa':         return Icons.weekend;
      case 'air purifier': return Icons.air;
      default:             return Icons.check_circle_outline;
    }
  }
}
// ── Full-screen photo viewer ─────────────────────────────────────────────────
class _FullPhotoViewer extends StatefulWidget {
  const _FullPhotoViewer({required this.photos, required this.initialIndex});
  final List<String> photos;
  final int initialIndex;

  @override
  State<_FullPhotoViewer> createState() => _FullPhotoViewerState();
}

class _FullPhotoViewerState extends State<_FullPhotoViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => Center(
            child: InteractiveViewer(
              child: widget.photos[i].startsWith('assets/')
                  ? Image.asset(widget.photos[i], fit: BoxFit.contain)
                  : Image.network(AppConstants.fileUrl(widget.photos[i]),
                      fit: BoxFit.contain),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        if (widget.photos.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_index + 1} / ${widget.photos.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Wishlist heart ───────────────────────────────────────────────────────────
// Its own widget so the (stateless) detail screen doesn't need to rebuild
// wholesale, and so the saved state survives coming back to this screen.
class _WishlistHeartButton extends StatefulWidget {
  const _WishlistHeartButton({required this.tent, this.light = true});

  final CapsuleTent tent;

  /// True (default) renders a light/cream icon for a dark or photo
  /// background; false renders a dark icon for sitting on a white circle.
  final bool light;

  @override
  State<_WishlistHeartButton> createState() => _WishlistHeartButtonState();
}

class _WishlistHeartButtonState extends State<_WishlistHeartButton> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Deferred: load() notifies listeners, which is illegal during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WishlistProvider>().load();
    });
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);

    final wishlist = context.read<WishlistProvider>();
    final nowSaved = await wishlist.toggle(widget.tent);

    if (!mounted) return;
    setState(() => _busy = false);

    final failed = wishlist.error != null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(failed
          ? wishlist.error!
          : nowSaved
              ? 'Saved to your wishlist'
              : 'Removed from your wishlist'),
      backgroundColor: failed ? _kError : _kMaroonMid,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<WishlistProvider>().isSaved(widget.tent.id);

    return IconButton(
      onPressed: _busy ? null : _toggle,
      icon: Icon(
        saved ? Icons.favorite : Icons.favorite_outline,
        color: saved ? _kError : (widget.light ? _kCream : _kTextMid),
      ),
      tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
    );
  }
}

// ── Sticky bottom price + Book bar ───────────────────────────────────────────
class _BottomBookBar extends StatelessWidget {
  const _BottomBookBar({required this.tent, required this.onBook});

  final CapsuleTent tent;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyUtils.currencyForCountry(
        context.watch<AuthProvider>().visitor?.country);
    final rates = context.watch<TentProvider>().exchangeRates;
    final priceLabel = CurrencyUtils.formatPrice(tent.price1Day,
        currency: currency, rates: rates);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorderLight)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark),
                  ),
                  const Text('per night + taxes',
                      style: TextStyle(fontSize: 11.5, color: _kTextLight)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              onPressed: tent.isAvailable ? onBook : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                disabledBackgroundColor: _kBorderLight,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Book Now',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reviews section ──────────────────────────────────────────────────────────
// What other guests see for this tent — submitted from the booking detail
// screen after a confirmed stay, not an email that only the support team saw.
class _ReviewsSection extends StatelessWidget {
  final bool loading;
  final TentReviewSummary summary;
  const _ReviewsSection({required this.loading, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(color: _kGold, strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Guest Reviews',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: _kTextDark)),
          if (summary.totalReviews > 0) ...[
            const SizedBox(width: 10),
            Icon(Icons.star_rounded, size: 18, color: _kGold),
            const SizedBox(width: 2),
            Text(
              '${summary.averageRating.toStringAsFixed(1)} '
              '(${summary.totalReviews})',
              style: const TextStyle(
                  color: _kTextMid, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        if (summary.reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withValues(alpha: 0.18)),
            ),
            child: const Text(
              'No reviews yet — be the first to stay and share how it went.',
              style: TextStyle(color: _kTextMid, fontSize: 13),
            ),
          )
        else
          ...summary.reviews.map((r) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(r.guestName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: _kTextDark)),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 14,
                            color: _kGold,
                          ),
                        ),
                      ),
                    ]),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.comment,
                          style: const TextStyle(
                              fontSize: 13, color: _kTextMid, height: 1.4)),
                    ],
                  ],
                ),
              )),
      ],
    );
  }
}
