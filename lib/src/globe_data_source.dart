import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle;

import 'package:flutter_globe_picker/src/globe_data.dart';

/// Translated names to add or replace: language (`hi`, `zh-Hant`), then
/// `countries` or `currencies`, then alpha-2 or currency code.
///
/// ```dart
/// const fixes = {
///   'hi': {
///     'countries': {'IN': 'भारत गणराज्य'},
///     'currencies': {'INR': 'रुपया'},
///   },
/// };
/// ```
typedef GlobeTranslationOverrides =
    Map<String, Map<String, Map<String, String>>>;

/// Where the data comes from, and what to change in it before use.
///
/// The data is two JSON files: `globe_data.json` (countries and currencies)
/// and `globe_translations.json` (their names in other languages, linked by
/// code). Each can be the bundled file, your own asset, or JSON text, and
/// every value can be overridden.
///
/// Pass it to [GlobeData.loadSource] or to a widget's `dataSource`. Every
/// widget shares one data set: a widget with a different source replaces it
/// for the whole app. Widgets without a source use the data already loaded,
/// or the bundled data.
///
/// ```dart
/// // Your updated copy of globe_data.json, declared in your pubspec.
/// const mySource = GlobeDataSource(assetKey: 'assets/my_globe_data.json');
///
/// // The bundled data with a few changes, in English and Hindi only.
/// const custom = GlobeDataSource(
///   languages: ['hi'],
///   countryOverrides: {'IN': {'name': 'Bharat'}},
///   translationOverrides: {'hi': {'countries': {'IN': 'भारत गणराज्य'}}},
/// );
///
/// GlobePicker.country(context, dataSource: mySource);
/// GlobePhoneField(pickerOptions: GlobePickerOptions(dataSource: custom));
/// ```
@immutable
class GlobeDataSource {
  /// Creates a data source. With no arguments it is the bundled data with
  /// every bundled language.
  ///
  /// [json] takes precedence over [assetKey], and [translationsJson] over
  /// [translationsAssetKey].
  const GlobeDataSource({
    this.assetKey = GlobeData.assetKey,
    this.json,
    this.translationsAssetKey = GlobeData.translationsAssetKey,
    this.translationsJson,
    this.languages,
    this.countryOverrides = const {},
    this.currencyOverrides = const {},
    this.translationOverrides = const {},
  });

  /// The bundled data, unchanged.
  static const bundled = GlobeDataSource();

  /// Asset key of a JSON file shaped like `assets/globe_data.json`.
  final String assetKey;

  /// JSON text shaped like `assets/globe_data.json`, for example downloaded
  /// from your server. Used instead of [assetKey] when set.
  final String? json;

  /// Asset key of a JSON file shaped like `assets/globe_translations.json`.
  final String translationsAssetKey;

  /// JSON text shaped like `assets/globe_translations.json`. Used instead of
  /// [translationsAssetKey] when set.
  final String? translationsJson;

  /// Languages to keep, for example `['hi', 'fr']`. `null` keeps every
  /// language of the translations; an empty list skips translations, so
  /// every name is English.
  final List<String>? languages;

  /// Fields to replace per alpha-2 code. See [GlobeData.load].
  final Map<String, Map<String, Object?>> countryOverrides;

  /// Fields to replace per currency code. See [GlobeData.load].
  final Map<String, Map<String, Object?>> currencyOverrides;

  /// Translated names to add or replace. See [GlobeTranslationOverrides].
  final GlobeTranslationOverrides translationOverrides;

  /// Whether this source loads any translations.
  bool get usesTranslations => languages?.isNotEmpty ?? true;

  /// Loads this source into [GlobeData]. Same as [GlobeData.loadSource].
  Future<void> load({AssetBundle? bundle}) =>
      GlobeData.loadSource(this, bundle: bundle);

  // Overrides are compared by content, so a source created again in every
  // build (with new map instances) does not reload the data. The encoded
  // text is computed once per instance.
  String get _overridesSignature => _signatures[this] ??= jsonEncode([
    languages,
    countryOverrides,
    currencyOverrides,
    translationOverrides,
  ], toEncodable: (value) => value.toString());

  static final _signatures = Expando<String>('GlobeDataSource signature');

  @override
  bool operator ==(Object other) =>
      other is GlobeDataSource &&
      other.assetKey == assetKey &&
      other.json == json &&
      other.translationsAssetKey == translationsAssetKey &&
      other.translationsJson == translationsJson &&
      ((identical(other.languages, languages) &&
              identical(other.countryOverrides, countryOverrides) &&
              identical(other.currencyOverrides, currencyOverrides) &&
              identical(other.translationOverrides, translationOverrides)) ||
          other._overridesSignature == _overridesSignature);

  @override
  int get hashCode => Object.hash(
    assetKey,
    json?.length,
    translationsAssetKey,
    translationsJson?.length,
    _overridesSignature,
  );
}
