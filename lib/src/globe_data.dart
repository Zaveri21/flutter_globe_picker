import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'package:flutter_globe_picker/src/format/globe_date_formatter.dart';
import 'package:flutter_globe_picker/src/globe_data_source.dart';
import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/models/globe_phone_number.dart';
import 'package:flutter_globe_picker/src/models/globe_region.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';
import 'package:flutter_globe_picker/src/search/globe_search.dart';

/// Offline access to every country, currency, dial code and date format.
///
/// The data ships as one JSON file in the package. Load it once before
/// `runApp`; after that every method is synchronous:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await GlobeData.load();
///   runApp(const MyApp());
/// }
/// ```
///
/// To change the data before use, pass `countryOverrides` and
/// `currencyOverrides` to [load], or load your own JSON with [loadFromJson].
///
/// ```dart
/// final india = GlobeData.countryByAlpha2('IN');
/// final euro = GlobeData.currencyByCode('EUR');
/// final phone = GlobeData.parsePhone('+447400123456');
/// ```
abstract final class GlobeData {
  static WorldIndex get _index => worldIndex;

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Asset key of the bundled data file: countries and currencies.
  static const assetKey =
      'packages/flutter_globe_picker/assets/globe_data.json';

  /// Asset key of the bundled translations file: country and currency names
  /// in other languages, linked to the data by code.
  static const translationsAssetKey =
      'packages/flutter_globe_picker/assets/globe_translations.json';

  /// Whether data has been loaded.
  static bool get isLoaded => isWorldIndexLoaded;

  /// Increases each time data is loaded, so caches can tell old data from
  /// new. `0` before the first load.
  static int get generation => _generation;
  static int _generation = 0;

  /// Languages of the loaded translations, for example `hi` and `zh-Hant`.
  /// English is always available as the `name` of each item.
  static List<String> get languages =>
      List.unmodifiable(_index.countryNames.keys);

  /// Loads the bundled data and translations. Call it once before `runApp`
  /// when your code reads `GlobeData` directly (pickers load it by
  /// themselves); calling it again replaces the data.
  ///
  /// [countryOverrides] and [currencyOverrides] change the data before use.
  /// Keys are alpha-2 or currency codes, values hold the fields to replace,
  /// with the keys of `assets/globe_data.json` (the same as
  /// [GlobeCountry.toJson] and [GlobeCurrency.toJson]). A code that does not
  /// exist yet adds a new entry, which then needs every required field.
  /// [translationOverrides] adds or replaces translated names.
  ///
  /// ```dart
  /// await GlobeData.load(
  ///   countryOverrides: {
  ///     'IN': {'name': 'Bharat'},
  ///   },
  ///   currencyOverrides: {
  ///     'INR': {'symbol': 'Rs'},
  ///   },
  ///   translationOverrides: {
  ///     'hi': {'countries': {'IN': 'भारत गणराज्य'}},
  ///   },
  /// );
  /// ```
  ///
  /// [languages] keeps only these languages in memory (`[]` for English
  /// only). [assetKey] and [translationsAssetKey] load your own copies of
  /// the files from your app's assets. [bundle] defaults to `rootBundle`.
  static Future<void> load({
    Map<String, Map<String, Object?>> countryOverrides = const {},
    Map<String, Map<String, Object?>> currencyOverrides = const {},
    GlobeTranslationOverrides translationOverrides = const {},
    List<String>? languages,
    String assetKey = GlobeData.assetKey,
    String translationsAssetKey = GlobeData.translationsAssetKey,
    AssetBundle? bundle,
  }) => loadSource(
    GlobeDataSource(
      assetKey: assetKey,
      translationsAssetKey: translationsAssetKey,
      languages: languages,
      countryOverrides: countryOverrides,
      currencyOverrides: currencyOverrides,
      translationOverrides: translationOverrides,
    ),
    bundle: bundle,
  );

  /// Loads [source]: reads its files from [bundle] (default `rootBundle`)
  /// unless it holds JSON text, then applies its overrides.
  ///
  /// When another load starts before this one finishes, the newer one wins
  /// and this one leaves the data alone.
  static Future<void> loadSource(
    GlobeDataSource source, {
    AssetBundle? bundle,
  }) async {
    final request = ++_latestRequest;
    final assets = bundle ?? rootBundle;
    // `cache: false`: the bundle would otherwise keep the raw text, and a
    // failed read, for the whole session.
    final dataJson =
        source.json ?? await assets.loadString(source.assetKey, cache: false);
    final translationsJson = !source.usesTranslations
        ? null
        : source.translationsJson ??
              await assets.loadString(
                source.translationsAssetKey,
                cache: false,
              );
    if (request != _latestRequest) return;
    _apply(source, dataJson, translationsJson);
  }

  /// Number of the latest load request; older ones do not apply their data.
  static int _latestRequest = 0;

  /// Loads data from [json], shaped like `assets/globe_data.json`, and
  /// translations from [translationsJson], shaped like
  /// `assets/globe_translations.json` (names stay English without it).
  /// Synchronous, so it also works in tests and isolates. The other
  /// arguments work as in [load].
  static void loadFromJson(
    String json, {
    String? translationsJson,
    List<String>? languages,
    Map<String, Map<String, Object?>> countryOverrides = const {},
    Map<String, Map<String, Object?>> currencyOverrides = const {},
    GlobeTranslationOverrides translationOverrides = const {},
  }) {
    final source = GlobeDataSource(
      json: json,
      translationsJson: translationsJson,
      languages: translationsJson == null && translationOverrides.isEmpty
          ? const []
          : languages,
      countryOverrides: countryOverrides,
      currencyOverrides: currencyOverrides,
      translationOverrides: translationOverrides,
    );
    _latestRequest++;
    _apply(source, json, translationsJson);
  }

  static GlobeDataSource? _loadedSource;
  static Future<void>? _pendingLoad;
  static GlobeDataSource? _pendingSource;

  /// Whether the data a widget with [source] needs is loaded. A `null`
  /// source accepts any loaded data.
  static bool isLoadedFrom(GlobeDataSource? source) =>
      isLoaded && (source == null || _loadedSource == source);

  /// Loads [source], unless it is already loaded. A `null` source keeps
  /// the loaded data, or loads the bundled data when nothing is loaded.
  /// Widgets call this; you rarely need to.
  /// [bundle] defaults to `rootBundle`.
  static Future<void> ensureLoaded([
    GlobeDataSource? source,
    AssetBundle? bundle,
  ]) {
    if (isLoadedFrom(source)) return Future.value();
    final target = source ?? GlobeDataSource.bundled;
    final pending = _pendingLoad;
    if (pending != null && _pendingSource == target) return pending;
    _pendingSource = target;
    return _pendingLoad = loadSource(target, bundle: bundle).whenComplete(() {
      if (_pendingSource == target) {
        _pendingLoad = null;
        _pendingSource = null;
      }
    });
  }

  static void _apply(
    GlobeDataSource source,
    String dataJson,
    String? translationsJson,
  ) {
    final data = jsonDecode(dataJson) as Map<String, dynamic>;
    final countryEntries = _applyOverrides(
      data['countries'] as List,
      source.countryOverrides,
      idKey: 'alpha2Code',
    );
    final currencyEntries = _applyOverrides(
      data['currencies'] as List,
      source.currencyOverrides,
      idKey: 'code',
    );
    final translations = _readTranslations(
      translationsJson,
      source.translationOverrides,
      languages: source.languages,
    );
    worldIndexData = WorldIndex.build(
      [
        for (final entry in countryEntries)
          _parse('country', entry['alpha2Code'], () {
            if ((entry['dialCodes'] as List?)?.isEmpty ?? true) {
              throw const FormatException('needs at least one dial code');
            }
            return GlobeCountry.fromJson(entry);
          }),
      ],
      [
        for (final entry in currencyEntries)
          _parse(
            'currency',
            entry['code'],
            () => GlobeCurrency.fromJson(entry),
          ),
      ],
      languageCountries: {
        for (final MapEntry(:key, :value)
            in (data['languageCountries'] as Map<String, dynamic>? ?? const {})
                .entries)
          key: value as String,
      },
      countryNames: {
        for (final MapEntry(key: language, value: names)
            in translations.entries)
          language: names['countries'] ?? const {},
      },
      currencyNames: {
        for (final MapEntry(key: language, value: names)
            in translations.entries)
          language: names['currencies'] ?? const {},
      },
    );
    _loadedSource = source;
    _searchIndexes.clear();
    _countriesByName.clear();
    _generation++;
    _changes.value = _generation;
  }

  /// Builds one model, turning any error into a [FormatException] that
  /// names the entry, for example `country ZZ: needs at least one dial code`.
  static T _parse<T>(String kind, Object? code, T Function() build) {
    try {
      return build();
    } on Object catch (error) {
      final reason = error is FormatException ? error.message : '$error';
      throw FormatException('Invalid globe data, $kind $code: $reason');
    }
  }

  /// Notifies with the new [generation] each time data is loaded, so widgets
  /// already on screen can show the new data.
  static ValueListenable<int> get changes => _changes;
  static final _changes = ValueNotifier<int>(0);

  /// Reads the translations JSON, keeps [languages] (all when `null`) and
  /// applies [overrides]. Returns language → kind → code → name.
  static GlobeTranslationOverrides _readTranslations(
    String? json,
    GlobeTranslationOverrides overrides, {
    required List<String>? languages,
  }) {
    if (languages != null && languages.isEmpty) return const {};
    final wanted = languages?.map((language) => language.toLowerCase()).toSet();
    final result = <String, Map<String, Map<String, String>>>{};
    void add(String language, String kind, Map<String, Object?> names) {
      if (wanted != null && !wanted.contains(language.toLowerCase())) return;
      final target = (result[language] ??= {})[kind] ??= {};
      for (final MapEntry(key: code, value: name) in names.entries) {
        if (name is String && name.isNotEmpty) target[code] = name;
      }
    }

    if (json != null) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      for (final MapEntry(key: language, value: kinds) in decoded.entries) {
        for (final MapEntry(key: kind, value: names)
            in (kinds as Map<String, dynamic>).entries) {
          add(language, kind, names as Map<String, dynamic>);
        }
      }
    }
    for (final MapEntry(key: language, value: kinds) in overrides.entries) {
      for (final MapEntry(key: kind, value: names) in kinds.entries) {
        add(language, kind, names);
      }
    }
    return result;
  }

  /// Applies [overrides] to the JSON [entries], keyed by [idKey]. Unknown
  /// ids are added as new entries.
  static List<Map<String, dynamic>> _applyOverrides(
    List<dynamic> entries,
    Map<String, Map<String, Object?>> overrides, {
    required String idKey,
  }) {
    final pending = {
      for (final MapEntry(:key, :value) in overrides.entries)
        key.toUpperCase(): value,
    };
    final result = <Map<String, dynamic>>[];
    for (final entry in entries.cast<Map<String, dynamic>>()) {
      final id = entry[idKey]! as String;
      final override = pending.remove(id.toUpperCase());
      // The id links everything together, so an override cannot change it.
      result.add(override == null ? entry : {...entry, ...override, idKey: id});
    }
    for (final MapEntry(:key, :value) in pending.entries) {
      result.add({...value, idKey: key});
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Collections
  // ---------------------------------------------------------------------------

  /// Every country and territory, sorted by English name.
  static List<GlobeCountry> get countries => _index.countries;

  /// Every currency in current use, sorted by code.
  static List<GlobeCurrency> get currencies => _index.currencies;

  /// Every dial code, sorted by calling code.
  static List<GlobeDialCode> get dialCodes => _index.dialCodes;

  /// Every date format, most used first.
  static List<GlobeDateFormat> get dateFormats => _index.dateFormats;

  // ---------------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------------

  /// Country by ISO alpha-2 code, for example `IN`. Case-insensitive.
  static GlobeCountry? countryByAlpha2(String code) =>
      _index.countriesByAlpha2[code.trim().toUpperCase()];

  /// Country by ISO alpha-3 code, for example `IND`. Case-insensitive.
  static GlobeCountry? countryByAlpha3(String code) =>
      _index.countriesByAlpha3[code.trim().toUpperCase()];

  /// Country by ISO numeric code, for example `356` or `4` (Afghanistan).
  static GlobeCountry? countryByNumCode(int code) => code < 0
      ? null
      : _index.countriesByNumCode[code.toString().padLeft(3, '0')];

  /// Country by any ISO code: alpha-2, alpha-3 or numeric.
  static GlobeCountry? countryByCode(String code) {
    final trimmed = code.trim();
    if (_numericCode.hasMatch(trimmed)) {
      return countryByNumCode(int.parse(trimmed));
    }
    return trimmed.length == 3
        ? countryByAlpha3(trimmed)
        : countryByAlpha2(trimmed);
  }

  /// Country whose English name, alias or name in [locale] equals [name],
  /// ignoring case and accents.
  static GlobeCountry? countryByName(String name, {Locale? locale}) {
    final wanted = normalizeSearchText(name);
    if (wanted.isEmpty) return null;
    final language = locale == null ? '' : translationLanguageFor(locale);
    final lookup = _countriesByName[language] ??= {
      // Built once per language; the first name listed wins.
      for (final country in countries.reversed) ...{
        for (final alias in country.aliases)
          normalizeSearchText(alias): country,
        normalizeSearchText(country.name): country,
        if (locale != null)
          normalizeSearchText(country.localizedName(locale)): country,
      },
    };
    return lookup[wanted];
  }

  static final Map<String, Map<String, GlobeCountry>> _countriesByName = {};

  /// Countries in [region], sorted by English name.
  static List<GlobeCountry> countriesByRegion(GlobeRegion region) =>
      countries.where((country) => country.region == region).toList();

  /// Countries that use [code] as a dial code or calling code.
  ///
  /// `+1` returns every country of the North American Numbering Plan,
  /// `+1876` returns only Jamaica.
  static List<GlobeCountry> countriesByDialCode(String code) {
    final normalized = _normalizeDialCode(code);
    if (normalized == null) return const [];
    return countries
        .where(
          (country) =>
              country.dialCodes.contains(normalized) ||
              country.callingCode == normalized,
        )
        .toList();
  }

  /// Dial code entry, for example `+91`. A missing `+` is added.
  static GlobeDialCode? dialCodeByCode(String code) {
    final normalized = _normalizeDialCode(code);
    return normalized == null ? null : _index.dialCodesByCode[normalized];
  }

  /// Currency by ISO 4217 code, for example `INR`. Case-insensitive.
  static GlobeCurrency? currencyByCode(String code) =>
      _index.currenciesByCode[code.trim().toUpperCase()];

  /// Currencies whose symbol or native symbol is [symbol], for example `$`.
  static List<GlobeCurrency> currenciesBySymbol(String symbol) {
    final wanted = symbol.trim();
    return currencies
        .where(
          (currency) =>
              currency.symbol == wanted || currency.nativeSymbol == wanted,
        )
        .toList();
  }

  /// Date format entry by pattern, for example `dd/MM/yyyy`.
  static GlobeDateFormat? dateFormatByPattern(String pattern) =>
      _index.dateFormatsByPattern[pattern.trim()];

  /// The country of [locale]: its country code when present (`en_IN` →
  /// India), otherwise the country most associated with its language
  /// (`ja` → Japan). Use it to preselect the user's country:
  ///
  /// ```dart
  /// GlobeData.countryFromLocale(Localizations.localeOf(context));
  /// ```
  static GlobeCountry? countryFromLocale(Locale locale) {
    final countryCode = locale.countryCode;
    if (countryCode != null && countryCode.isNotEmpty) {
      // A UN M.49 region such as `419` (Latin America) is no one country.
      if (_numericCode.hasMatch(countryCode)) return null;
      // `UK` is common but not ISO: the code of the United Kingdom is GB.
      final country = countryByAlpha2(
        countryCode.toUpperCase() == 'UK' ? 'GB' : countryCode,
      );
      if (country != null) return country;
    }
    final defaultCountry =
        _index.languageCountries[locale.languageCode.toLowerCase()];
    return defaultCountry == null ? null : countryByAlpha2(defaultCountry);
  }

  /// The main currency of the country of [locale].
  static GlobeCurrency? currencyFromLocale(Locale locale) =>
      countryFromLocale(locale)?.currency;

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  static final _numericCode = RegExp(r'^\d{1,3}$');
  static final _nonDigit = RegExp(r'\D');

  static final Map<String, GlobeSearchIndex<GlobeItem>> _searchIndexes = {};

  static GlobeSearchIndex<T> _indexFor<T extends GlobeItem>(
    String name,
    List<T> items,
    List<GlobeField> fields,
    Locale? locale,
  ) {
    final language = locale == null ? '' : translationLanguageFor(locale);
    final key =
        '$name|${fields.map((field) => field.name).join(',')}|$language';
    return (_searchIndexes[key] ??= GlobeSearchIndex<T>(
          items,
          fields: fields,
          locale: locale,
        ))
        as GlobeSearchIndex<T>;
  }

  /// Countries matching [query] by name (English, alias or [locale]), ISO
  /// codes, dial code, capital or currency code. Best matches first.
  static List<GlobeCountry> searchCountries(String query, {Locale? locale}) =>
      _indexFor('countries', countries, const [
        GlobeField.countryName,
        GlobeField.alpha2Code,
        GlobeField.alpha3Code,
        GlobeField.dialCode,
        GlobeField.capital,
        GlobeField.currencyCode,
      ], locale).search(query);

  /// Currencies matching [query] by code, name (English or [locale]),
  /// symbol or country name.
  static List<GlobeCurrency> searchCurrencies(String query, {Locale? locale}) =>
      _indexFor('currencies', currencies, const [
        GlobeField.currencyCode,
        GlobeField.currencyName,
        GlobeField.currencySymbol,
        GlobeField.countryName,
      ], locale).search(query);

  /// Dial codes matching [query] by code or country name.
  static List<GlobeDialCode> searchDialCodes(String query, {Locale? locale}) =>
      _indexFor('dialCodes', dialCodes, const [
        GlobeField.dialCode,
        GlobeField.countryName,
        GlobeField.alpha2Code,
      ], locale).search(query);

  /// Countries and currencies matching [query], countries first.
  static List<GlobeItem> search(String query, {Locale? locale}) => [
    ...searchCountries(query, locale: locale),
    ...searchCurrencies(query, locale: locale),
  ];

  // ---------------------------------------------------------------------------
  // Phone numbers
  // ---------------------------------------------------------------------------

  /// Parses a phone number.
  ///
  /// Numbers starting with `+`, or with the international dialling prefix
  /// of [defaultCountry] (`00`, `011` in the US, `0011` in Australia), are
  /// matched to a country by calling code; shared codes such as `+1` and
  /// `+44` are resolved from area codes. `00` works without a default
  /// country. Other numbers are national numbers of [defaultCountry], or of
  /// the country sharing its calling code that owns them (`07400 123456`
  /// with Jersey as default is a UK mobile).
  ///
  /// Pasted text is cleaned first: invisible direction marks are removed,
  /// full-width `＋` and non-Latin digits are read, and an extension such as
  /// `ext. 123` is dropped.
  ///
  /// Returns `null` when no country can be determined. The result may still
  /// be invalid: check [GlobePhoneNumber.isValid].
  static GlobePhoneNumber? parsePhone(
    String input, {
    GlobeCountry? defaultCountry,
  }) {
    final text = normalizePhoneInput(input).trim();
    final digits = text.replaceAll(_nonDigit, '');
    if (digits.isEmpty) return null;
    if (text.startsWith('+')) return _parseInternational(digits);

    if (defaultCountry != null) {
      final afterPrefix = _afterInternationalPrefix(
        digits,
        defaultCountry.phoneInternationalPrefix,
      );
      if (afterPrefix != null) {
        final parsed = _parseInternational(afterPrefix);
        if (parsed != null) return parsed;
      }
      final national = defaultCountry.normalizeNationalNumber(digits) ?? digits;
      final owner = _index.ownerOfNationalNumber(
        defaultCountry.callingCode,
        national,
      );
      return GlobePhoneNumber(
        country: owner ?? defaultCountry,
        nationalNumber: digits,
      );
    }
    final afterZeros = _afterInternationalPrefix(digits, '00');
    return afterZeros == null ? null : _parseInternational(afterZeros);
  }

  static GlobePhoneNumber? _parseInternational(String digits) {
    final resolved = _index.resolveInternationalDigits(digits);
    if (resolved == null) return null;
    return GlobePhoneNumber(country: resolved.$1, nationalNumber: resolved.$2);
  }

  /// The digits after an international dialling prefix such as `00` or
  /// `011`, or `null` when [digits] do not start with one. Calling codes
  /// never start with `0`, so `000800…` in India stays a national number.
  static String? _afterInternationalPrefix(String digits, String? prefix) {
    if (prefix == null) return null;
    final match = _index.prefixPattern(prefix).firstMatch(digits);
    if (match == null || match.end >= digits.length) return null;
    final rest = digits.substring(match.end);
    return rest.startsWith('0') ? null : rest;
  }

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  /// Formats a date with [pattern], or with the usual format of the country
  /// [countryCode] (alpha-2). Uses `yyyy-MM-dd` when neither is given.
  ///
  /// ```dart
  /// GlobeData.formatDate(date, countryCode: 'US');          // 11/08/2026
  /// GlobeData.formatDate(date, pattern: 'EEE, d MMM yyyy'); // Sun, 8 Nov 2026
  /// ```
  ///
  /// Throws an [ArgumentError] for an unknown [countryCode].
  static String formatDate(
    DateTime dateTime, {
    String? countryCode,
    String? pattern,
    GlobeDateSymbols symbols = GlobeDateSymbols.english,
  }) {
    // Checked even when a pattern is given, as documented.
    final country = _countryOrThrow(countryCode);
    return formatDatePattern(
      dateTime,
      pattern ?? country?.dateFormat.pattern ?? 'yyyy-MM-dd',
      symbols: symbols,
    );
  }

  /// Formats a date and time: the date like [formatDate], followed by the
  /// time as `HH:mm` or, when [use24Hour] is `false`, `hh:mm a`.
  static String formatDateTime(
    DateTime dateTime, {
    String? countryCode,
    String? pattern,
    bool use24Hour = true,
    bool showSeconds = false,
    GlobeDateSymbols symbols = GlobeDateSymbols.english,
  }) {
    final seconds = showSeconds ? ':ss' : '';
    final timePattern = use24Hour ? 'HH:mm$seconds' : 'hh:mm$seconds a';
    return '${formatDate(dateTime, countryCode: countryCode, pattern: pattern, symbols: symbols)} '
        '${formatDatePattern(dateTime, timePattern, symbols: symbols)}';
  }

  /// Formats [amount] in the currency [currencyCode], laid out the way the
  /// country [countryCode] writes money (defaults to the issuing country).
  ///
  /// Throws an [ArgumentError] for an unknown currency or country code.
  static String formatCurrency(
    num amount, {
    required String currencyCode,
    String? countryCode,
    bool useNativeSymbol = false,
  }) {
    final currency = currencyByCode(currencyCode);
    if (currency == null) {
      throw ArgumentError.value(currencyCode, 'currencyCode', 'Unknown code');
    }
    return currency.format(
      amount,
      country: _countryOrThrow(countryCode),
      useNativeSymbol: useNativeSymbol,
    );
  }

  static GlobeCountry? _countryOrThrow(String? countryCode) {
    if (countryCode == null) return null;
    final country = countryByAlpha2(countryCode);
    if (country == null) {
      throw ArgumentError.value(countryCode, 'countryCode', 'Unknown code');
    }
    return country;
  }

  static String? _normalizeDialCode(String code) {
    final digits = code.replaceAll(_nonDigit, '');
    return digits.isEmpty ? null : '+$digits';
  }
}
