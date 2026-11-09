import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final countries = GlobeData.countries;
  List<String> codes(Iterable<GlobeItem> items) => [
    for (final item in items) item.id,
  ];

  test('empty filter keeps everything', () {
    expect(GlobeFilter.none.isEmpty, isTrue);
    expect(GlobeFilter.none.apply(countries).length, countries.length);
  });

  test('country include and exclude, case-insensitive', () {
    const only = GlobeFilter(countries: ['in', 'US']);
    expect(codes(only.apply(countries)), unorderedEquals(['IN', 'US']));
    const exclude = GlobeFilter(excludeCountries: ['in']);
    expect(codes(exclude.apply(countries)), isNot(contains('IN')));
    expect(exclude.apply(countries).length, countries.length - 1);
  });

  test('regions', () {
    const europe = GlobeFilter(regions: [GlobeRegion.europe]);
    expect(
      europe
          .apply(countries)
          .every((country) => country.region == GlobeRegion.europe),
      isTrue,
    );
    const notEurope = GlobeFilter(excludeRegions: [GlobeRegion.europe]);
    expect(
      notEurope
          .apply(countries)
          .any((country) => country.region == GlobeRegion.europe),
      isFalse,
    );
  });

  test('custom rule', () {
    final euroUsers = GlobeFilter(
      where: (currency) => currency.currency?.code == 'EUR',
    );
    expect(codes(euroUsers.apply(countries)), containsAll(['DE', 'FR']));
    expect(codes(euroUsers.apply(countries)), isNot(contains('US')));
  });

  test('presets', () {
    expect(GlobeFilter.europeanUnion.apply(countries).length, 27);
    expect(GlobeFilter.eurozone.apply(countries).length, 21);
    expect(GlobeFilter.unMembers.apply(countries).length, 193);
  });

  test('currency rules only filter currency items', () {
    const filter = GlobeFilter(excludeCurrencies: ['usd']);
    expect(codes(filter.apply(GlobeData.currencies)), isNot(contains('USD')));
    expect(codes(filter.apply(countries)), contains('US'));
    const only = GlobeFilter(currencies: ['EUR', 'INR']);
    expect(codes(only.apply(GlobeData.currencies)), ['EUR', 'INR']);
  });

  test('dial code rules accept codes with or without +', () {
    const filter = GlobeFilter(dialCodes: ['91', '+44']);
    expect(codes(filter.apply(GlobeData.dialCodes)), ['+44', '+91']);
    const exclude = GlobeFilter(excludeDialCodes: ['+1']);
    expect(codes(exclude.apply(GlobeData.dialCodes)), isNot(contains('+1')));
  });

  test('country rules apply to every item type', () {
    const filter = GlobeFilter(countries: ['IN']);
    expect(codes(filter.apply(GlobeData.currencies)), ['INR']);
    expect(codes(filter.apply(GlobeData.dialCodes)), ['+91']);
    expect(codes(filter.apply(GlobeData.dateFormats)), ['dd/MM/yyyy']);
    // The euro stays while at least one euro country is allowed.
    const noFrance = GlobeFilter(excludeCountries: ['FR']);
    expect(codes(noFrance.apply(GlobeData.currencies)), contains('EUR'));
  });

  test('combining with + requires both filters', () {
    const first = GlobeFilter(
      countries: ['IN', 'US', 'FR'],
      excludeCurrencies: ['USD'],
    );
    const second = GlobeFilter(countries: ['US', 'FR', 'DE']);
    final combined = first + second;
    expect(combined.countries, ['US', 'FR']);
    expect(combined.excludeCurrencies, ['USD']);
    final withRules =
        GlobeFilter(where: (country) => country.region == GlobeRegion.europe) +
        GlobeFilter(where: (country) => country.isEurozone);
    // Cyprus uses the euro but is in Western Asia (UN M.49).
    expect(withRules.apply(countries).length, 20);
    expect(codes(withRules.apply(countries)), isNot(contains('CY')));
    expect((GlobeFilter.none + first).countries, first.countries);
  });

  test('combining "only" lists without a common value keeps nothing', () {
    final countriesOnly =
        const GlobeFilter(countries: ['IN']) +
        const GlobeFilter(countries: ['US']);
    expect(countriesOnly.apply(countries), isEmpty);

    final currenciesOnly =
        const GlobeFilter(currencies: ['INR']) +
        const GlobeFilter(currencies: ['USD']);
    expect(currenciesOnly.apply(GlobeData.currencies), isEmpty);
    // Currency rules do not touch the country list.
    expect(currenciesOnly.apply(countries).length, countries.length);

    final dialCodesOnly =
        const GlobeFilter(dialCodes: ['+91']) +
        const GlobeFilter(dialCodes: ['+1']);
    expect(dialCodesOnly.apply(GlobeData.dialCodes), isEmpty);

    final regionsOnly =
        const GlobeFilter(regions: [GlobeRegion.asia]) +
        const GlobeFilter(regions: [GlobeRegion.europe]);
    expect(regionsOnly.apply(countries), isEmpty);
    expect(regionsOnly.apply(GlobeData.currencies), isEmpty);
  });

  test('copyWith and equality', () {
    const filter = GlobeFilter(countries: ['IN']);
    expect(filter.copyWith(regions: [GlobeRegion.asia]).regions, [
      GlobeRegion.asia,
    ]);
    expect(filter.copyWith().countries, ['IN']);
    expect(filter, const GlobeFilter(countries: ['IN']));
    expect(filter.hashCode, const GlobeFilter(countries: ['IN']).hashCode);
    expect(filter == const GlobeFilter(countries: ['US']), isFalse);
  });
}
