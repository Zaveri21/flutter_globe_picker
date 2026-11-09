/// The linked world model: countries, currencies, dial codes and date
/// formats that all point to each other.
library;

import 'dart:ui' show Locale;

import 'package:flutter_globe_picker/src/format/globe_date_formatter.dart';
import 'package:flutter_globe_picker/src/format/globe_number_format.dart';
import 'package:flutter_globe_picker/src/models/globe_region.dart';
import 'package:flutter_globe_picker/src/search/globe_search.dart';

part 'globe_country.dart';
part 'globe_currency.dart';
part 'globe_date_format.dart';
part 'globe_dial_code.dart';
part 'world_index.dart';

/// Base type of everything a picker can show.
///
/// It is `sealed`, so a `switch` over a [GlobeItem] is checked by the
/// compiler:
///
/// ```dart
/// final label = switch (item) {
///   GlobeCountry(:final name) => name,
///   GlobeCurrency(:final code) => code,
///   GlobeDialCode(:final code) => code,
///   GlobeDateFormat(:final pattern) => pattern,
/// };
/// ```
///
/// Items are created once by `GlobeData` and never change afterwards.
sealed class GlobeItem {
  const GlobeItem();

  /// Unique key within its type: alpha-2 code, currency code, dial code or
  /// date pattern.
  String get id;

  /// English name shown by default in pickers.
  String get displayName;

  /// Name in the language of [locale] from the loaded translations, or
  /// [displayName] when there is none.
  String localizedName(Locale? locale) => displayName;

  /// The countries this item belongs to.
  List<GlobeCountry> get countries;

  /// The country used for flags and country related fields, if any.
  GlobeCountry? get representativeCountry;

  /// Lowercase code of the flag to show for this item (for example `in`,
  /// `eu`), or `null` when the item has no flag.
  String? get flagCode => representativeCountry?.alpha2Code.toLowerCase();
}

/// The translation language that best matches [locale]: `zh-Hant` for
/// Traditional Chinese, and current codes for legacy ones (`iw` → `he`).
String translationLanguageFor(Locale locale) {
  final language = locale.languageCode.toLowerCase();
  if (language == 'zh') {
    final usesTraditionalScript =
        locale.scriptCode == 'Hant' ||
        (locale.scriptCode == null &&
            const {'TW', 'HK', 'MO'}.contains(locale.countryCode));
    return usesTraditionalScript ? 'zh-Hant' : 'zh';
  }
  if (language == 'iw') return 'he';
  if (language == 'in') return 'id';
  return language;
}
