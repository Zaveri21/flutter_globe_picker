import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';
import 'package:flutter_globe_picker/src/search/globe_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeSearchText', () {
    expect(normalizeSearchText('  Côte d’Ivoire '), 'cote d ivoire');
    expect(normalizeSearchText('São Tomé & Príncipe'), 'sao tome principe');
    expect(normalizeSearchText('Straße'), 'strasse');
    expect(normalizeSearchText('+1 (876)'), '1 876');
    expect(normalizeSearchText('Guinea-Bissau'), 'guinea bissau');
    expect(normalizeSearchText(''), '');
    // Decomposed (NFD) accents, as in pasted text.
    expect(normalizeSearchText('Co\u0302te'), 'cote');
    expect(GlobeData.searchCountries('Co\u0302te').first.alpha2Code, 'CI');
  });

  test('ranking: exact, prefix, word prefix, contains', () {
    final index = GlobeSearchIndex(
      GlobeData.countries,
      fields: const [GlobeField.countryName],
    );
    final results = index.search('guinea');
    expect(results.first.name, 'Guinea');
    expect(results[1].name, startsWith('Guinea'));
    expect(
      results.map((country) => country.name),
      contains('Papua New Guinea'),
    );
    expect(index.search('  '), hasLength(GlobeData.countries.length));
  });

  test('fields', () {
    expect(
      globeFieldValues(
        GlobeData.currencyByCode('EUR')!,
        GlobeField.countryName,
      ),
      contains('Germany'),
    );
    expect(
      globeFieldValues(GlobeData.countryByAlpha2('IN')!, GlobeField.flag),
      isEmpty,
    );
    expect(
      globeFieldValues(
        GlobeData.dialCodeByCode('+91')!,
        GlobeField.currencyCode,
      ),
      ['INR'],
    );
    expect(
      globeFieldValues(
        GlobeData.dateFormatByPattern('MM/dd/yyyy')!,
        GlobeField.dateExample,
        today: DateTime(2026, 11, 8),
      ),
      ['11/08/2026'],
    );
    expect(
      globeFieldValues(GlobeData.countryByAlpha2('IN')!, GlobeField.region),
      ['Asia'],
    );
    expect(
      globeFieldValues(GlobeData.countryByAlpha2('IN')!, GlobeField.capital),
      ['New Delhi'],
    );
  });
}
