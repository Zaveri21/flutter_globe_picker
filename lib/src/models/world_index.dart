part of 'globe_models.dart';

WorldIndex? _loadedWorldIndex;

/// The loaded data, indexed and linked.
///
/// Internal: use `GlobeData` instead.
WorldIndex get worldIndex =>
    _loadedWorldIndex ??
    (throw StateError(
      'flutter_globe_picker data is not loaded. Call '
      '`await GlobeData.load()` before runApp, or GlobeData.loadFromJson().',
    ));

/// Whether data has been loaded.
///
/// Internal: use `GlobeData.isLoaded` instead.
bool get isWorldIndexLoaded => _loadedWorldIndex != null;

/// Replaces the loaded data.
///
/// Internal: use `GlobeData.load` instead.
set worldIndexData(WorldIndex index) => _loadedWorldIndex = index;

/// Lookup tables and links between the bundled models.
///
/// Internal: use `GlobeData` instead.
class WorldIndex {
  WorldIndex._({
    required this.countries,
    required this.currencies,
    required this.dialCodes,
    required this.dateFormats,
    required this.countriesByCurrency,
    required this.languageCountries,
    required this.countryNames,
    required this.currencyNames,
  }) : countriesByAlpha2 = {
         for (final country in countries) country.alpha2Code: country,
       },
       countriesByAlpha3 = {
         for (final country in countries) country.alpha3Code: country,
       },
       countriesByNumCode = {
         for (final country in countries) ?country.numCode: country,
       },
       currenciesByCode = {
         for (final currency in currencies) currency.code: currency,
       },
       dialCodesByCode = {
         for (final dialCode in dialCodes) dialCode.code: dialCode,
       },
       dateFormatsByPattern = {
         for (final dateFormat in dateFormats) dateFormat.pattern: dateFormat,
       };

  /// Indexes [countryList] and [currencyList] and links them together.
  ///
  /// [languageCountries] maps a language code to its main country.
  /// [countryNames] and [currencyNames] hold translated names by language,
  /// then by alpha-2 or currency code.
  factory WorldIndex.build(
    List<GlobeCountry> countryList,
    List<GlobeCurrency> currencyList, {
    Map<String, String> languageCountries = const {},
    Map<String, Map<String, String>> countryNames = const {},
    Map<String, Map<String, String>> currencyNames = const {},
  }) {
    final sortKeys = {
      for (final country in countryList)
        country: normalizeSearchText(country.name),
    };
    final countries = countryList.toList()
      ..sort((first, second) => sortKeys[first]!.compareTo(sortKeys[second]!));

    final countriesByCurrency = <String, List<GlobeCountry>>{};
    final countriesByDialCode = <String, List<GlobeCountry>>{};
    final countriesByPattern = <String, List<GlobeCountry>>{};
    for (final country in countries) {
      for (final code in country.currencyCodes) {
        countriesByCurrency.putIfAbsent(code, () => []).add(country);
      }
      for (final code in country.dialCodes) {
        countriesByDialCode.putIfAbsent(code, () => []).add(country);
      }
      countriesByPattern
          .putIfAbsent(country.dateFormatPattern, () => [])
          .add(country);
    }

    final dialCodes = [
      for (final entry in countriesByDialCode.entries)
        GlobeDialCode(
          code: entry.key,
          countries: List.unmodifiable(entry.value),
        ),
    ]..sort(_compareDialCodes);

    final dateFormats =
        [
          for (final entry in countriesByPattern.entries)
            GlobeDateFormat(
              pattern: entry.key,
              countries: List.unmodifiable(entry.value),
            ),
        ]..sort((first, second) {
          final byUsage = second.countries.length.compareTo(
            first.countries.length,
          );
          return byUsage != 0
              ? byUsage
              : first.pattern.compareTo(second.pattern);
        });

    return WorldIndex._(
      countries: List.unmodifiable(countries),
      currencies: List.unmodifiable(
        currencyList.toList()
          ..sort((first, second) => first.code.compareTo(second.code)),
      ),
      dialCodes: List.unmodifiable(dialCodes),
      dateFormats: List.unmodifiable(dateFormats),
      countriesByCurrency: {
        for (final entry in countriesByCurrency.entries)
          entry.key: List<GlobeCountry>.unmodifiable(entry.value),
      },
      languageCountries: languageCountries,
      countryNames: countryNames,
      currencyNames: currencyNames,
    );
  }

  /// Countries sorted by English name.
  final List<GlobeCountry> countries;

  /// Currencies sorted by code.
  final List<GlobeCurrency> currencies;

  /// Dial codes sorted by calling code, then area code.
  final List<GlobeDialCode> dialCodes;

  /// Date formats, most used first.
  final List<GlobeDateFormat> dateFormats;

  /// Countries by alpha-2 code.
  final Map<String, GlobeCountry> countriesByAlpha2;

  /// Countries by alpha-3 code.
  final Map<String, GlobeCountry> countriesByAlpha3;

  /// Countries by three digit numeric code.
  final Map<String, GlobeCountry> countriesByNumCode;

  /// Currencies by ISO 4217 code.
  final Map<String, GlobeCurrency> currenciesByCode;

  /// Dial codes by code with `+`.
  final Map<String, GlobeDialCode> dialCodesByCode;

  /// Date formats by pattern.
  final Map<String, GlobeDateFormat> dateFormatsByPattern;

  /// Countries using each currency code.
  final Map<String, List<GlobeCountry>> countriesByCurrency;

  /// The main country of each language code, for example `ja` → `JP`.
  final Map<String, String> languageCountries;

  /// Translated country names by language, then alpha-2 code.
  final Map<String, Map<String, String>> countryNames;

  /// Translated currency names by language, then currency code.
  final Map<String, Map<String, String>> currencyNames;

  final Map<String, RegExp> _fullMatchPatterns = {};
  final Map<String, RegExp> _prefixPatterns = {};

  /// A cached regular expression matching the whole input against [source].
  RegExp fullMatchPattern(String source) =>
      _fullMatchPatterns[source] ??= RegExp('^(?:$source)\$');

  /// A cached regular expression matching the start of the input.
  RegExp prefixPattern(String source) =>
      _prefixPatterns[source] ??= RegExp('^(?:$source)');

  /// Finds the country of an international number given as digits after
  /// the `+`, for example `919876543210`. Returns the country together with
  /// the national number, or `null` when no calling code matches.
  (GlobeCountry, String)? resolveInternationalDigits(String digits) {
    for (var length = 3; length >= 1; length--) {
      if (digits.length <= length) continue;
      final callingCode = '+${digits.substring(0, length)}';
      final candidates = _countriesByCallingCode[callingCode];
      if (candidates == null) continue;
      final nationalNumber = digits.substring(length);
      final owner =
          ownerOfNationalNumber(callingCode, nationalNumber) ??
          candidates.first;
      return (owner, nationalNumber);
    }
    return null;
  }

  /// The country of [callingCode] that a national number belongs to, in
  /// libphonenumber order: the main country first, then the others. `null`
  /// when no country claims it (for example a number still being typed).
  GlobeCountry? ownerOfNationalNumber(String callingCode, String digits) {
    for (final country
        in _countriesByCallingCode[callingCode] ?? const <GlobeCountry>[]) {
      if (country._ownsNationalNumber(digits)) return country;
    }
    return null;
  }

  /// The main country of [callingCode] that has a numbering plan, for
  /// example Norway for `+47`.
  GlobeCountry? mainCountryForCallingCode(String callingCode) =>
      _countriesByCallingCode[callingCode]?.firstOrNull;

  /// Countries by calling code, in libphonenumber order: the main country
  /// first, then the others; countries without phone metadata come last.
  late final Map<String, List<GlobeCountry>> _countriesByCallingCode = () {
    final result = <String, List<GlobeCountry>>{};
    int rank(GlobeCountry country) => country.isMainCountryForDialCode
        ? 0
        : country.phonePattern != null
        ? 1
        : 2;
    for (final country in countries) {
      (result[country.callingCode] ??= []).add(country);
    }
    for (final group in result.values) {
      // A stable sort keeps the name order within each rank.
      final ordered = [
        for (var currentRank = 0; currentRank < 3; currentRank++)
          ...group.where((country) => rank(country) == currentRank),
      ];
      group
        ..clear()
        ..addAll(ordered);
    }
    return result;
  }();

  static int _compareDialCodes(GlobeDialCode first, GlobeDialCode second) {
    int callingCodeOf(GlobeDialCode dialCode) =>
        dialCode.code.startsWith('+1') ? 1 : int.parse(dialCode.digits);
    final byCallingCode = callingCodeOf(first).compareTo(callingCodeOf(second));
    if (byCallingCode != 0) return byCallingCode;
    final byLength = first.code.length.compareTo(second.code.length);
    return byLength != 0 ? byLength : first.code.compareTo(second.code);
  }
}
