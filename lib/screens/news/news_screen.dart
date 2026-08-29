import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
const _kError       = Color(0xFFC0392B);

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _repo = NewsRepository();

  List<NewsItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = _items.isEmpty; _error = null; });
    try {
      final items = await _repo.list();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
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
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kGold.withValues(alpha: 0.45)),
            ),
            child: const Icon(Icons.campaign_outlined, color: _kGold, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('News & Updates',
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

    return RefreshIndicator(
      color: _kGold,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) => _NewsCard(item: _items[i], index: i),
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

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, this.index = 0});
  final NewsItem item;
  final int index;

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

  @override
  Widget build(BuildContext context) {
    final card = Container(
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
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Image.network(
                AppConstants.fileUrl(item.imageUrl!),
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark)),
                  const SizedBox(height: 6),
                  Text(item.body,
                      maxLines: item.isExternal ? 3 : null,
                      overflow:
                          item.isExternal ? TextOverflow.ellipsis : null,
                      style: const TextStyle(
                          fontSize: 13.5, color: _kTextMid, height: 1.5)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.schedule, size: 12, color: _kTextLight),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(item.createdAt),
                      style:
                          const TextStyle(fontSize: 11.5, color: _kTextLight),
                    ),
                    if (item.isExternal) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.sourceName ?? 'News',
                          style: const TextStyle(
                              fontSize: 10.5,
                              color: _kGold,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.open_in_new,
                          size: 13, color: _kGold),
                      const SizedBox(width: 3),
                      const Text('Read more',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: _kGold,
                              fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ],
              ),
            ),
          ],
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
}
