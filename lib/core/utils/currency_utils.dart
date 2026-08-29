import 'countries_data.dart';

/// Drives "what currency should this guest see prices in" off their
/// registered country, instead of making everyone manually pick one.
/// GST is never touched by any of this — it's always computed and shown in
/// INR (₹) regardless of display currency, since it's an Indian
/// accommodation tax tied to where the property is, not where the guest
/// is from.
class CurrencyUtils {
  CurrencyUtils._();

  // Only these four have exchange rates on the backend
  // (see migrations/017_multi_currency.sql's CHECK constraint) — every
  // other country, India included, previews in INR.
  static const Set<String> _eurozone = {
    'austria', 'belgium', 'cyprus', 'estonia', 'finland', 'france',
    'germany', 'greece', 'ireland', 'italy', 'latvia', 'lithuania',
    'luxembourg', 'malta', 'netherlands', 'portugal', 'slovakia',
    'slovenia', 'spain', 'andorra', 'monaco', 'san marino', 'vatican city',
  };

  static const Map<String, String> symbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'AED ',
  };

  /// Resolves a visitor's `country` field to the currency their prices
  /// should preview in.
  static String currencyForCountry(String? country) {
    if (country == null || country.trim().isEmpty) return 'INR';
    final key =
        CountriesData.resolveCountry(country) ?? country.trim().toLowerCase();
    if (key == 'united states') return 'USD';
    if (key == 'united kingdom') return 'GBP';
    if (key == 'united arab emirates') return 'AED';
    if (_eurozone.contains(key)) return 'EUR';
    return 'INR';
  }

  /// Converts [amountInr] into [currency] using [rates] (currency code ->
  /// rate to INR, from GET /exchange-rates) and formats it with the right
  /// symbol. Falls back to a plain ₹ amount whenever the target currency is
  /// INR itself, or the rate isn't loaded yet — never shows a broken price.
  static String formatPrice(
    double amountInr, {
    required String currency,
    Map<String, double>? rates,
  }) {
    if (currency == 'INR') return '₹${amountInr.toStringAsFixed(0)}';
    final rate = rates?[currency];
    if (rate == null || rate <= 0) return '₹${amountInr.toStringAsFixed(0)}';
    final converted = amountInr / rate;
    final symbol = symbols[currency] ?? '$currency ';
    return '$symbol${converted.toStringAsFixed(2)}';
  }
}
