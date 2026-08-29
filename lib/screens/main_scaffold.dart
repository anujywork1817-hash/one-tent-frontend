import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'bookings/my_bookings_screen.dart';
import 'news/news_screen.dart';
import 'profile/profile_screen.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const _kMaroon  = Color(0xFF4A1000);
const _kGold    = Color(0xFFD4891A);
const _kTextMid = Color(0xFF7A4A30);
const _kBorder  = Color(0xFFDDD0C4);
// ─────────────────────────────────────────────────────────────────────────────

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const MyBookingsScreen(),
    const NewsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Loaded once here rather than per-screen so every price shown anywhere
    // in the app (tent cards, tent detail, checkout) can convert to the
    // guest's currency as soon as they land past login.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<TentProvider>().loadExchangeRates());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder, width: 1)),
          boxShadow: [
            BoxShadow(
              color: _kMaroon.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            // Expanded rather than a fixed-width Row: five tabs at the old
            // fixed 72px each stop fitting on narrow phones (< 360dp), which
            // would overflow. This always divides the available width evenly.
            child: Row(
              children: [
                Expanded(child: _NavItem(icon: Icons.home_outlined,         activeIcon: Icons.home,            label: 'Home',     index: 0, currentIndex: _currentIndex, onTap: () => setState(() => _currentIndex = 0))),
                Expanded(child: _NavItem(icon: Icons.search_outlined,       activeIcon: Icons.search,          label: 'Search',   index: 1, currentIndex: _currentIndex, onTap: () => setState(() => _currentIndex = 1))),
                Expanded(child: _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Bookings', index: 2, currentIndex: _currentIndex, onTap: () => setState(() => _currentIndex = 2))),
                Expanded(child: _NavItem(icon: Icons.campaign_outlined,     activeIcon: Icons.campaign,        label: 'News',     index: 3, currentIndex: _currentIndex, onTap: () => setState(() => _currentIndex = 3))),
                Expanded(child: _NavItem(icon: Icons.person_outline,        activeIcon: Icons.person,          label: 'Profile',  index: 4, currentIndex: _currentIndex, onTap: () => setState(() => _currentIndex = 4))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? _kGold.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? _kGold : _kTextMid,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? _kGold : _kTextMid,
              ),
            ),
          ],
        ),
    );
  }
}
