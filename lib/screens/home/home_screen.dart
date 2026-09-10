import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../widgets/tent_card.dart';
import '../../widgets/handcrafted.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kBgDeep = Color(0xFF0D0401);
const _kHeroBg = Color(0xFF2A0A02);
const _kBodyBg = Color(0xFFFFFFFF);
const _kCardBg = Color(0xFFFFFFFF);
const _kGold = Color(0xFFD4891A);
const _kGoldLight = Color(0xFFE8A93A);
const _kBorder = Color(0xFFDDD0C4);
const _kTextDark = Color(0xFF2D0F05);
const _kTextMid = Color(0xFF7A4A30);
const _kTextLight = Color(0xFFA07050);
const _kCream = Color(0xFFF5E6C8);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedType;
  String _searchQuery = '';
  String _sortBy = 'Popular';

  // The field needs a controller: without one, clearing _searchQuery resets
  // the results but leaves the typed text sitting in the box, so the clear
  // button looks broken.
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTents();
      _maybeShowPassportPrompt();
    });
  }

  // Shown exactly once, right after email verification succeeds — nudges
  // the guest toward the other prerequisite (passport) they'll need before
  // check-in, instead of them discovering it later at booking time.
  void _maybeShowPassportPrompt() {
    final auth = context.read<AuthProvider>();
    if (!auth.justVerifiedEmail) return;
    auth.clearJustVerifiedEmail();

    final status = auth.visitor?.passportStatus ?? 'none';
    if (status != 'none')
      return; // already uploaded (pending/verified/rejected)
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PassportPromptDialog(
        onUpload: () {
          Navigator.of(ctx).pop();
          context.push('/passport-upload');
        },
        onLater: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _loadTents() async {
    if (mounted) context.read<TentProvider>().loadTents();
  }

  void _filterByType(String? type) => setState(() => _selectedType = type);

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                    color: _kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Sort by',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark)),
            const SizedBox(height: 14),
            ...['Popular', 'Price: Low to High', 'Price: High to Low']
                .map((option) {
              final isSelected = _sortBy == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _sortBy = option);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _kGold.withValues(alpha: 0.08)
                          : _kBodyBg,
                      border: Border.all(color: isSelected ? _kGold : _kBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(option,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 14,
                                color: isSelected ? _kGold : _kTextMid)),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: _kGold, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TentProvider>();

    final displayTents = _searchQuery.isEmpty
        ? prov.tents
        : prov.tents.where((t) {
            final q = _searchQuery.toLowerCase();
            return t.location.toLowerCase().contains(q) ||
                t.tentType.toLowerCase().contains(q) ||
                t.tentNumber.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q);
          }).toList();

    final typedTents = _selectedType == null
        ? displayTents
        : displayTents
            .where(
                (t) => t.tentType.toLowerCase() == _selectedType!.toLowerCase())
            .toList();

    final sortedTents = List.of(typedTents);
    if (_sortBy == 'Price: Low to High') {
      sortedTents.sort((a, b) => a.price1Day.compareTo(b.price1Day));
    } else if (_sortBy == 'Price: High to Low') {
      sortedTents.sort((a, b) => b.price1Day.compareTo(a.price1Day));
    }

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: RefreshIndicator(
        color: _kGold,
        onRefresh: _loadTents,
        child: CustomScrollView(
          // Always scrollable, so the pull gesture works even when the list is
          // short enough not to overflow the screen.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero App Bar ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: _kBgDeep,
              elevation: 0,
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _kGold.withValues(alpha: 0.45), width: 1),
                  ),
                  child:
                      const Icon(Icons.temple_hindu, color: _kGold, size: 18),
                ),
                const SizedBox(width: 10),
                RichText(
                  text: const TextSpan(
                    text: 'One ',
                    style: TextStyle(
                        color: _kCream,
                        fontSize: 17,
                        fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: 'Tent',
                        style: TextStyle(
                            color: _kGold, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ]),
              actions: [
                IconButton(
                  icon:
                      const Icon(Icons.info_outline, color: _kCream, size: 22),
                  tooltip: 'History of Kumbh Mela',
                  onPressed: () => context.push('/kumbh-history'),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined,
                      color: _kCream, size: 22),
                  tooltip: 'Kumbh Calendar',
                  onPressed: () => context.push('/kumbh-calendar'),
                ),
                Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: _kCream, size: 22),
                    onPressed: () => context.push('/notifications'),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  ),
                ]),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero image
                    Image.asset(
                      'assets/images/kumbh_hero.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_kBgDeep, _kHeroBg],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _kBgDeep.withValues(alpha: 0.85),
                            _kBgDeep.withValues(alpha: 0.40),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    // Hero text
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Find Your',
                                style: AppFonts.display(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.1)),
                            RichText(
                              text: TextSpan(
                                text: 'Perfect ',
                                style: AppFonts.display(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.15),
                                children: [
                                  TextSpan(
                                    text: 'Stay',
                                    style: TextStyle(
                                        color: _kGold,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Comfortable stays for a spiritual journey',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _kGold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _kGold.withValues(alpha: 0.45)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on,
                                      color: _kGold, size: 13),
                                  SizedBox(width: 4),
                                  Text('Nashik, Kumbh',
                                      style: TextStyle(
                                          color: _kCream,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search Bar ────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: _kBgDeep,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: _kHeroBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kGold.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 14, color: _kCream),
                    cursorColor: _kGold,
                    decoration: InputDecoration(
                      // The global theme's filled:true paints a square fill that
                      // ignores this container's corner radius.
                      filled: false,
                      hintText: 'Search by location, tent type...',
                      hintStyle: TextStyle(
                          color: _kTextLight.withValues(alpha: 0.7),
                          fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: _kGold, size: 20),
                      // IconButton rather than a bare GestureDetector: it fills
                      // the suffix box, so taps landing just off the 20px glyph
                      // still register.
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close,
                                  color: _kTextLight, size: 20),
                              tooltip: 'Clear search',
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // ── Explore banners (auto-sliding) ────────────────
            SliverToBoxAdapter(
              child: Container(
                color: _kBodyBg,
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
                child: _ExploreBannerCarousel(banners: [
                  _ExploreBannerData(
                    label: 'Calendar',
                    subtitle: 'Important Mela dates',
                    color: _kGold,
                    imageAsset: 'assets/images/calendar_banner.jpg',
                    onTap: () => context.push('/kumbh-calendar'),
                  ),
                  _ExploreBannerData(
                    label: 'History',
                    subtitle: 'The story of Kumbh Mela',
                    color: const Color(0xFF6B1A00),
                    imageAsset: 'assets/images/history_banner.jpg',
                    onTap: () => context.push('/kumbh-history'),
                  ),
                  _ExploreBannerData(
                    label: 'News',
                    subtitle: 'Latest updates',
                    color: const Color(0xFF2E6E8C),
                    imageAsset: 'assets/images/news_banner.jpg',
                    onTap: () => context.go('/news'),
                  ),
                  _ExploreBannerData(
                    label: 'Offers',
                    subtitle: 'Special discounts for you',
                    color: const Color(0xFF2E7D32),
                    imageAsset: 'assets/images/offers_banner.jpg',
                    onTap: () => context.push('/offers'),
                  ),
                ]),
              ),
            ),

            // ── Popular Categories ────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: _kBodyBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Popular Categories',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextDark)),
                          GestureDetector(
                            // This used to just call _filterByType(null),
                            // which resets the home page's own category
                            // filter — a no-op (and so, felt "dead") on the
                            // common case where nothing was filtered yet.
                            // "View all" should actually take you to the
                            // full listing.
                            onTap: () => context.go('/search'),
                            child: const Text('View all',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _kGold)),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Row(
                        children: [
                          _categoryChip('All', null),
                          ...AppConstants.tentTypes.map((t) => _categoryChip(
                                t[0].toUpperCase() + t.substring(1),
                                t,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Count + Sort ──────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: _kBodyBg,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: '${sortedTents.length} ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kGold),
                        children: [
                          TextSpan(
                              text: 'stays available',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: _kTextMid)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _showSortBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          border: Border.all(color: _kBorder),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6),
                          ],
                        ),
                        child: const Row(children: [
                          Icon(Icons.tune, size: 15, color: _kGold),
                          SizedBox(width: 6),
                          Text('Sort',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextDark)),
                          SizedBox(width: 4),
                          Icon(Icons.expand_more, size: 15, color: _kGold),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                color: _kBodyBg,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Divider(height: 1, color: _kBorder),
              ),
            ),

            // ── Tent List ─────────────────────────────────────
            if (prov.isLoading)
              SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (_, __) => _shimmerCard(),
                      childCount: 4))
            else if (prov.error != null)
              SliverFillRemaining(
                child: Container(
                  color: _kBodyBg,
                  child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 50, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text(prov.error ?? 'Failed to load stays',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _kTextMid)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadTents,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Try Again'),
                          ),
                        ]),
                  ),
                ),
              )
            else if (sortedTents.isEmpty)
              SliverFillRemaining(
                child: Container(
                  color: _kBodyBg,
                  child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 50, color: _kTextLight),
                          const SizedBox(height: 12),
                          const Text('No stays found',
                              style: TextStyle(color: _kTextMid)),
                        ]),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TentCard(
                        tent: sortedTents[i],
                        index: i,
                        onTap: () => context.push('/tent/${sortedTents[i].id}',
                            extra: sortedTents[i]),
                      ),
                    ),
                    childCount: sortedTents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String? value) {
    final selected = _selectedType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 6),
      child: GestureDetector(
        onTap: () => _filterByType(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _kGold : _kGold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? _kGold : _kBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: _kGold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _kTextMid)),
        ),
      ),
    );
  }

  Widget _shimmerCard() => Shimmer.fromColors(
        baseColor: const Color(0xFFE8D5C4),
        highlightColor: const Color(0xFFF5E6C8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 320,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      );
}

// ── Explore banner data (Calendar / History / News / Offers) ───────────────
class _ExploreBannerData {
  const _ExploreBannerData({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.imageAsset,
  });

  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  /// Optional background photo. When set, [color] is still used as the
  /// gradient scrim over it (so text stays legible) rather than a flat fill.
  final String? imageAsset;
}

/// Auto-advancing carousel of [_ExploreBannerData], one full-width card at a
/// time with dot indicators — swipeable manually too, and the auto-advance
/// pauses for a few seconds after a manual swipe so it doesn't fight the user.
class _ExploreBannerCarousel extends StatefulWidget {
  const _ExploreBannerCarousel({required this.banners});
  final List<_ExploreBannerData> banners;

  @override
  State<_ExploreBannerCarousel> createState() => _ExploreBannerCarouselState();
}

class _ExploreBannerCarouselState extends State<_ExploreBannerCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.88);
  Timer? _autoTimer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.banners.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 108,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            // A manual swipe shouldn't get immediately yanked back by the
            // timer — restart it so the user gets a full interval first.
            onPageChanged: (i) {
              setState(() => _page = i);
              _startAutoSlide();
            },
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _ExploreBannerCard(data: widget.banners[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _kGold : _kBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ExploreBannerCard extends StatelessWidget {
  const _ExploreBannerCard({required this.data});
  final _ExploreBannerData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: data.color.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (data.imageAsset != null)
                Image.asset(data.imageAsset!, fit: BoxFit.cover)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [data.color, data.color.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              // Scrim so the label/subtitle stay legible over a photo — kept
              // (lighter) on the flat-color cards too for a consistent look.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      data.color.withValues(
                          alpha: data.imageAsset != null ? 0.80 : 0.35),
                      data.color.withValues(
                          alpha: data.imageAsset != null ? 0.55 : 0.10),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(data.subtitle,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Passport Upload Prompt (shown once, right after email verification) ────
class _PassportPromptDialog extends StatelessWidget {
  final VoidCallback onUpload;
  final VoidCallback onLater;
  const _PassportPromptDialog({required this.onUpload, required this.onLater});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kGold.withValues(alpha: 0.4)),
              ),
              child:
                  const Icon(Icons.badge_outlined, color: _kGold, size: 30),
            ),
            const SizedBox(height: 18),
            const Text(
              'Email verified! 🎉',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _kTextDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'One more step before you can check in: upload your passport '
              'so our staff can verify it ahead of your stay.',
              style: TextStyle(fontSize: 13.5, color: _kTextMid, height: 1.45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onUpload,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _kHeroBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kGold.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                          color: _kHeroBg.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_rounded, color: _kGold, size: 17),
                      SizedBox(width: 8),
                      Text('Upload Passport',
                          style: TextStyle(
                              color: _kCream,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: onLater,
              child: const Text('Later',
                  style: TextStyle(
                      color: _kTextMid,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
