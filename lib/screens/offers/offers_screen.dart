import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

const _kHeroBg      = Color(0xFF3D0F05);
const _kBodyBg      = Color(0xFFF2EAE0);
const _kCardBg      = Color(0xFFFFFFFF);
const _kGold        = Color(0xFFD4891A);
const _kBorderLight = Color(0xFFDDD0C4);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextMid     = Color(0xFF7A4A30);
const _kTextLight   = Color(0xFFA07050);
const _kCream       = Color(0xFFF5E6C8);

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final _repo = OffersRepository();

  List<Offer> _offers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = _offers.isEmpty; _error = null; });
    try {
      final offers = await _repo.list();
      if (!mounted) return;
      setState(() { _offers = offers; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      appBar: AppBar(
        backgroundColor: _kHeroBg,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kGold.withValues(alpha: 0.45)),
            ),
            child: const Icon(Icons.local_offer_outlined, color: _kGold, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Offers',
              style: TextStyle(
                  color: _kCream, fontWeight: FontWeight.w600, fontSize: 17)),
        ]),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _kGold, strokeWidth: 2));
    }

    if (_error != null && _offers.isEmpty) {
      return _refreshable(_message(
        icon: Icons.error_outline,
        title: 'Could not load offers',
        subtitle: _error!,
      ));
    }

    if (_offers.isEmpty) {
      return _refreshable(_message(
        icon: Icons.local_offer_outlined,
        title: 'No offers right now',
        subtitle: 'Check back soon for discounts and seasonal promotions.',
      ));
    }

    return RefreshIndicator(
      color: _kGold,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        itemBuilder: (_, i) => _OfferCard(offer: _offers[i]),
      ),
    );
  }

  /// Wraps a non-scrolling state so it fills the viewport and can be pulled
  /// — the empty/error states are exactly when someone is likely to refresh.
  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      color: _kGold,
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: _kGold),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5, color: _kTextMid, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderLight),
        boxShadow: [
          BoxShadow(
              color: _kHeroBg.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
              Stack(children: [
                Image.network(
                  AppConstants.fileUrl(offer.imageUrl!),
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                if (offer.discountText != null)
                  Positioned(
                    top: 10, right: 10,
                    child: _discountChip(),
                  ),
              ]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(offer.title,
                          style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: _kTextDark)),
                    ),
                    if (offer.imageUrl == null || offer.imageUrl!.isEmpty)
                      if (offer.discountText != null) _discountChip(),
                  ]),
                  const SizedBox(height: 6),
                  Text(offer.description,
                      style: const TextStyle(
                          fontSize: 13.5, color: _kTextMid, height: 1.5)),
                  if (offer.validUntil != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.event_busy,
                          size: 12, color: _kTextLight),
                      const SizedBox(width: 4),
                      Text(
                        'Valid until ${DateFormat('MMM dd, yyyy').format(offer.validUntil!)}',
                        style: const TextStyle(
                            fontSize: 11.5, color: _kTextLight),
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

  Widget _discountChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _kHeroBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGold.withValues(alpha: 0.6)),
        ),
        child: Text(offer.discountText!,
            style: const TextStyle(
                color: _kGold,
                fontSize: 11.5,
                fontWeight: FontWeight.w700)),
      );
}
