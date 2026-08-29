import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_utils.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/handcrafted.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const _kHeroBg       = Color(0xFF4A1000);   // dark maroon hero
const _kMaroonMid    = Color(0xFF6B1A00);
const _kBodyBg       = Color(0xFFF2EAE0);   // warm cream body
const _kCardBg       = Color(0xFFFFFFFF);
const _kGold         = Color(0xFFD4891A);
const _kGoldLight    = Color(0xFFE8A93A);
const _kBorderLight  = Color(0xFFDDD0C4);
const _kTextDark     = Color(0xFF2D0F05);
const _kTextMid      = Color(0xFF7A4A30);
const _kTextLight    = Color(0xFFA07050);
const _kCream        = Color(0xFFF5E6C8);
const _kSuccess      = Color(0xFF2E7D32);
const _kError        = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

const _uspHighlights = [
  {'icon': Icons.privacy_tip_rounded,       'label': 'Private & Peaceful',   'color': Color(0xFF7A1F0A)},
  {'icon': Icons.bolt_rounded,              'label': 'Smart & Sustainable',  'color': Color(0xFF2E7D32)},
  {'icon': Icons.health_and_safety_rounded, 'label': 'Secure & Hygienic',    'color': Color(0xFF6B1A00)},
  {'icon': Icons.temple_hindu_rounded,      'label': 'Culturally Immersive', 'color': Color(0xFFD4891A)},
];

const _ecoFeatures = [
  {'icon': Icons.solar_power_rounded, 'label': 'Solar Powered'},
  {'icon': Icons.water_drop_rounded,  'label': 'Water Saving'},
  {'icon': Icons.recycling_rounded,   'label': 'Low Waste Living'},
];

const _safetyFeatures = [
  {'icon': Icons.security_rounded,      'label': '24/7 Security'},
  {'icon': Icons.videocam_rounded,      'label': 'CCTV Monitoring'},
  {'icon': Icons.lock_rounded,          'label': 'Smart Access Control'},
  {'icon': Icons.support_agent_rounded, 'label': 'On-call Assistance'},
];

const _travelerTypes = [
  {'icon': Icons.person_rounded,           'label': 'Solo Travelers'},
  {'icon': Icons.people_rounded,           'label': 'Couples'},
  {'icon': Icons.laptop_rounded,           'label': 'Digital Nomads'},
  {'icon': Icons.self_improvement_rounded, 'label': 'Pilgrims'},
];

const _interiorFeatures = [
  {'icon': Icons.bed_rounded,               'label': 'Ergonomic Bed',     'sub': 'Premium Linens'},
  {'icon': Icons.ac_unit_rounded,           'label': 'AC / Heating',      'sub': 'Climate Control'},
  {'icon': Icons.wifi_rounded,              'label': 'High-Speed WiFi',   'sub': '& Charging Ports'},
  {'icon': Icons.shower_rounded,            'label': 'Private Bathroom',  'sub': 'Hot Shower'},
  {'icon': Icons.lock_rounded,              'label': 'Smart Lock',        'sub': '24/7 Security'},
  {'icon': Icons.desk_rounded,              'label': 'Work & Relax Desk', 'sub': 'Quiet Area'},
  {'icon': Icons.solar_power_rounded,       'label': 'Eco-Friendly',      'sub': 'Solar Powered'},
  {'icon': Icons.cleaning_services_rounded, 'label': 'Housekeeping',      'sub': 'Daily + Laundry'},
];

// Product-style photo gallery — the real unit photos + spec sheets, in the
// order a buyer would want to see them: exterior, dimensions, build quality,
// interior, then the expandable/modular option.
const _galleryImages = [
  'assets/images/tent_gallery_1.png',
  'assets/images/tent_gallery_2.png',
  'assets/images/tent_gallery_3.png',
  'assets/images/tent_gallery_4.png',
  'assets/images/tent_gallery_5.png',
];

class TentDetailScreen extends StatefulWidget {
  final CapsuleTent tent;
  const TentDetailScreen({super.key, required this.tent});

  @override
  State<TentDetailScreen> createState() => _TentDetailScreenState();
}

class _TentDetailScreenState extends State<TentDetailScreen> {
  final _galleryCtrl = PageController();
  int _galleryPage = 0;
  TentReviewSummary _reviews = const TentReviewSummary();
  bool _reviewsLoading = true;

  CapsuleTent get tent => widget.tent;

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
    _galleryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      body: CustomScrollView(
        slivers: [

          // ── Hero gallery ─────────────────────────────────────────────
          // Plain SliverToBoxAdapter, not SliverAppBar.flexibleSpace — a
          // PageView nested inside FlexibleSpaceBar loses horizontal swipe
          // gestures to the SliverAppBar's own collapse/expand gesture
          // handling, so guests could only advance by tapping a dot. This
          // way the PageView owns its gesture arena outright.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: Stack(fit: StackFit.expand, children: [
                PageView.builder(
                  controller: _galleryCtrl,
                  itemCount: _galleryImages.length,
                  onPageChanged: (i) => setState(() => _galleryPage = i),
                  itemBuilder: (_, i) => Image.asset(
                    _galleryImages[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kHeroBg, _kMaroonMid],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.cabin, size: 60, color: _kGold),
                    ),
                  ),
                ),
                // Bottom scrim so the app bar title/back button and the dot
                // indicator both stay legible over a bright photo.
                const Positioned(
                  left: 0, right: 0, bottom: 0,
                  height: 90,
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
                // Page dots
                Positioned(
                  bottom: 14,
                  left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_galleryImages.length, (i) {
                      final active = i == _galleryPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? _kGold
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                // "2 / 5" counter, ecommerce-gallery style — sits below the
                // back/wishlist row now that this isn't inside an app bar.
                Positioned(
                  top: MediaQuery.of(context).padding.top + 56,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_galleryPage + 1} / ${_galleryImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Back + wishlist — floating over the gallery, same as they
                // used to sit in the app bar's leading/actions slots.
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGold.withValues(alpha: 0.40)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: _kCream),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGold.withValues(alpha: 0.40)),
                    ),
                    child: _WishlistHeartButton(tent: tent),
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

                  // ── Name + status ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tent.name,
                              style: AppFonts.display(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextDark),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kGold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _kGold.withValues(alpha: 0.35)),
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
                          ],
                        ),
                      ),
                      _statusBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Highlighted bed configuration ─────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kHeroBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGold.withValues(alpha: 0.5)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.bed_rounded, size: 18, color: _kGold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tent.bedLabel == 'Single Bed'
                              ? 'Single Bed — perfect for solo travelers'
                              : 'Double Bed — ideal for couples or friends',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Location & capacity ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorderLight),
                      boxShadow: [
                        BoxShadow(
                            color: _kHeroBg.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _kGold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on,
                                  size: 18, color: _kGold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Location',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _kTextLight,
                                            fontWeight: FontWeight.w500)),
                                    Text(tent.location,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _kTextDark)),
                                  ]),
                            ),
                          ]),
                          Divider(height: 16, color: _kBorderLight),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _detailItem(
                                    icon: Icons.straighten,
                                    label: 'Size',
                                    value: '2.0m × 2.2m × 1.8m'),
                                _detailItem(
                                    icon: Icons.people,
                                    label: 'Capacity',
                                    value: '${tent.maxOccupancy} guests'),
                              ]),
                        ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Why One Tent? ────────────────────────────────
                  _sectionHeader(context, Icons.star_rounded, 'Why One Tent?'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3.5,
                    children: _uspHighlights.map((h) {
                      final color = h['color'] as Color;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Row(children: [
                          Icon(h['icon'] as IconData, size: 15, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              h['label'] as String,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Interiors ─────────────────────────────────────────
                  _sectionHeader(context, Icons.home_rounded, 'Interiors That Feel Like Home'),
                  const SizedBox(height: 6),
                  Text(
                    'Every capsule is crafted with soft lighting, natural textures, and intelligent design to help you relax, recharge, and reconnect.',
                    style: TextStyle(fontSize: 13, color: _kTextMid, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.9,
                    children: _interiorFeatures.map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorderLight),
                        boxShadow: [
                          BoxShadow(
                              color: _kHeroBg.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(a['icon'] as IconData,
                              size: 14, color: _kGold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(a['label'] as String,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _kTextDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(a['sub'] as String,
                                  style: const TextStyle(
                                      fontSize: 9, color: _kTextLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ]),
                    )).toList(),
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

                  // ── Safety ────────────────────────────────────────────
                  _sectionHeader(context, Icons.shield_rounded, 'Safe, Secure & Worry-Free'),
                  const SizedBox(height: 6),
                  Text(
                    'Your safety is our priority with 24/7 security, CCTV surveillance, and smart access systems.',
                    style: TextStyle(fontSize: 13, color: _kTextMid, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kSuccess.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: _safetyFeatures.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: _kSuccess.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(s['icon'] as IconData,
                                size: 14, color: _kSuccess),
                          ),
                          const SizedBox(width: 12),
                          Text(s['label'] as String,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: _kTextDark,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Eco ───────────────────────────────────────────────
                  _sectionHeader(context, Icons.eco_rounded, 'Sustainable & Future-Ready'),
                  const SizedBox(height: 6),
                  Text(
                    'Our capsules are built with eco-friendly materials and solar energy, minimising environmental impact while maximising comfort.',
                    style: TextStyle(fontSize: 13, color: _kTextMid, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _kSuccess.withValues(alpha: 0.07),
                        _kSuccess.withValues(alpha: 0.03),
                      ]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kSuccess.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: _ecoFeatures.map((e) => Expanded(
                        child: Column(children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                shape: BoxShape.circle),
                            child: Icon(e['icon'] as IconData,
                                size: 20, color: _kSuccess),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e['label'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: _kSuccess,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Traveler types ────────────────────────────────────
                  _sectionHeader(context, Icons.travel_explore_rounded, 'For Global Travelers'),
                  const SizedBox(height: 6),
                  Text(
                    'From solo explorers to digital nomads, our capsules are perfect for anyone seeking a unique, comfortable, and meaningful Kumbh experience.',
                    style: TextStyle(fontSize: 13, color: _kTextMid, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _travelerTypes.map((t) => Expanded(
                      child: Column(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(t['icon'] as IconData,
                              size: 20, color: _kGold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 10,
                              color: _kTextMid,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                        ),
                      ]),
                    )).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Pricing ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kGold.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                            color: _kHeroBg.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _kGold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_offer,
                                  size: 20, color: _kGold),
                            ),
                            const SizedBox(width: 12),
                            Text('Pricing',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _kTextDark)),
                          ]),
                          const SizedBox(height: 16),
                          _priceRow(context, '1 Day',   tent.price1Day),
                          _priceRow(context, '3 Days',  tent.price3Days),
                          _priceRow(context, '7 Days',  tent.price7Days),
                          _priceRow(context, '15 Days', tent.price15Days),
                          _priceRow(context, '30 Days', tent.price30Days),
                        ]),
                  ),
                  const SizedBox(height: 24),

                  // ── About ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGold.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.info_outline,
                                size: 20, color: _kGold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('About this tent',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _kGold)),
                                const SizedBox(height: 6),
                                Text(
                                  tent.description.isNotEmpty
                                      ? tent.description
                                      : 'This premium capsule tent offers comfort and convenience for your Kumbh Mela experience.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _kTextMid,
                                      height: 1.5),
                                ),
                              ])),
                        ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Reviews ────────────────────────────────────────────
                  _ReviewsSection(loading: _reviewsLoading, summary: _reviews),
                  const SizedBox(height: 28),

                  // ── Book button ───────────────────────────────────────
                  if (tent.isAvailable)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/book', extra: tent),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kHeroBg,
                          foregroundColor: _kCream,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                            side: BorderSide(
                                color: _kGold.withValues(alpha: 0.6), width: 1.5),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward, color: _kGold, size: 18),
                        label: const Text(
                          'Book This Tent Now',
                          style: TextStyle(
                              color: _kCream,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4),
                        ),
                      ),
                    )
                  else
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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

  Widget _amenityChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _kGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kGold.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: _kGold),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: _kGold, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _priceRow(BuildContext context, String label, double price) {
    final currency = CurrencyUtils.currencyForCountry(
        context.watch<AuthProvider>().visitor?.country);
    final rates = context.watch<TentProvider>().exchangeRates;
    final priceLabel =
        CurrencyUtils.formatPrice(price, currency: currency, rates: rates);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    color: _kTextMid,
                    fontWeight: FontWeight.w500)),
            // Flexible so a longer converted amount (multi-day AED/EUR
            // totals get long) shrinks and ellipsizes instead of
            // overflowing this row.
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kGold.withValues(alpha: 0.30)),
                ),
                child: Text(priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kGold)),
              ),
            ),
          ]),
    );
  }

  Widget _detailItem(
          {required IconData icon,
          required String label,
          required String value}) =>
      Column(children: [
        Icon(icon, color: _kGold, size: 20),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: _kTextLight,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextDark),
            textAlign: TextAlign.center),
      ]);

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
// ── Wishlist heart ───────────────────────────────────────────────────────────
// Its own widget so the (stateless) detail screen doesn't need to rebuild
// wholesale, and so the saved state survives coming back to this screen.
class _WishlistHeartButton extends StatefulWidget {
  const _WishlistHeartButton({required this.tent});

  final CapsuleTent tent;

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
        color: saved ? _kError : _kCream,
      ),
      tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
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
