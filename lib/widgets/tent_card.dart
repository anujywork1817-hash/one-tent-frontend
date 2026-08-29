import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../core/utils/currency_utils.dart';
import '../providers/providers.dart';
import 'handcrafted.dart';

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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: handDrawnRadius(base: 16, seed: index),
          border: Border.all(color: _kBorderLight, width: 1.2),
          boxShadow: stickerShadow(_kMaroon.withValues(alpha: 0.13)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Tent icon box ──────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.12),
                  borderRadius: handDrawnRadius(base: 14, seed: index + 1),
                  border: Border.all(color: _kGold.withValues(alpha: 0.30)),
                ),
                child: const Icon(Icons.cabin, color: _kGold, size: 32),
              ),
              const SizedBox(width: 14),

              // ── Details ────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tent.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _kTextDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Tent type
                    Text(
                      tent.tentType.toUpperCase(),
                      style: const TextStyle(
                        color: _kGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Highlighted bed configuration
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kMaroon,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.bed_rounded,
                            size: 12, color: _kGold),
                        const SizedBox(width: 4),
                        Text(
                          tent.bedLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 6),

                    // Location
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: _kTextLight),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          tent.location,
                          style:
                              const TextStyle(fontSize: 12, color: _kTextLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    // Amenities + price — each icon borrows a different
                    // accent color rather than repeating one muted tone.
                    Row(children: [
                      if (tent.hasAC)
                        _amenityIcon(Icons.ac_unit, AppPalette.accentFor(0)),
                      if (tent.hasWifi)
                        _amenityIcon(Icons.wifi, AppPalette.accentFor(1)),
                      if (tent.hasBathroom)
                        _amenityIcon(
                            Icons.shower_outlined, AppPalette.accentFor(2)),
                      if (tent.hasTV)
                        _amenityIcon(
                            Icons.tv_outlined, AppPalette.accentFor(3)),
                      if (!tent.hasAC &&
                          !tent.hasWifi &&
                          !tent.hasBathroom &&
                          !tent.hasTV)
                        _amenityIcon(Icons.people_outline, _kTextMid),
                      const Spacer(),
                      // Flexible so a longer converted price (e.g. "AED
                      // 66.37/day" vs. the old fixed "₹1500/day") shrinks
                      // and ellipsizes instead of overflowing the row.
                      Flexible(
                        child: Tilt(
                          degrees: index.isEven ? -2 : 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kGold.withValues(alpha: 0.10),
                              borderRadius:
                                  handDrawnRadius(base: 20, seed: index + 2),
                              border: Border.all(
                                  color: _kGold.withValues(alpha: 0.30)),
                            ),
                            child: Text(
                              '$priceLabel/day',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _kGold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _statusBadge() {
    final color = tent.isAvailable ? _kSuccess : _kError;
    return Tilt(
      degrees: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: handDrawnRadius(base: 10, seed: 3),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: stickerShadow(color.withValues(alpha: 0.18), dx: 2, dy: 2),
        ),
        child: Text(
          tent.isAvailable ? 'Available' : 'Booked',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _amenityIcon(IconData icon, Color color) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(icon, size: 15, color: color),
      );
}
