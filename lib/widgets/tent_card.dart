import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../core/utils/currency_utils.dart';
import '../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const _kMaroon = Color(0xFF4A1000);
const _kGold = Color(0xFFD4891A);
const _kBorderLight = Color(0xFFDDD0C4);
const _kTextDark = Color(0xFF2D0F05);
const _kTextMid = Color(0xFF7A4A30);
const _kTextLight = Color(0xFFA07050);
const _kSuccess = Color(0xFF2E7D32);
const _kError = Color(0xFFC0392B);
// ─────────────────────────────────────────────────────────────────────────────

// Placeholder cover shots used only until a tent has a real admin-uploaded
// photo (image_urls is empty for every tent right now) — same bundled
// gallery assets used as the detail screen's fallback gallery, picked
// deterministically per tent so a given tent's card always shows the same
// shot instead of flickering between them on rebuild.
const _fallbackCovers = [
  'assets/images/tent_gallery_1.png',
  'assets/images/tent_gallery_2.png',
  'assets/images/tent_gallery_3.png',
  'assets/images/tent_gallery_4.png',
  'assets/images/tent_gallery_5.png',
];

/// Photo-forward listing card — hero image up top, name/location/amenity
/// pills below, price + CTA on the last row. Shows the tent's first real
/// photo when the admin has uploaded one, otherwise a stand-in gallery shot.
class TentCard extends StatelessWidget {
  final CapsuleTent tent;
  final VoidCallback onTap;

  /// Position in the list it's rendered from, used to stagger the entrance
  /// animation. 0 (the default) plays immediately with no delay.
  final int index;

  const TentCard({
    super.key,
    required this.tent,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Driven off the guest's registered country rather than a manual
    // picker — an India-based guest still sees ₹ everywhere, unchanged.
    final currency = CurrencyUtils.currencyForCountry(
        context.watch<AuthProvider>().visitor?.country);
    final rates = context.watch<TentProvider>().exchangeRates;
    final priceLabel = CurrencyUtils.formatPrice(tent.price1Day,
        currency: currency, rates: rates);

    final wishlist = context.watch<WishlistProvider>();
    final isSaved = wishlist.isSaved(tent.id);
    final isVip = tent.tentType.toLowerCase() == 'deluxe';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: _kMaroon.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero photo ────────────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 11,
                  child: (tent.imageUrl == null || tent.imageUrl!.isEmpty)
                      ? Image.asset(_fallbackCovers[0], fit: BoxFit.cover)
                      : Image.network(
                          AppConstants.fileUrl(tent.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _imagePlaceholder(loading: true);
                          },
                        ),
                ),
                // Bottom gradient so any badges/text sitting on the photo
                // edge stay legible regardless of what's in the shot.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                if (isVip)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _pillBadge('VIP', _kMaroon, Colors.white),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => wishlist.toggle(tent),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isSaved ? _kError : _kTextMid,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: _statusBadge(),
                ),
              ],
            ),

            // ── Details ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tent.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                      color: _kTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: _kTextLight),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        tent.location,
                        style: const TextStyle(
                            fontSize: 12.5, color: _kTextLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Amenity pills — outline chips, matching the "AC ·
                  // Private Bath · Butler" strip style, built from
                  // whatever this tent actually has (never fabricated).
                  if (tent.amenities.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tent.amenities
                          .take(4)
                          .map((a) => _amenityPill(a))
                          .toList(),
                    ),
                  const SizedBox(height: 14),

                  // Price + CTA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('From',
                                style: TextStyle(
                                    fontSize: 11, color: _kTextLight)),
                            Text(
                              '$priceLabel/night',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _kTextDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGold,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Details',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        // Staggered by list position so cards settle in one after another
        // instead of the whole list popping in at once.
        .animate(delay: (55 * index).ms)
        .fadeIn(duration: 320.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.08, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
  }

  Widget _imagePlaceholder({bool loading = false}) => Container(
        color: _kGold.withValues(alpha: 0.10),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kGold),
              )
            : const Icon(Icons.cabin, color: _kGold, size: 40),
      );

  Widget _pillBadge(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
      );

  Widget _statusBadge() {
    final color = tent.isAvailable ? _kSuccess : _kError;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        tent.isAvailable ? 'Available' : 'Booked',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _amenityPill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _kGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorderLight),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: _kTextMid),
        ),
      );
}
