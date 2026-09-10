import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/tent_card.dart';

const _kBodyBg      = Color(0xFFFFFFFF);
const _kCardBg      = Color(0xFFFFFFFF);
const _kBorderLight = Color(0xFFDDD0C4);
const _kGold        = Color(0xFFD4891A);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextMid     = Color(0xFF7A4A30);
const _kError       = Color(0xFFC0392B);

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    // Force a refresh: a tent saved on another screen (or removed on another
    // device) should be reflected when this screen is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WishlistProvider>().load(force: true);
    });
  }

  Future<void> _remove(CapsuleTent tent) async {
    final wishlist = context.read<WishlistProvider>();
    await wishlist.toggle(tent);
    if (!mounted) return;

    final failed = wishlist.error != null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(failed ? wishlist.error! : 'Removed from your wishlist',
          style: const TextStyle(color: Colors.white)),
      backgroundColor: failed ? _kError : _kTextDark,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: _kBodyBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        surfaceTintColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _kTextDark, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Wishlist',
            style: TextStyle(
                color: _kTextDark, fontWeight: FontWeight.w700, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorderLight),
        ),
      ),
      body: _body(wishlist),
    );
  }

  Widget _body(WishlistProvider wishlist) {
    if (wishlist.isLoading && wishlist.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _kGold, strokeWidth: 2));
    }

    // Empty and error states are pull-to-refresh too — they're the states a
    // guest is most likely to want to retry from.
    if (wishlist.error != null && wishlist.isEmpty) {
      return _refreshable(
        wishlist,
        _message(
          icon: Icons.error_outline,
          title: 'Could not load your wishlist',
          subtitle: wishlist.error!,
          action: FilledButton(
            onPressed: () => wishlist.load(force: true),
            style: FilledButton.styleFrom(backgroundColor: _kGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Try again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    if (wishlist.isEmpty) {
      return _refreshable(
        wishlist,
        _message(
          icon: Icons.favorite_border,
          title: 'No saved tents yet',
          subtitle: 'Tap the heart on any tent to save it here for later.',
          action: FilledButton(
            onPressed: () => context.go('/search'),
            style: FilledButton.styleFrom(backgroundColor: _kGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Browse tents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _kGold,
      onRefresh: () => wishlist.load(force: true),
      child: ListView.builder(
        // Without this the pull is ignored whenever the list is too short
        // to scroll.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: wishlist.tents.length,
        itemBuilder: (_, i) {
          final tent = wishlist.tents[i];
          return Stack(children: [
            TentCard(
              tent: tent,
              index: i,
              onTap: () => context.push('/tent/${tent.id}', extra: tent),
            ),
            Positioned(
              top: 8, right: 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.favorite, color: _kError),
                  tooltip: 'Remove from wishlist',
                  onPressed: () => _remove(tent),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  /// Wraps a non-scrolling state so it fills the viewport and can be pulled.
  Widget _refreshable(WishlistProvider wishlist, Widget child) {
    return RefreshIndicator(
      color: _kGold,
      onRefresh: () => wishlist.load(force: true),
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
    required Widget action,
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
            const SizedBox(height: 22),
            action,
          ],
        ),
      ),
    );
  }
}
