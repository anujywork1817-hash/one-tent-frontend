import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
const _kBlue        = Color(0xFF2E6E8C);

class KumbhCalendarScreen extends StatefulWidget {
  const KumbhCalendarScreen({super.key});

  @override
  State<KumbhCalendarScreen> createState() => _KumbhCalendarScreenState();
}

class _KumbhCalendarScreenState extends State<KumbhCalendarScreen> {
  final _repo = EventsRepository();

  List<KumbhEvent> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = _events.isEmpty; _error = null; });
    try {
      final events = await _repo.list();
      if (!mounted) return;
      setState(() { _events = events; _loading = false; });
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
            child: const Icon(Icons.event_note_outlined,
                color: _kGold, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Kumbh Calendar',
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

    if (_error != null && _events.isEmpty) {
      return _refreshable(_message(
        icon: Icons.error_outline,
        title: 'Could not load the calendar',
        subtitle: _error!,
      ));
    }

    if (_events.isEmpty) {
      return _refreshable(_message(
        icon: Icons.event_note_outlined,
        title: 'Event dates coming soon',
        subtitle: 'Bathing dates and festival days for the Mela will be '
            'published here as they\'re confirmed.',
      ));
    }

    final today = DateTime.now();
    final upcoming = _events.where((e) => !e.eventDate.isBefore(
        DateTime(today.year, today.month, today.day))).toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    final past = _events.where((e) => e.eventDate.isBefore(
        DateTime(today.year, today.month, today.day))).toList()
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return RefreshIndicator(
      color: _kGold,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (upcoming.isNotEmpty) ...[
            _sectionLabel('Upcoming'),
            const SizedBox(height: 10),
            ...upcoming.asMap().entries.map((entry) => _EventCard(
                event: entry.value, isPast: false, index: entry.key)),
            const SizedBox(height: 8),
          ],
          if (past.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('Past'),
            const SizedBox(height: 10),
            ...past.asMap().entries.map((entry) => _EventCard(
                event: entry.value, isPast: true, index: entry.key)),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: _kTextDark,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.4));

  /// Wraps a non-scrolling state so it fills the viewport and can be pulled.
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

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.isPast, this.index = 0});
  final KumbhEvent event;
  final bool isPast;
  final int index;

  (IconData, Color, String) get _typeVisual {
    switch (event.eventType) {
      case 'snan':
        return (Icons.water_drop_rounded, _kBlue, 'Bathing Date');
      case 'festival':
        return (Icons.celebration_rounded, _kGold, 'Festival');
      default:
        return (Icons.info_outline, _kTextMid, 'General');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _typeVisual;
    return Opacity(
      opacity: isPast ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorderLight),
          boxShadow: [
            BoxShadow(
                color: _kHeroBg.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Text(DateFormat('MMM').format(event.eventDate).toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${event.eventDate.day}',
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 5),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark)),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(event.description,
                        style: const TextStyle(
                            fontSize: 12.5, color: _kTextMid, height: 1.4)),
                  ],
                  const SizedBox(height: 4),
                  Text(DateFormat('EEEE, MMM dd, yyyy').format(event.eventDate),
                      style: const TextStyle(
                          fontSize: 11.5, color: _kTextLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (55 * index).ms)
        .fadeIn(duration: 320.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
  }
}
