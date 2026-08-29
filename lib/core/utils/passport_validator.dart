import 'countries_data.dart';

/// Passport number formats, keyed by canonical country (from
/// [CountriesData]). Real passport formats vary a lot by issuing country
/// (length, whether letters are allowed, whether the first character must
/// be a letter, etc). Countries without a specific pattern fall back to
/// [_genericPattern] — 6 to 9 upper-case alphanumeric characters that must
/// contain at least one letter and one digit, which covers most
/// ICAO-compliant passports without letting plain digits or plain letters
/// slip through unchecked.
class PassportValidator {
  PassportValidator._();

  static final RegExp _genericPattern =
      RegExp(r'^(?=.*[A-Z])(?=.*[0-9])[A-Z0-9]{6,9}$');

  static final Map<String, RegExp> _countryPatterns = {
    'india': RegExp(r'^[A-Z][0-9]{7}$'),
    'united states': RegExp(r'^[A-Z0-9]{9}$'),
    'united kingdom': RegExp(r'^[0-9]{9}$'),
    'canada': RegExp(r'^[A-Z]{2}[0-9]{6}$'),
    'australia': RegExp(r'^[A-Z][0-9]{7}$'),
    'germany': RegExp(r'^[C-FJ-NP-RT-VXYZ0-9]{9}$'),
    'france': RegExp(r'^[0-9]{2}[A-Z]{2}[0-9]{5}$'),
    'italy': RegExp(r'^[A-Z]{2}[0-9]{7}$'),
    'spain': RegExp(r'^[A-Z]{3}[0-9]{6}$'),
    'china': RegExp(r'^[EG][0-9]{8}$'),
    'japan': RegExp(r'^[A-Z]{2}[0-9]{7}$'),
    'south korea': RegExp(r'^[MS][0-9]{8}$'),
    'russia': RegExp(r'^[0-9]{9}$'),
    'brazil': RegExp(r'^[A-Z]{2}[0-9]{6}$'),
    'nepal': RegExp(r'^[0-9]{8}$'),
    'bangladesh': RegExp(r'^[A-Z]{2}[0-9]{7}$'),
    'pakistan': RegExp(r'^[A-Z]{2}[0-9]{7}$'),
    'sri lanka': RegExp(r'^[A-Z][0-9]{7}$'),
    'singapore': RegExp(r'^[KES][0-9]{7}[A-Z]$'),
    'malaysia': RegExp(r'^[A-Z][0-9]{8}$'),
    'indonesia': RegExp(r'^[A-Z][0-9]{7}$'),
    'thailand': RegExp(r'^[A-Z][0-9]{7}$'),
    'philippines': RegExp(r'^[A-Z]{2}[0-9]{7}$'),
    'south africa': RegExp(r'^[A-Z][0-9]{8}$'),
    'united arab emirates': RegExp(r'^[0-9]{9}$'),
    'saudi arabia': RegExp(r'^[A-Z][0-9]{7}$'),
    'new zealand': RegExp(r'^[A-Z]{2}[0-9]{6}$'),
    'netherlands': RegExp(r'^[A-Z]{2}[A-Z0-9]{6}[0-9]$'),
    'mexico': RegExp(r'^[0-9]{7,10}$'),
  };

  /// Returns a human-readable error, or null if [passportNumber] is a
  /// plausible passport number for [country] (a country name or demonym —
  /// resolved via [CountriesData]).
  static String? validate(String country, String passportNumber) {
    final number = passportNumber.trim().toUpperCase();
    if (number.isEmpty) return 'Passport number is required';

    final canonical = CountriesData.resolveCountry(country);
    final pattern = canonical != null
        ? (_countryPatterns[canonical] ?? _genericPattern)
        : _genericPattern;

    if (!pattern.hasMatch(number)) {
      return 'Please enter a valid or correct passport number';
    }
    return null;
  }
}
