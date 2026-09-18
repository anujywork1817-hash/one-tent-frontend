import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kMaroon    = Color(0xFF4A1000);
const Color _kGold      = Color(0xFFD4891A);
const Color _kBodyBg    = Color(0xFFFFFFFF);
const Color _kCardBg    = Color(0xFFFFFFFF);
const Color _kCardUnread= Color(0xFFFFF8F0); // warm tint for unread
const Color _kTextDark  = Color(0xFF2C1A0E);
const Color _kTextMuted = Color(0xFF8A6A50);
const Color _kDivider   = Color(0xFFEDE0D4);
const Color _kGreen     = Color(0xFF2E7D32);
const Color _kRed       = Color(0xFFC0392B);
const Color _kBlue      = Color(0xFF1565C0);
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<AppNotification> _notifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final list = await auth.getNotifications();
      setState(() { _notifications = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markAllRead() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.markAllNotificationsRead();
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });
    } catch (_) {}
  }

  /// Tapping a notification is what should clear its own unread dot — the
  /// list updates immediately (optimistic) so it doesn't wait on the
  /// network; if the request fails, the read state is rolled back.
  Future<void> _markOneRead(AppNotification n) async {
    if (n.isRead) return;
    final i = _notifications.indexWhere((x) => x.id == n.id);
    if (i == -1) return;

    setState(() => _notifications[i] = _notifications[i].copyWith(isRead: true));
    try {
      await context.read<AuthProvider>().markNotificationRead(n.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _notifications[i] = _notifications[i].copyWith(isRead: false));
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'booking_confirmed': return Icons.check_circle_outline_rounded;
      case 'payment_success':   return Icons.payments_outlined;
      case 'booking_cancelled': return Icons.cancel_outlined;
      case 'passport_approved': return Icons.verified_user_outlined;
      case 'passport_rejected': return Icons.gpp_bad_outlined;
      default:                  return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'booking_confirmed': return _kGreen;
      case 'payment_success':   return _kBlue;
      case 'booking_cancelled': return _kRed;
      case 'passport_approved': return _kGreen;
      case 'passport_rejected': return _kRed;
      default:                  return _kGold;
    }
  }

  /// Makes a non-scrolling state (empty / error) fill the viewport and accept
  /// a pull, so RefreshIndicator has something to attach to.
  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)    return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: _kBodyBg,
      body: Column(
        children: [
          // ── Dark maroon hero header ──────────────────────────────────
          _NotifHeader(
            unreadCount: unreadCount,
            onMarkAll: unreadCount > 0 ? _markAllRead : null,
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _kGold, strokeWidth: 2.5))
                // The empty state is inside the indicator now: with no
                // notifications there is nothing to scroll, which is exactly
                // when someone pulls down to check for new ones.
                : RefreshIndicator(
                    onRefresh: _load,
                    color: _kGold,
                    backgroundColor: _kCardBg,
                    child: _error != null
                        ? _scrollable(
                            _ErrorState(error: _error!, onRetry: _load))
                        : _notifications.isEmpty
                            ? _scrollable(const _EmptyState())
                            : ListView.separated(
                                // Without this the pull is ignored whenever
                                // the list is too short to scroll.
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    16, 20, 16, 24),
                                itemCount: _notifications.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) => _NotifCard(
                                  notification: _notifications[i],
                                  icon: _iconFor(_notifications[i].type),
                                  color: _colorFor(_notifications[i].type),
                                  timeAgo:
                                      _timeAgo(_notifications[i].createdAt),
                                  onTap: () => _markOneRead(_notifications[i]),
                                ),
                              ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header — same plain white chrome as every other screen ─────────────────
class _NotifHeader extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onMarkAll;
  const _NotifHeader(
      {required this.unreadCount, required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: _kTextDark, size: 28),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: _kTextDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount unread',
                        style: const TextStyle(
                          color: _kGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (onMarkAll != null)
                GestureDetector(
                  onTap: onMarkAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: _kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Notification Card ──────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color color;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotifCard({
    required this.notification,
    required this.icon,
    required this.color,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Material(
      color: n.isRead ? _kCardBg : _kCardUnread,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kMaroon.withValues(alpha: n.isRead ? 0.04 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with unread dot
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (!n.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _kGold,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _kCardUnread, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: _kTextDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: _kTextMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: const TextStyle(
                        fontSize: 13, color: _kTextMuted),
                  ),
                  // Unread label
                  if (!n.isRead) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: _kGold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 40, color: _kGold),
          ),
          const SizedBox(height: 18),
          const Text('No notifications yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark)),
          const SizedBox(height: 6),
          const Text(
            "You'll see booking and payment updates here",
            style: TextStyle(fontSize: 13, color: _kTextMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, size: 36, color: _kRed),
            ),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _kTextDark, fontSize: 13)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: _kGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}