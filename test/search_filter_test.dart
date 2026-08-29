import 'package:flutter_test/flutter_test.dart';
import 'package:one_tent/data/models/models.dart';
import 'package:one_tent/screens/search/search_screen.dart';

CapsuleTent tent(
  String name,
  String type,
  double price, {
  bool ac = false,
  bool wifi = false,
  bool bathroom = false,
  bool available = true,
  String location = 'Zone A - Godavari Riverside',
}) =>
    CapsuleTent(
      id: name,
      name: name,
      tentTypeStr: type,
      description: '',
      capacity: 2,
      isAvailable: available,
      locationStr: location,
      price1Day: price,
      price3Days: price * 3,
      price7Days: price * 7,
      price15Days: price * 15,
      price30Days: price * 30,
      hasAC: ac,
      hasWifi: wifi,
      hasBathroom: bathroom,
    );

// Mirrors the real seeded catalogue: ₹1,500 – ₹5,000.
final catalogue = [
  tent('CAP-A01', 'single', 1500, ac: true, wifi: true),
  tent('CAP-A02', 'single', 1500, ac: true, wifi: true),
  tent('CAP-B01', 'double', 2500, ac: true, wifi: true),
  tent('CAP-B02', 'double', 2500, ac: true, wifi: true),
  tent('CAP-L01', 'luxury', 5000, ac: true, wifi: true, bathroom: true),
];

List<String> names(List<CapsuleTent> t) => t.map((x) => x.name).toList();

void main() {
  group('price filter', () {
    test('null maxPrice returns everything', () {
      expect(filterTents(tents: catalogue).length, 5);
    });

    test('filters out tents above the cap', () {
      final r = filterTents(tents: catalogue, maxPrice: 2500);
      expect(names(r), ['CAP-A01', 'CAP-A02', 'CAP-B01', 'CAP-B02']);
    });

    test('cap is inclusive at the boundary', () {
      expect(filterTents(tents: catalogue, maxPrice: 1500).length, 2);
    });

    test('tightest cap leaves only the cheapest', () {
      final r = filterTents(tents: catalogue, maxPrice: 1500);
      expect(r.every((t) => t.price1Day <= 1500), isTrue);
    });

    test('cap below everything returns empty, not all', () {
      expect(filterTents(tents: catalogue, maxPrice: 500), isEmpty);
    });
  });

  group('search by amount', () {
    test('numeric query acts as a budget', () {
      final r = filterTents(tents: catalogue, query: '2500');
      expect(names(r), ['CAP-A01', 'CAP-A02', 'CAP-B01', 'CAP-B02']);
    });

    test('rupee symbol and commas are tolerated', () {
      final r = filterTents(tents: catalogue, query: '₹2,500');
      expect(r.length, 4);
    });

    test('text query still matches name, type and location', () {
      expect(names(filterTents(tents: catalogue, query: 'CAP-L01')), ['CAP-L01']);
      expect(filterTents(tents: catalogue, query: 'luxury').length, 1);
      expect(filterTents(tents: catalogue, query: 'godavari').length, 5);
    });

    test('non-matching text returns empty', () {
      expect(filterTents(tents: catalogue, query: 'zzzz'), isEmpty);
    });
  });

  group('combined filters', () {
    test('type plus price', () {
      final r =
          filterTents(tents: catalogue, type: 'double', maxPrice: 2500);
      expect(names(r), ['CAP-B01', 'CAP-B02']);
    });

    test('amenity narrows the set', () {
      expect(filterTents(tents: catalogue, bathroomOnly: true).length, 1);
      expect(filterTents(tents: catalogue, acOnly: true).length, 5);
    });

    test('availableOnly excludes inactive tents', () {
      final withInactive = [...catalogue, tent('CAP-X', 'single', 1000, available: false)];
      expect(filterTents(tents: withInactive, availableOnly: true).length, 5);
      expect(filterTents(tents: withInactive).length, 6);
    });
  });

  group('tentPriceBounds', () {
    test('spans the real catalogue, rounded to 500s', () {
      final b = tentPriceBounds(catalogue);
      expect(b.min, 1500);
      expect(b.max, 5000);
    });

    test('whole slider range is useful — no dead travel', () {
      final b = tentPriceBounds(catalogue);
      // Every tent must sit inside the slider's travel, so moving the thumb
      // always changes the result set. This is the bug that was reported.
      for (final t in catalogue) {
        expect(t.price1Day >= b.min && t.price1Day <= b.max, isTrue,
            reason: '${t.name} at ${t.price1Day} is outside ${b.min}-${b.max}');
      }
    });

    test('identical prices still yield a usable span', () {
      final b = tentPriceBounds([tent('A', 'single', 2000), tent('B', 'single', 2000)]);
      expect(b.max > b.min, isTrue);
    });

    test('rounds outwards to tidy steps', () {
      final b = tentPriceBounds([tent('A', 'single', 1750), tent('B', 'single', 3200)]);
      expect(b.min, 1500);
      expect(b.max, 3500);
    });

    test('empty catalogue falls back to a sane range', () {
      final b = tentPriceBounds([]);
      expect(b.min, 0);
      expect(b.max, 10000);
    });
  });
}
