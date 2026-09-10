import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

// ─────────────────────────────────────────────
//  One Tent — Split Theme Tokens
// ─────────────────────────────────────────────
const _kBodyBg       = Color(0xFFFFFFFF);   // warm cream body
const _kCardBg       = Color(0xFFFFFFFF);   // white cards
const _kChipBg       = Color(0xFFEDE0D4);   // beige icon bg
const _kBorderLight  = Color(0xFFDDD0C4);   // light border
const _kGold         = Color(0xFFD4891A);   // gold accent
const _kMaroon       = Color(0xFF5C1A08);   // maroon icons/text
const _kTextDark     = Color(0xFF2D0F05);   // headings
const _kTextMid      = Color(0xFF7A4A30);   // body text
const _kTextLight    = Color(0xFFA07050);   // muted / hint
const _kCream        = Color(0xFFF5E6C8);   // text on dark hero
const _kErrorColor   = Color(0xFFC0392B);   // error / sign out

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());
  }

  Future<void> _refreshProfile() async {
    if (!mounted) return;
    await context.read<AuthProvider>().refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final v    = auth.visitor;

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: RefreshIndicator(
        color: _kGold,
        onRefresh: _refreshProfile,
        child: CustomScrollView(
        // Always scrollable, so the gesture is available even when the
        // content is short enough not to overflow.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [

          // ── Header — same plain white chrome as every other screen ──
          SliverAppBar(
            pinned: true,
            backgroundColor: _kCardBg,
            surfaceTintColor: _kCardBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('Profile',
                style: TextStyle(
                    color: _kTextDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 17)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _kBorderLight),
            ),
          ),

          // ── Body ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: _kBodyBg,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Avatar + name card ────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            color: _kChipBg,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: _kMaroon.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: (v?.profileImageUrl != null &&
                                    v!.profileImageUrl!.isNotEmpty)
                                ? Image.network(
                                    AppConstants.fileUrl(v.profileImageUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _avatarFallback(v.fullName))
                                : _avatarFallback(v?.fullName ?? '?'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          v?.fullName.isNotEmpty == true
                              ? v!.fullName
                              : 'Loading...',
                          style: const TextStyle(
                              color: _kTextDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v?.email ?? '',
                          style: const TextStyle(
                              color: _kTextLight, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user,
                                  color: _kGold, size: 12),
                              SizedBox(width: 5),
                              Text('One Tent',
                                  style: TextStyle(
                                      color: _kGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Unverified email banner ───────────────
                  if (v != null && !v.emailVerified) ...[
                    GestureDetector(
                      onTap: () => context.push('/verify-email'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.mark_email_unread_outlined,
                              color: _kGold, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Verify your email to unlock booking',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextDark),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: _kGold, size: 18),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Personal Information ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Personal Information',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kTextDark)),
                      // ── Edit Profile button ──
                      GestureDetector(
                        onTap: () => context.push('/edit-profile'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.edit_outlined,
                                  color: _kGold, size: 14),
                              SizedBox(width: 5),
                              Text('Edit',
                                  style: TextStyle(
                                      color: _kGold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _infoCard([
                    _InfoRow(Icons.phone_outlined, 'Phone',
                        v?.phone.isNotEmpty == true ? v!.phone : '—',
                        true),
                    _InfoRow(Icons.flag_outlined, 'Nationality',
                        v?.nationality.isNotEmpty == true
                            ? v!.nationality
                            : '—',
                        true),
                    _InfoRow(Icons.public, 'Country',
                        v?.country.isNotEmpty == true
                            ? v!.country
                            : '—',
                        true),
                    _InfoRow(
                        Icons.badge_outlined,
                        'Passport',
                        _maskPassport(v?.passportNumber ?? ''),
                        false),
                  ]),

                  const SizedBox(height: 28),

                  // ── Account ───────────────────────────────
                  const Text('Account',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark)),
                  const SizedBox(height: 14),

                  _menuTile(context,
                      icon: Icons.book_online_outlined,
                      label: 'My Bookings',
                      subtitle: 'View your tent bookings',
                      onTap: () => context.go('/my-bookings')),
                  const SizedBox(height: 10),
                  _menuTile(context,
                      icon: Icons.favorite_outline,
                      label: 'My Wishlist',
                      subtitle: 'Tents you saved for later',
                      onTap: () => context.push('/wishlist')),
                  const SizedBox(height: 10),
                  _menuTile(context,
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      subtitle: 'Booking and payment updates',
                      onTap: () => context.push('/notifications')),
                  const SizedBox(height: 10),
                  _menuTile(context,
                      icon: Icons.badge_outlined,
                      label: 'Passport Verification',
                      subtitle: 'Upload passport for foreign visitors',
                      onTap: () => context.push('/passport-upload')),
                  const SizedBox(height: 10),
                  _menuTile(context,
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      subtitle: 'Contact us for assistance',
                      onTap: () => context.push('/help-support')),
                  const SizedBox(height: 10),
                  _menuTile(context,
                      icon: Icons.star_outline,
                      label: 'Rate & Review',
                      // App-level rating: 5 stars, then either straight to
                      // the Play Store (4-5★) or an in-app feedback box
                      // (lower ratings) instead of a public store review.
                      // A specific stay is still reviewed from that
                      // booking's own detail page.
                      subtitle: 'Rate One Tent on the Play Store',
                      onTap: () => context.push('/rate-app')),

                  const SizedBox(height: 28),

                  // ── Sign Out ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout,
                          size: 18, color: _kCream),
                      label: const Text('Sign Out',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: _kCream)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kErrorColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                      ),
                      onPressed: () => _confirmSignOut(context, auth),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text('One Tent v1.0.0',
                        style: const TextStyle(
                            color: _kTextLight, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // ── Sign out confirmation dialog ────────────────────────
  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _kTextDark)),
        content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: _kTextMid)),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Cancel',
                style: TextStyle(color: _kMaroon)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kErrorColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              ctx.pop();
              // Clear first: saved tents belong to the session being ended.
              context.read<WishlistProvider>().clear();
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Avatar fallback ─────────────────────────────────────
  Widget _avatarFallback(String name) {
    return Container(
      color: _kChipBg,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: _kGold),
        ),
      ),
    );
  }

  // ── Passport masking ────────────────────────────────────
  String _maskPassport(String p) {
    if (p.isEmpty) return '—';
    if (p.length <= 4) return p;
    return '${'*' * (p.length - 4)}${p.substring(p.length - 4)}';
  }

  // ── Info card ───────────────────────────────────────────
  Widget _infoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _kMaroon.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: rows.map((r) => Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kChipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(r.icon,
                    color: _kMaroon, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: _kTextLight,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(r.value,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark)),
                  ],
                ),
              ),
            ]),
          ),
          if (r.showDivider)
            Divider(height: 0, color: _kBorderLight),
        ])).toList(),
      ),
    );
  }

  // ── Menu tile ───────────────────────────────────────────
  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: _kMaroon.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kChipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kMaroon, size: 22),
          ),
          title: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _kTextDark,
                  fontSize: 14)),
          subtitle: Text(subtitle,
              style: const TextStyle(
                  color: _kTextLight, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right,
              color: _kTextLight, size: 20),
        ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String   label;
  final String   value;
  final bool     showDivider;
  const _InfoRow(this.icon, this.label, this.value, this.showDivider);
}