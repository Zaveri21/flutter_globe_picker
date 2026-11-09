import 'dart:ui' show Locale;

import 'package:flutter_globe_picker/src/models/globe_models.dart';

/// A piece of information a picker row can show or search.
///
/// Every field works with every picker type. Country fields read the item's
/// representative country, currency fields read the item's currency.
enum GlobeField {
  /// The flag (display only, never searched).
  flag,

  /// Country name, localized when a locale is available.
  countryName,

  /// ISO 3166-1 alpha-2 code, for example `IN`.
  alpha2Code,

  /// ISO 3166-1 alpha-3 code, for example `IND`.
  alpha3Code,

  /// ISO 3166-1 numeric code, for example `356`.
  numCode,

  /// Dial code, for example `+91`.
  dialCode,

  /// Currency name, for example `Indian Rupee`.
  currencyName,

  /// ISO 4217 currency code, for example `INR`.
  currencyCode,

  /// Currency symbol, for example `₹`.
  currencySymbol,

  /// Date pattern, for example `dd/MM/yyyy`.
  dateFormat,

  /// Today's date written with the date pattern, for example `08/11/2026`.
  dateExample,

  /// Region name, for example `Asia`.
  region,

  /// Capital city.
  capital,
}

/// Returns the text values of [field] for [item].
///
/// Names are translated into the language of [locale] when the loaded
/// translations have it, and English otherwise.
///
/// Most fields give one value. Items linked to several countries (a shared
/// currency, a shared dial code, a date format) give one value per country
/// for country fields, so searching "Germany" finds the euro.
List<String> globeFieldValues(
  GlobeItem item,
  GlobeField field, {
  Locale? locale,
  DateTime? today,
}) {
  final countries = switch (item) {
    GlobeCountry() => [item],
    GlobeCurrency(:final countries) => countries,
    GlobeDialCode(:final countries) => countries,
    GlobeDateFormat(:final countries) => countries,
  };
  // Only the currency fields need this, so it is not built for the others.
  List<GlobeCurrency> currencies() => switch (item) {
    GlobeCurrency() => [item],
    GlobeCountry(:final currencies) => currencies,
    GlobeDialCode(:final country) => country.currencies,
    GlobeDateFormat() => const <GlobeCurrency>[],
  };
  List<String> fromCountries(String? Function(GlobeCountry country) read) => [
    for (final country in countries)
      if (read(country) case final value? when value.isNotEmpty) value,
  ];

  switch (field) {
    case GlobeField.flag:
      return const [];
    case GlobeField.countryName:
      return fromCountries((country) => country.localizedName(locale));
    case GlobeField.alpha2Code:
      return fromCountries((country) => country.alpha2Code);
    case GlobeField.alpha3Code:
      return fromCountries((country) => country.alpha3Code);
    case GlobeField.numCode:
      return fromCountries((country) => country.numCode);
    case GlobeField.dialCode:
      return switch (item) {
        GlobeDialCode(:final code) => [code],
        GlobeCountry(:final dialCodes) => dialCodes,
        _ => fromCountries((country) => country.dialCode),
      };
    case GlobeField.currencyName:
      return [
        for (final currency in currencies()) currency.localizedName(locale),
      ];
    case GlobeField.currencyCode:
      return [for (final currency in currencies()) currency.code];
    case GlobeField.currencySymbol:
      return [for (final currency in currencies()) currency.symbol];
    case GlobeField.dateFormat:
      return switch (item) {
        GlobeDateFormat(:final pattern) => [pattern],
        _ => fromCountries((country) => country.dateFormat.pattern),
      };
    case GlobeField.dateExample:
      final date = today ?? DateTime.now();
      return switch (item) {
        GlobeDateFormat() => [item.format(date)],
        _ => fromCountries((country) => country.dateFormat.format(date)),
      };
    case GlobeField.region:
      return fromCountries((country) => country.region.label).toSet().toList();
    case GlobeField.capital:
      return fromCountries((country) => country.capital);
  }
}
