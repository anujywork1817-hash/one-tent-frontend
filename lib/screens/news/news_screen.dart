import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

const _kHeroBg      = Color(0xFF4A1000);
const _kBodyBg      = Color(0xFFFFFFFF);
const _kCardBg      = Color(0xFFFFFFFF);
const _kGold        = Color(0xFFD4891A);
const _kBorderLight = Color(0xFFDDD0C4);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextMid     = Color(0xFF7A4A30);
const _kTextLight   = Color(0xFFA07050);
const _kLive        = Color(0xFFD8432E);

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _newsRepo = NewsRepository();
  final _eventsRepo = EventsRepository();

  List<NewsItem> _items = [];
  bool _loading = true;
  String? _error;

  // Real "next Snan" countdown — the nearest upcoming bathing date from the
  // same event data the Kumbh Calendar screen uses. Null until it loads, or
  // if there's no upcoming snan date on record right now.
  KumbhEvent? _nextSnan;

  @override
  void initState() {
    super.initState();
    _load();
    _loadNextSnan();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = _items.isEmpty; _error = null; });
    try {
      final items = await _newsRepo.list();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _loadNextSnan() async {
    try {
      final events = await _eventsRepo.list();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final upcoming = events
          .where((e) => e.eventType == 'snan' && !e.eventDate.isBefore(todayDate))
          .toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
      if (!mounted) return;
      setState(() => _nextSnan = upcoming.isNotEmpty ? upcoming.first : null);
    } catch (_) {
      // Silent: the countdown card just doesn't show if this fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        surfaceTintColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('News & Updates',
            style: TextStyle(
                color: _kTextDark, fontWeight: FontWeight.w700, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorderLight),
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

    if (_error != null && _items.isEmpty) {
      return _refreshable(_message(
        icon: Icons.error_outline,
        title: 'Could not load news',
        subtitle: _error!,
      ));
    }

    if (_items.isEmpty) {
      return _refreshable(_message(
        icon: Icons.campaign_outlined,
        title: 'No announcements yet',
        subtitle: 'Kumbh Mela updates and news will show up here.',
      ));
    }

    final hero = _items.first;
    final rest = _items.skip(1).toList();

    return RefreshIndicator(
      color: _kGold,
      onRefresh: () => Future.wait([_load(), _loadNextSnan()]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_nextSnan != null) ...[
            _SnanCountdownCard(event: _nextSnan!),
            const SizedBox(height: 18),
          ],
          _NewsCard(item: hero, index: 0, hero: true),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('More Updates',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _kTextDark)),
            const SizedBox(height: 12),
            ...rest.asMap().entries.map(
                (e) => _NewsCard(item: e.value, index: e.key + 1)),
          ],
        ],
      ),
    );
  }

  /// Wraps a non-scrolling state so it fills the viewport and can be pulled
  /// — the empty/error states are exactly when someone is likely to refresh.
  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      color: _kGold,
      onRefresh: () => Future.wait([_load(), _loadNextSnan()]),
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

// ── Next-Snan countdown ──────────────────────────────────────────────────
// Real data: the nearest upcoming bathing date from the events backend,
// the same source the Kumbh Calendar screen reads from.
class _SnanCountdownCard extends StatelessWidget {
  const _SnanCountdownCard({required this.event});
  final KumbhEvent event;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final days = event.eventDate.difference(todayDate).inDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4891A), Color(0xFFB5540F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _kHeroBg.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.water_drop_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('NEXT SNAN',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6)),
                ]),
                const SizedBox(height: 10),
                Text(event.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, dd MMM yyyy').format(event.eventDate),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Text(days > 0 ? '$days' : 'Today',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: days > 0 ? 26 : 16,
                      fontWeight: FontWeight.w800)),
              if (days > 0)
                const Text('days',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, this.index = 0, this.hero = false});
  final NewsItem item;
  final int index;
  /// The first, larger card at the top of the feed — bigger image, no
  /// truncation on the body text.
  final bool hero;

  Future<void> _openSource(BuildContext context) async {
    if (item.sourceUrl == null) return;
    final uri = Uri.tryParse(item.sourceUrl!);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open this article')));
      }
    }
  }

  /// A story counts as "live" when it was published within the last day —
  /// real freshness, not a fabricated flag.
  bool get _isRecent =>
      DateTime.now().difference(item.createdAt).inHours < 24;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _kHeroBg.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: hero
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage)
                    Stack(children: [
                      Image.network(
                        AppConstants.fileUrl(item.imageUrl!),
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      if (_isRecent)
                        Positioned(top: 12, left: 12, child: _liveBadge()),
                    ]),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _cardBody(),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          AppConstants.fileUrl(item.imageUrl!),
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    if (hasImage) const SizedBox(width: 12),
                    Expanded(child: _cardBody(compact: true)),
                  ],
                ),
              ),
      ),
    );

    final content = item.isExternal
        ? InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openSource(context),
            child: card,
          )
        : card;

    return content
        .animate(delay: (55 * index).ms)
        .fadeIn(duration: 320.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
  }

  Widget _liveBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: _kLive,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('LIVE',
            style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4)),
      );

  Widget _cardBody({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact && _isRecent) ...[
          Row(children: [
            _liveBadge(),
          ]),
          const SizedBox(height: 6),
        ],
        Text(item.title,
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: TextStyle(
                fontSize: compact ? 13.5 : 15.5,
                fontWeight: FontWeight.bold,
                color: _kTextDark)),
        if (!compact) ...[
          const SizedBox(height: 6),
          Text(item.body,
              maxLines: item.isExternal ? 3 : null,
              overflow: item.isExternal ? TextOverflow.ellipsis : null,
              style: const TextStyle(
                  fontSize: 13.5, color: _kTextMid, height: 1.5)),
        ] else ...[
          const SizedBox(height: 4),
          Text(item.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _kTextMid, height: 1.4)),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.schedule, size: 12, color: _kTextLight),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM dd, yyyy').format(item.createdAt),
            style: const TextStyle(fontSize: 11.5, color: _kTextLight),
          ),
          if (item.sourceName != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.sourceName!,
                style: const TextStyle(
                    fontSize: 10.5,
                    color: _kGold,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (!compact && item.isExternal) ...[
            const Spacer(),
            const Icon(Icons.open_in_new, size: 13, color: _kGold),
            const SizedBox(width: 3),
            const Text('Read more',
                style: TextStyle(
                    fontSize: 11.5,
                    color: _kGold,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
      ],
    );
  }
}
