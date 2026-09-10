import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kHeroBg      = Color(0xFF4A1000);
const _kBodyBg      = Color(0xFFFFFFFF);
const _kCardBg      = Color(0xFFFFFFFF);
const _kBorderLight = Color(0xFFDDD0C4);
const _kGold        = Color(0xFFD4891A);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextMid     = Color(0xFF7A4A30);
const _kCream       = Color(0xFFF5E6C8);

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

const _sections = [
  _Section(
    '1. Mythological Origin',
    'According to Hindu mythology, Kumbh Mela is connected with Samudra '
        'Manthan (Churning of the Ocean).\n\n'
        'The Devas (gods) and Asuras (demons) churned the cosmic ocean to '
        'obtain Amrit, the nectar of immortality. When the Amrit appeared in '
        'a Kumbh (pot), a struggle began over it.\n\n'
        'According to the tradition, drops of Amrit fell at four places on '
        'Earth:\n'
        '• Prayagraj — Ganga, Yamuna and the mythical Saraswati\n'
        '• Haridwar — Ganga\n'
        '• Nashik — Godavari\n'
        '• Ujjain — Shipra\n\n'
        'These four places became the main Kumbh Mela locations.',
  ),
  _Section(
    '2. Historical Development',
    'The tradition of gathering at sacred rivers is much older than the '
        'modern Kumbh Mela. People traditionally gathered at holy places for '
        'bathing, worship, meditation and religious ceremonies.\n\n'
        'In the 7th century CE, the Chinese traveler Xuanzang described a '
        'large religious gathering at Prayagraj during the reign of Emperor '
        'Harsha. Historians consider this an important precursor to later '
        'large religious gatherings, although it is not certain that it was '
        'the Kumbh Mela exactly as we know it today.\n\n'
        'Over the centuries, gatherings of pilgrims, saints, sadhus and '
        'religious groups became increasingly organized.',
  ),
  _Section(
    '3. Akharas and Sadhus',
    'The Akharas, or organized groups of ascetics, became an important part '
        'of Kumbh Mela.\n\n'
        'The Naga Sadhus are particularly famous for participating in the '
        'major bathing ceremonies. Kumbh became an important place for '
        'religious communities to meet, perform rituals, teach, and practice '
        'spirituality.',
  ),
  _Section(
    '4. Kumbh During the British Period',
    'During British rule, the huge gatherings required increasing attention '
        'to:\n'
        '• Crowd management\n'
        '• Sanitation\n'
        '• Drinking water\n'
        '• Transportation\n'
        '• Police arrangements\n'
        '• Public health\n\n'
        'This helped develop the administrative systems used for managing '
        'very large pilgrimages.',
  ),
  _Section(
    '5. Kumbh After Independence',
    'After 1947, Kumbh Mela continued to grow significantly.\n\n'
        'Modern governments began providing large-scale temporary '
        'infrastructure, including:\n'
        '• Roads and bridges\n'
        '• Hospitals and medical facilities\n'
        '• Electricity\n'
        '• Water supply\n'
        '• Sanitation\n'
        '• Police and emergency services\n'
        '• Temporary accommodation\n'
        '• Transportation\n\n'
        'The festival gradually became not only a religious gathering but '
        'also a remarkable example of large-scale temporary city planning '
        'and crowd management.',
  ),
  _Section(
    '6. Kumbh Mela Today',
    'Today, millions of people travel to Kumbh Mela to take a holy bath in '
        'the sacred river, pray, meet saints and participate in religious '
        'ceremonies.\n\n'
        'One of the most important events is the Amrit Snan, the ceremonial '
        'holy bathing of saints and pilgrims on important festival dates.',
  ),
];

/// Optional illustration shown above a section, keyed by its exact title.
/// Sections not listed here render with no image.
const _sectionImages = {
  '2. Historical Development': 'assets/images/historical_development.jpg',
  '3. Akharas and Sadhus': 'assets/images/akharas_sadhus.jpg',
  '4. Kumbh During the British Period': 'assets/images/british_period.jpg',
  '5. Kumbh After Independence': 'assets/images/after_independence.jpg',
  '6. Kumbh Mela Today': 'assets/images/kumbh_today.jpg',
};

const _kumbhTypes = [
  ('Purna Kumbh', 'Approximately every 12 years at a particular location'),
  ('Ardh Kumbh', 'Approximately every 6 years, mainly at Prayagraj and Haridwar'),
  ('Maha Kumbh', 'Traditionally associated with Prayagraj after approximately 144 years'),
];

const _timeline = [
  'Ancient India',
  'Sacred river pilgrimage traditions develop',
  'Samudra Manthan tradition',
  'Four places become associated with the sacred drops of Amrit',
  '7th century CE — Xuanzang records a major religious gathering at Prayagraj',
  'Medieval period — Growth of sadhus, akharas and organized pilgrimages',
  'British period — Large-scale administration and crowd management develop',
  'After 1947 — Modern infrastructure and government organization',
  'Today — Kumbh becomes one of the world\'s largest religious gatherings',
];

class KumbhHistoryScreen extends StatelessWidget {
  const KumbhHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('History of Kumbh Mela',
            style: TextStyle(
                color: _kTextDark, fontWeight: FontWeight.w700, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Icon(Icons.temple_hindu, color: _kGold, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kumbh Mela is one of the world\'s largest religious '
                    'gatherings. Its history is a combination of ancient '
                    'Hindu mythology, sacred river traditions, astrology, '
                    'and centuries of pilgrimage.',
                    style: TextStyle(
                        color: _kTextMid, fontSize: 13.5, height: 1.5),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Samudra Manthan — the churning of the ocean, the mythological
            // origin the section right below this tells the story of.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/samudra_manthan.jpg',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            for (final s in _sections) ...[
              if (_sectionImages[s.title] != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _sectionImages[s.title]!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _sectionCard(s.title, s.body),
              const SizedBox(height: 14),
            ],

            // ── Why every 12 years ──────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/why_12_years.jpg',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 14),
            _cardShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('7. Why Does Kumbh Come Every 12 Years?',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark)),  
                  const SizedBox(height: 10),
                  const Text(
                    'The timing of Kumbh is based on traditional Hindu '
                    'astrology, particularly the positions of Jupiter and '
                    'the Sun, along with other celestial calculations. At '
                    'each major Kumbh location, the appropriate '
                    'astrological alignment occurs approximately once every '
                    '12 years.',
                    style: TextStyle(
                        color: _kTextMid, fontSize: 13.5, height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  ..._kumbhTypes.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kHeroBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t.$1,
                                  style: const TextStyle(
                                      color: _kGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(t.$2,
                                  style: const TextStyle(
                                      color: _kTextMid,
                                      fontSize: 13,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 4),
                  const Text(
                    'The Kumbh locations rotate: Prayagraj → Haridwar → '
                    'Nashik → Ujjain. The exact dates are determined by '
                    'traditional astrological calculations rather than '
                    'simply following a fixed calendar date.',
                    style: TextStyle(
                        color: _kTextMid,
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Timeline ─────────────────────────────────────────
            _cardShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Simple Timeline',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark)),
                  const SizedBox(height: 14),
                  for (int i = 0; i < _timeline.length; i++)
                    _timelineRow(_timeline[i], isLast: i == _timeline.length - 1),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── In short ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kHeroBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.auto_stories, color: _kGold, size: 18),
                    const SizedBox(width: 8),
                    const Text('In Short',
                        style: TextStyle(
                            color: _kCream,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    'Kumbh Mela developed over many centuries from India\'s '
                    'ancient tradition of pilgrimage to sacred rivers. Its '
                    'spiritual foundation comes from the story of Samudra '
                    'Manthan, while its historical form gradually developed '
                    'through religious gatherings at Prayagraj, Haridwar, '
                    'Nashik and Ujjain. A Kumbh generally occurs '
                    'approximately every 12 years at the same location, '
                    'with Ardh Kumbh occurring approximately every 6 years '
                    'at Prayagraj and Haridwar.',
                    style: TextStyle(
                        color: _kCream.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, String body) =>
      _cardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark)),
            const SizedBox(height: 10),
            Text(body,
                style: const TextStyle(
                    color: _kTextMid, fontSize: 13.5, height: 1.6)),
          ],
        ),
      );

  Widget _cardShell({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _kHeroBg.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5)),
          ],
        ),
        child: child,
      );

  Widget _timelineRow(String text, {required bool isLast}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                      color: _kGold, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: _kGold.withValues(alpha: 0.25),
                    ),
                  ),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(text,
                      style: const TextStyle(
                          color: _kTextMid, fontSize: 13, height: 1.4)),
                ),
              ),
            ],
          ),
        ),
      );
}
