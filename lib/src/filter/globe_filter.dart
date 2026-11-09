import 'package:flutter/foundation.dart';

import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/models/globe_region.dart';

/// Decides whether a country is kept by [GlobeFilter.where].
typedef GlobeCountryPredicate = bool Function(GlobeCountry country);

/// One filter for every picker type and for headless lists.
///
/// **Country rules** (`countries`, `excludeCountries`, `regions`,
/// `excludeRegions`, `where`) apply to every type: an item is kept when at
/// least one of its countries passes them. Excluding a country therefore
/// also hides a dial code used only by that country.
///
/// **Currency rules** (`currencies`, `excludeCurrencies`) only filter
/// currency items, and **dial code rules** (`dialCodes`, `excludeDialCodes`)
/// only filter dial code items. So one shared filter can hide a currency
/// from the currency picker without hiding the countries that use it.
///
/// An empty "only" list means "no restriction". Codes are case-insensitive.
///
/// ```dart
/// const appFilter = GlobeFilter(excludeCountries: ['AQ', 'BV']);
/// GlobePicker.country(context, filter: appFilter);
/// GlobePicker.currency(context, filter: appFilter);
/// ```
@immutable
class GlobeFilter {
  /// Creates a filter. Every rule is optional.
  const GlobeFilter({
    this.countries = const [],
    this.excludeCountries = const [],
    this.currencies = const [],
    this.excludeCurrencies = const [],
    this.dialCodes = const [],
    this.excludeDialCodes = const [],
    this.regions = const [],
    this.excludeRegions = const [],
    this.where,
  });

  /// A filter that keeps everything.
  static const none = GlobeFilter();

  /// Only the 27 member states of the European Union.
  static final europeanUnion = GlobeFilter(
    where: (country) => country.isEUMember,
  );

  /// Only EU members that use the euro.
  static final eurozone = GlobeFilter(where: (country) => country.isEurozone);

  /// Only member states of the United Nations.
  static final unMembers = GlobeFilter(where: (country) => country.isUNMember);

  /// Only these countries (ISO alpha-2, alpha-3 or numeric codes).
  final List<String> countries;

  /// Hides these countries (ISO alpha-2, alpha-3 or numeric codes).
  final List<String> excludeCountries;

  /// Only these currencies in the currency picker (ISO 4217 codes).
  final List<String> currencies;

  /// Hides these currencies from the currency picker (ISO 4217 codes).
  final List<String> excludeCurrencies;

  /// Only these dial codes in the dial code picker, for example `+91`.
  final List<String> dialCodes;

  /// Hides these dial codes from the dial code picker.
  final List<String> excludeDialCodes;

  /// Only countries in these regions.
  final List<GlobeRegion> regions;

  /// Hides countries in these regions.
  final List<GlobeRegion> excludeRegions;

  /// Your own country rule, combined with the other rules.
  final GlobeCountryPredicate? where;

  /// Whether this filter has no rules at all.
  bool get isEmpty =>
      countries.isEmpty &&
      excludeCountries.isEmpty &&
      currencies.isEmpty &&
      excludeCurrencies.isEmpty &&
      dialCodes.isEmpty &&
      excludeDialCodes.isEmpty &&
      regions.isEmpty &&
      excludeRegions.isEmpty &&
      where == null;

  /// Whether [country] passes the country rules.
  bool matchesCountry(GlobeCountry country) {
    if (countries.isNotEmpty && !_containsCountry(countries, country)) {
      return false;
    }
    if (_containsCountry(excludeCountries, country)) return false;
    if (regions.isNotEmpty && !regions.contains(country.region)) return false;
    if (excludeRegions.contains(country.region)) return false;
    final predicate = where;
    return predicate == null || predicate(country);
  }

  /// Whether [item] passes this filter.
  bool matches(GlobeItem item) {
    switch (item) {
      case GlobeCurrency(:final code):
        if (currencies.isNotEmpty && !_containsCode(currencies, code)) {
          return false;
        }
        if (_containsCode(excludeCurrencies, code)) return false;
      case GlobeDialCode(:final code):
        if (dialCodes.isNotEmpty && !_containsCode(dialCodes, code)) {
          return false;
        }
        if (_containsCode(excludeDialCodes, code)) return false;
      case GlobeCountry():
      case GlobeDateFormat():
        break;
    }
    return item.countries.any(matchesCountry);
  }

  /// Returns the items of [items] that pass this filter, in order.
  List<T> apply<T extends GlobeItem>(Iterable<T> items) =>
      isEmpty ? items.toList() : items.where(matches).toList();

  /// Returns a copy with the given rules replaced.
  GlobeFilter copyWith({
    List<String>? countries,
    List<String>? excludeCountries,
    List<String>? currencies,
    List<String>? excludeCurrencies,
    List<String>? dialCodes,
    List<String>? excludeDialCodes,
    List<GlobeRegion>? regions,
    List<GlobeRegion>? excludeRegions,
    GlobeCountryPredicate? where,
  }) => GlobeFilter(
    countries: countries ?? this.countries,
    excludeCountries: excludeCountries ?? this.excludeCountries,
    currencies: currencies ?? this.currencies,
    excludeCurrencies: excludeCurrencies ?? this.excludeCurrencies,
    dialCodes: dialCodes ?? this.dialCodes,
    excludeDialCodes: excludeDialCodes ?? this.excludeDialCodes,
    regions: regions ?? this.regions,
    excludeRegions: excludeRegions ?? this.excludeRegions,
    where: where ?? this.where,
  );

  /// Combines two filters so an item must pass **both**.
  ///
  /// Exclude lists are joined. "Only" lists are intersected when both
  /// filters set them, otherwise the one that is set is kept. `where` rules
  /// must both return `true`.
  GlobeFilter operator +(GlobeFilter other) {
    List<T> intersectOrKeep<T>(List<T> first, List<T> second) {
      if (first.isEmpty) return second;
      if (second.isEmpty) return first;
      final secondNormalized = second.map(_normalizeAny).toSet();
      return [
        for (final value in first)
          if (secondNormalized.contains(_normalizeAny(value))) value,
      ];
    }

    // An empty "only" list means "no rule", so two "only" lists without a
    // common value must become a list that matches nothing instead.
    List<String> intersectCodes(List<String> first, List<String> second) {
      final codes = intersectOrKeep(first, second);
      return codes.isEmpty && first.isNotEmpty && second.isNotEmpty
          ? const [_matchesNothing]
          : codes;
    }

    final regionList = intersectOrKeep(regions, other.regions);
    final noRegionLeft =
        regionList.isEmpty && regions.isNotEmpty && other.regions.isNotEmpty;
    final firstWhere = where;
    final secondWhere = other.where;
    return GlobeFilter(
      countries: intersectCodes(countries, other.countries),
      excludeCountries: [...excludeCountries, ...other.excludeCountries],
      currencies: intersectCodes(currencies, other.currencies),
      excludeCurrencies: [...excludeCurrencies, ...other.excludeCurrencies],
      dialCodes: intersectCodes(dialCodes, other.dialCodes),
      excludeDialCodes: [...excludeDialCodes, ...other.excludeDialCodes],
      regions: regionList,
      excludeRegions: [...excludeRegions, ...other.excludeRegions],
      where: noRegionLeft
          ? (_) => false
          : firstWhere == null
          ? secondWhere
          : secondWhere == null
          ? firstWhere
          : (country) => firstWhere(country) && secondWhere(country),
    );
  }

  /// A code that no country, currency or dial code has.
  static const _matchesNothing = '\u0000';

  /// Normalizes a code for comparison: `in` becomes `IN`, `91` and
  /// `+ 91` become `+91`. Regions are returned unchanged.
  static Object _normalizeAny(Object? value) =>
      value is String ? _normalizeCode(value) : value!;

  /// Spaces, dashes, brackets and dots, as in `+1 (876)`.
  static final _separators = RegExp(r'[\s\-().]');
  static final _numericCountryCode = RegExp(r'^\d{1,3}$');
  static final _digitsOnly = RegExp(r'^\+?\d+$');

  static String _normalizeCode(String code) {
    final compact = code.replaceAll(_separators, '').toUpperCase();
    return _digitsOnly.hasMatch(compact)
        ? '+${compact.replaceAll('+', '')}'
        : compact;
  }

  static bool _containsCode(List<String> codes, String code) =>
      codes.any((candidate) => _normalizeCode(candidate) == code);

  /// Country codes may be alpha-2 (`IN`), alpha-3 (`IND`) or numeric
  /// (`356`).
  static bool _containsCountry(List<String> codes, GlobeCountry country) =>
      codes.any((candidate) {
        final code = candidate.replaceAll(_separators, '').toUpperCase();
        if (_numericCountryCode.hasMatch(code)) {
          return country.numCode == code.padLeft(3, '0');
        }
        return code == country.alpha2Code || code == country.alpha3Code;
      });

  @override
  bool operator ==(Object other) =>
      other is GlobeFilter &&
      listEquals(other.countries, countries) &&
      listEquals(other.excludeCountries, excludeCountries) &&
      listEquals(other.currencies, currencies) &&
      listEquals(other.excludeCurrencies, excludeCurrencies) &&
      listEquals(other.dialCodes, dialCodes) &&
      listEquals(other.excludeDialCodes, excludeDialCodes) &&
      listEquals(other.regions, regions) &&
      listEquals(other.excludeRegions, excludeRegions) &&
      other.where == where;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(countries),
    Object.hashAll(excludeCountries),
    Object.hashAll(currencies),
    Object.hashAll(excludeCurrencies),
    Object.hashAll(dialCodes),
    Object.hashAll(excludeDialCodes),
    Object.hashAll(regions),
    Object.hashAll(excludeRegions),
    where,
  );
}
