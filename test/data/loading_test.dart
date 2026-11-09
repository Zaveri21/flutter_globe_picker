import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves the bundled JSON under [GlobeData.assetKey] and counts the reads.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, String> assets;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    reads++;
    final text = assets[key];
    if (text == null) throw StateError('Unable to load asset: $key');
    return ByteData.sublistView(utf8.encode(text));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    reads++;
    final text = assets[key];
    if (text == null) throw StateError('Unable to load asset: $key');
    return text;
  }
}

void main() {
  final json = File('assets/globe_data.json').readAsStringSync();
  final translationsJson = File('assets/globe_translations.json')
      .readAsStringSync();
  final data = jsonDecode(json) as Map<String, dynamic>;
  List<Map<String, dynamic>> entries(String key) => [
    for (final item in data[key] as List) item as Map<String, dynamic>,
  ];

  // Every test starts from the plain bundled data.
  tearDown(
    () => GlobeData.loadFromJson(json, translationsJson: translationsJson),
  );

  test('models match assets/globe_data.json exactly', () {
    final countries = entries('countries');
    expect(GlobeData.countries.length, countries.length);
    for (final expected in countries) {
      final code = expected['alpha2Code'] as String;
      final country = GlobeData.countryByAlpha2(code)!;
      expect(expected['flagEmoji'], country.flagEmoji, reason: code);
      expect(expected['flag'], country.flagAssetPath(), reason: code);
      expect(
        expected['flagSquare'],
        country.flagAssetPath(GlobeFlagAspect.square),
        reason: code,
      );
      // Derived keys and `formatLocale` (the CLDR source locale) are not
      // model fields.
      final modelFields = Map.of(expected)
        ..remove('flagEmoji')
        ..remove('flag')
        ..remove('flagSquare')
        ..remove('formatLocale');
      expect(country.toJson(), modelFields, reason: code);
    }
    final currencies = entries('currencies');
    expect(GlobeData.currencies.length, currencies.length);
    for (final expected in currencies) {
      final code = expected['code'] as String;
      expect(GlobeData.currencyByCode(code)!.toJson(), expected, reason: code);
      expect(GlobeCurrency.fromJson(expected).toJson(), expected);
    }
  });

  test('overrides change fields, add entries and relink everything', () {
    GlobeData.loadFromJson(
      json,
      countryOverrides: {
        'in': {'name': 'Bharat', 'capital': null},
        'ZZ': {
          'name': 'Zedland',
          'alpha2Code': 'ZZ',
          'alpha3Code': 'ZZZ',
          'region': 'europe',
          'subregion': 'Northern Europe',
          'dialCodes': ['+999'],
          'currencyCodes': ['ZZD'],
          'dateFormat': 'dd/MM/yyyy',
        },
      },
      currencyOverrides: {
        'INR': {'symbol': 'Rs'},
        'ZZD': {'name': 'Zed Dollar', 'symbol': 'Z\$'},
      },
    );
    final india = GlobeData.countryByAlpha2('IN')!;
    expect(india.name, 'Bharat');
    expect(india.capital, isNull);
    expect(india.alpha3Code, 'IND');
    expect(india.currency?.symbol, 'Rs');
    expect(GlobeData.searchCountries('bharat').first, india);

    final zedland = GlobeData.countryByAlpha2('ZZ')!;
    expect(zedland.currency?.name, 'Zed Dollar');
    expect(GlobeData.dialCodeByCode('+999')?.country, zedland);
    expect(GlobeData.countries.length, 251);
    expect(GlobeData.currencies.length, 154);
  });

  test('an incomplete new entry fails with a clear error', () {
    expect(
      () => GlobeData.loadFromJson(
        json,
        countryOverrides: {
          'ZZ': {'name': 'Zedland'},
        },
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('country ZZ'),
        ),
      ),
    );
    // The previous data stays loaded.
    expect(GlobeData.countryByAlpha2('IN')?.name, 'India');
  });

  test('overrides cannot break ids or dial codes, and accept 2.0 for 2', () {
    expect(
      () => GlobeData.loadFromJson(
        json,
        countryOverrides: {
          'IN': {'dialCodes': <String>[]},
        },
      ),
      throwsA(isA<FormatException>()),
    );
    GlobeData.loadFromJson(
      json,
      countryOverrides: {
        'IN': {
          'alpha2Code': 'in',
          'phoneLengths': [10.0],
        },
      },
      currencyOverrides: {
        'INR': {'decimalDigits': 2.0},
      },
    );
    final india = GlobeData.countryByAlpha2('IN')!;
    expect(india.alpha2Code, 'IN');
    expect(india.phoneLengths, [10]);
    expect(india.currency?.decimalDigits, 2);
  });

  test('translation overrides work without a translations file', () {
    GlobeData.loadFromJson(
      json,
      translationOverrides: {
        'hi': {
          'countries': {'IN': 'भारत'},
        },
      },
    );
    expect(
      GlobeData.countryByAlpha2('IN')!.localizedName(const Locale('hi')),
      'भारत',
    );
  });

  test('a newer load wins over an older one that finishes later', () async {
    final slowBundle = _FakeBundle({
      GlobeData.assetKey: json,
      GlobeData.translationsAssetKey: translationsJson,
    });
    final older = GlobeData.load(bundle: slowBundle);
    GlobeData.loadFromJson(
      json,
      countryOverrides: {
        'IN': {'name': 'Bharat'},
      },
    );
    await older;
    expect(GlobeData.countryByAlpha2('IN')?.name, 'Bharat');
  });

  test('sources with values that are not JSON still compare', () {
    final first = GlobeDataSource(
      countryOverrides: {
        'IN': {'region': GlobeRegion.asia},
      },
    );
    final second = GlobeDataSource(
      countryOverrides: {
        'IN': {'region': GlobeRegion.asia},
      },
    );
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first == GlobeDataSource.bundled, isFalse);
  });

  test(
    'load reads the asset once per source and bumps the generation',
    () async {
      final bundle = _FakeBundle({
        GlobeData.assetKey: json,
        GlobeData.translationsAssetKey: translationsJson,
      });
      final before = GlobeData.generation;
      await GlobeData.load(bundle: bundle);
      expect(bundle.reads, 2);
      expect(GlobeData.languages, contains('hi'));
      expect(GlobeData.generation, before + 1);
      expect(GlobeData.isLoadedFrom(GlobeDataSource.bundled), isTrue);
      expect(GlobeData.isLoadedFrom(null), isTrue);

      const renamed = GlobeDataSource(
        countryOverrides: {
          'IN': {'name': 'Bharat'},
        },
      );
      expect(GlobeData.isLoadedFrom(renamed), isFalse);
      // Same content in new map instances counts as the same source.
      expect(
        renamed,
        GlobeDataSource(
          countryOverrides: {
            'IN': {'name': 'Bharat'},
          },
        ),
      );
    },
  );

  test('ensureLoaded loads a JSON source once', () async {
    final source = GlobeDataSource(
      json: json,
      translationsJson: translationsJson,
      currencyOverrides: const {
        'INR': {'symbol': 'Rs'},
      },
    );
    await Future.wait([
      GlobeData.ensureLoaded(source),
      GlobeData.ensureLoaded(source),
    ]);
    expect(GlobeData.currencyByCode('INR')?.symbol, 'Rs');
    final generation = GlobeData.generation;
    await GlobeData.ensureLoaded(source);
    await GlobeData.ensureLoaded();
    expect(GlobeData.generation, generation);
  });

  testWidgets('a picker loads its data source by itself', (tester) async {
    final source = GlobeDataSource(
      json: json,
      translationsJson: translationsJson,
      countryOverrides: const {
        'IN': {'name': 'Bharat'},
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobePickerView<GlobeCountry>(
            type: GlobePickerType.country,
            options: GlobePickerOptions(
              dataSource: source,
              filter: const GlobeFilter(countries: ['IN', 'JP']),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bharat'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);
    expect(GlobeData.isLoadedFrom(source), isTrue);
  });

  group('translations', () {
    const hindi = Locale('hi');

    test('names in a language, with English as the fallback', () {
      final india = GlobeData.countryByAlpha2('IN')!;
      expect(india.localizedName(hindi), 'भारत');
      expect(india.localizedName(const Locale('fr')), 'Inde');
      expect(india.currency!.localizedName(hindi), 'भारतीय रुपया');
      // No translations for this language: English.
      expect(india.localizedName(const Locale('sw')), 'India');
      expect(india.localizedName(null), 'India');
      // Traditional Chinese by script or region, legacy Hebrew code.
      final taiwan = GlobeData.countryByAlpha2('TW')!;
      expect(
        taiwan.localizedName(const Locale('zh', 'TW')),
        taiwan.localizedName(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
      );
      expect(
        india.localizedName(const Locale('iw')),
        india.localizedName(const Locale('he')),
      );
    });

    test('every bundled language names every country and currency', () {
      final decoded = jsonDecode(translationsJson) as Map<String, dynamic>;
      expect(decoded.keys, hasLength(29));
      for (final MapEntry(key: language, value: kinds) in decoded.entries) {
        final names = kinds as Map<String, dynamic>;
        expect((names['countries'] as Map).keys.toSet(), {
          for (final country in GlobeData.countries) country.alpha2Code,
        }, reason: language);
        expect((names['currencies'] as Map).keys.toSet(), {
          for (final currency in GlobeData.currencies) currency.code,
        }, reason: language);
      }
    });

    test('search and lookup in a language, English still matches', () {
      expect(
        GlobeData.searchCountries('भारत', locale: hindi).first.alpha2Code,
        'IN',
      );
      expect(
        GlobeData.searchCountries('india', locale: hindi).first.alpha2Code,
        'IN',
      );
      expect(
        GlobeData.searchCurrencies('रुपया', locale: hindi).first.code,
        'INR',
      );
      expect(GlobeData.countryByName('भारत', locale: hindi)?.alpha2Code, 'IN');
      expect(GlobeData.countryByName('भारत'), isNull);
    });

    test('overrides, missing names and the languages filter', () {
      GlobeData.loadFromJson(
        json,
        translationsJson: translationsJson,
        languages: ['hi'],
        translationOverrides: {
          'hi': {
            'countries': {'IN': 'भारत गणराज्य'},
          },
          'xx': {
            'countries': {'IN': 'ignored, not in languages'},
          },
        },
        countryOverrides: {
          'ZZ': {
            'name': 'Zedland',
            'alpha2Code': 'ZZ',
            'alpha3Code': 'ZZZ',
            'region': 'europe',
            'subregion': 'Northern Europe',
            'dialCodes': ['+999'],
            'currencyCodes': ['EUR'],
            'dateFormat': 'dd/MM/yyyy',
          },
        },
      );
      expect(GlobeData.languages, ['hi']);
      expect(
        GlobeData.countryByAlpha2('IN')!.localizedName(hindi),
        'भारत गणराज्य',
      );
      expect(
        GlobeData.countryByAlpha2('IN')!.localizedName(const Locale('fr')),
        'India',
      );
      // A new country without a translation shows its English name.
      expect(GlobeData.countryByAlpha2('ZZ')!.localizedName(hindi), 'Zedland');
    });

    test('an empty languages list skips translations', () {
      GlobeData.loadFromJson(
        json,
        translationsJson: translationsJson,
        languages: const [],
      );
      expect(GlobeData.languages, isEmpty);
      expect(GlobeData.countryByAlpha2('IN')!.localizedName(hindi), 'India');
    });

    testWidgets('pickers show and sort names in the app language', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            // French as the app locale, keeping the English Material texts.
            builder: (context) => Localizations.override(
              context: context,
              locale: const Locale('fr'),
              child: const Scaffold(
                body: GlobePickerView<GlobeCountry>(
                  type: GlobePickerType.country,
                  options: GlobePickerOptions(
                    filter: GlobeFilter(countries: ['DE', 'IN', 'ES']),
                    // The search field needs French Material texts, which
                    // tests do not have. Search is covered above.
                    search: GlobeSearchConfig(enabled: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final titles = [
        for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
          (tile.title! as Text).data!,
      ];
      // Allemagne, Espagne, Inde: sorted by the French name.
      expect(titles, ['Allemagne', 'Espagne', 'Inde']);
    });
  });
}
