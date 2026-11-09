import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('countries', () {
    final countries = GlobeData.countries;

    test('cover ISO 3166-1 plus Kosovo', () {
      expect(countries.length, 250);
    });

    test('have unique, well formed codes', () {
      final alpha2 = <String>{};
      final alpha3 = <String>{};
      final numeric = <String>{};
      for (final country in countries) {
        expect(country.alpha2Code, matches(RegExp(r'^[A-Z]{2}$')));
        expect(country.alpha3Code, matches(RegExp(r'^[A-Z]{3}$')));
        expect(alpha2.add(country.alpha2Code), isTrue);
        expect(alpha3.add(country.alpha3Code), isTrue);
        final numCode = country.numCode;
        if (numCode != null) {
          expect(numCode, matches(RegExp(r'^\d{3}$')));
          expect(numeric.add(numCode), isTrue, reason: country.alpha2Code);
        }
      }
    });

    test('are sorted by name, ignoring accents', () {
      final keys = countries
          .map((country) => normalizeSearchText(country.name))
          .toList();
      expect(keys, orderedEquals([...keys]..sort()));
      expect(countries.first.name, 'Afghanistan');
      expect(countries[1].name, 'Åland Islands');
    });

    test('have names, dial codes and date formats', () {
      for (final country in countries) {
        expect(country.name.trim(), isNotEmpty);
        expect(country.dialCodes, isNotEmpty, reason: country.alpha2Code);
        for (final code in country.dialCodes) {
          expect(code, matches(RegExp(r'^\+\d{1,4}$')));
        }
        expect(country.callingCode, matches(RegExp(r'^\+\d{1,3}$')));
        expect(
          country.dateFormat.pattern,
          matches(RegExp(r'^[dMy./\- ]+$')),
          reason: country.alpha2Code,
        );
        expect(country.flagEmoji.runes.length, 2);
      }
    });

    test('have currencies except Antarctica', () {
      for (final country in countries) {
        if (country.alpha2Code == 'AQ') {
          expect(country.currency, isNull);
          continue;
        }
        expect(country.currency, isNotNull, reason: country.alpha2Code);
        expect(country.currency!.countries, contains(country));
      }
    });

    test('each calling code has exactly one main country', () {
      final byCallingCode = <String, List<GlobeCountry>>{};
      for (final country in countries) {
        if (country.phonePattern == null) continue;
        byCallingCode.putIfAbsent(country.callingCode, () => []).add(country);
      }
      for (final MapEntry(key: code, value: group) in byCallingCode.entries) {
        expect(
          group.where((country) => country.isMainCountryForDialCode).length,
          1,
          reason: code,
        );
      }
    });

    test('example phone numbers are valid', () {
      for (final country in countries) {
        final example = country.phoneExample;
        if (example == null) continue;
        expect(
          country.isValidPhoneNumber(example),
          isTrue,
          reason: '${country.alpha2Code} $example',
        );
        final parsed = GlobeData.parsePhone('${country.callingCode}$example');
        expect(parsed, isNotNull, reason: country.alpha2Code);
        expect(parsed!.isValid, isTrue, reason: country.alpha2Code);
      }
    });

    test('example numbers resolve like libphonenumber', () {
      // Countries sharing a calling code are told apart by area codes and
      // numbering patterns. libphonenumber has no number range of their own
      // for these territories, so it also resolves their examples to the
      // main country.
      const sharedRangeExamples = {'MF -> GP', 'EH -> MA'};
      final mismatches = <String>{};
      for (final country in countries) {
        final example = country.phoneExample;
        if (example == null) continue;
        final parsed = GlobeData.parsePhone('${country.callingCode}$example');
        if (parsed?.country != country) {
          mismatches.add(
            '${country.alpha2Code} -> ${parsed?.country.alpha2Code}',
          );
        }
      }
      expect(mismatches, sharedRangeExamples);
    });
  });

  group('currencies', () {
    test('have ISO codes and are used by at least one country', () {
      for (final currency in GlobeData.currencies) {
        expect(currency.code, matches(RegExp(r'^[A-Z]{3}$')));
        expect(currency.name.trim(), isNotEmpty);
        expect(currency.symbol.trim(), isNotEmpty);
        expect(currency.symbol, isNot(currency.code), reason: currency.code);
        expect(currency.nativeSymbol.trim(), isNotEmpty);
        expect(currency.decimalDigits, inInclusiveRange(0, 4));
        expect(currency.countries, isNotEmpty, reason: currency.code);
        expect(
          currency.numCode,
          matches(RegExp(r'^\d{3}$')),
          reason: currency.code,
        );
      }
    });

    test('primary country is the issuer from the ISO code', () {
      expect(GlobeData.currencyByCode('INR')!.primaryCountry?.alpha2Code, 'IN');
      expect(GlobeData.currencyByCode('USD')!.primaryCountry?.alpha2Code, 'US');
      expect(GlobeData.currencyByCode('EUR')!.primaryCountry, isNull);
      expect(GlobeData.currencyByCode('XOF')!.primaryCountry, isNull);
    });

    test('flag codes', () {
      expect(GlobeData.currencyByCode('EUR')!.flagCode, 'eu');
      expect(GlobeData.currencyByCode('INR')!.flagCode, 'in');
      expect(GlobeData.currencyByCode('XOF')!.flagCode, isNotNull);
    });
  });

  group('links', () {
    test('dial codes link back to their countries', () {
      for (final dialCode in GlobeData.dialCodes) {
        expect(dialCode.countries, isNotEmpty);
        for (final country in dialCode.countries) {
          expect(country.dialCodes, contains(dialCode.code));
        }
      }
      final plusOne = GlobeData.dialCodeByCode('+1')!;
      expect(plusOne.country.alpha2Code, 'US');
      expect(
        plusOne.countries.map((country) => country.alpha2Code),
        containsAll(['US', 'CA']),
      );
    });

    test('date formats link back to their countries', () {
      var total = 0;
      for (final format in GlobeData.dateFormats) {
        total += format.countries.length;
        for (final country in format.countries) {
          expect(country.dateFormat, same(format));
        }
      }
      expect(total, GlobeData.countries.length);
      expect(GlobeData.dateFormats.first.pattern, 'dd/MM/yyyy');
    });

    test('collections are unmodifiable', () {
      expect(() => GlobeData.countries.clear(), throwsUnsupportedError);
      expect(() => GlobeData.currencies.clear(), throwsUnsupportedError);
      final india = GlobeData.countryByAlpha2('IN')!;
      expect(india.dialCodes.clear, throwsUnsupportedError);
      expect(india.currencyCodes.clear, throwsUnsupportedError);
      // Linked lists are new copies, so changing them never changes the data.
      india.currencies.clear();
      expect(india.currencies.single.code, 'INR');
    });
  });
}
