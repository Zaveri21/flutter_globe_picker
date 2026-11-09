import 'dart:ui' show Locale;

import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('copyWith', () {
    test('country keeps unchanged fields and its links', () {
      final india = GlobeData.countryByAlpha2('IN')!;
      final custom = india.copyWith(name: 'Bharat', aliases: ['India']);
      expect(custom.name, 'Bharat');
      expect(custom.aliases, ['India']);
      expect(custom.alpha3Code, 'IND');
      expect(custom.phonePattern, india.phonePattern);
      expect(custom.currency?.code, 'INR');
      expect(custom, india);
    });

    test('currency keeps unchanged fields and its links', () {
      final rupee = GlobeData.currencyByCode('INR')!;
      final custom = rupee.copyWith(name: 'Rupee', decimalDigits: 0);
      expect(custom.name, 'Rupee');
      expect(custom.decimalDigits, 0);
      expect(custom.symbol, rupee.symbol);
      expect(custom.nativeSymbol, rupee.nativeSymbol);
      expect(custom.countries, contains(GlobeData.countryByAlpha2('IN')));
      expect(custom.format(1234.5), '₹1,235');
    });
  });

  group('lookups', () {
    test('by alpha-2, alpha-3 and numeric code, case-insensitive', () {
      expect(GlobeData.countryByAlpha2('in')?.name, 'India');
      expect(GlobeData.countryByAlpha2(' IN ')?.name, 'India');
      expect(GlobeData.countryByAlpha3('ind')?.name, 'India');
      expect(GlobeData.countryByNumCode(356)?.name, 'India');
      expect(GlobeData.countryByNumCode(4)?.name, 'Afghanistan');
      expect(GlobeData.countryByNumCode(-1), isNull);
      expect(GlobeData.countryByAlpha2('ZZ'), isNull);
    });

    test('by any code', () {
      expect(GlobeData.countryByCode('IN')?.alpha2Code, 'IN');
      expect(GlobeData.countryByCode('IND')?.alpha2Code, 'IN');
      expect(GlobeData.countryByCode('356')?.alpha2Code, 'IN');
      expect(GlobeData.countryByCode('004')?.alpha2Code, 'AF');
      expect(GlobeData.countryByCode(''), isNull);
    });

    test('by name and alias', () {
      expect(GlobeData.countryByName('india')?.alpha2Code, 'IN');
      expect(GlobeData.countryByName('Ivory Coast')?.alpha2Code, 'CI');
      expect(GlobeData.countryByName('cote divoire'), isNull);
      expect(GlobeData.countryByName("Côte d'Ivoire")?.alpha2Code, 'CI');
      expect(GlobeData.countryByName(''), isNull);
    });

    test('by region', () {
      final europe = GlobeData.countriesByRegion(GlobeRegion.europe);
      expect(
        europe.map((country) => country.alpha2Code),
        containsAll(['DE', 'FR', 'GB']),
      );
      expect(
        europe.every((country) => country.region == GlobeRegion.europe),
        isTrue,
      );
    });

    test('by dial code', () {
      expect(
        GlobeData.countriesByDialCode('91')
            .map((country) => country.alpha2Code),
        ['IN'],
      );
      expect(
        GlobeData.countriesByDialCode('+1876')
            .map((country) => country.alpha2Code),
        ['JM'],
      );
      final northAmerica = GlobeData.countriesByDialCode('+1');
      expect(northAmerica.length, greaterThan(20));
      expect(
        northAmerica.map((country) => country.alpha2Code),
        containsAll(['US', 'CA', 'JM']),
      );
      expect(GlobeData.countriesByDialCode('abc'), isEmpty);
      expect(GlobeData.dialCodeByCode('44')?.code, '+44');
      expect(GlobeData.dialCodeByCode(''), isNull);
    });

    test('currencies by code and symbol', () {
      expect(GlobeData.currencyByCode('inr')?.symbol, '₹');
      expect(GlobeData.currencyByCode('XAU'), isNull);
      expect(
        GlobeData.currenciesBySymbol(r'$').map((currency) => currency.code),
        containsAll(['USD', 'AUD', 'CAD']),
      );
      expect(
        GlobeData.currenciesBySymbol('د.إ.').map((currency) => currency.code),
        ['AED'],
      );
    });

    test('date format by pattern', () {
      final format = GlobeData.dateFormatByPattern('MM/dd/yyyy')!;
      expect(
        format.countries.map((country) => country.alpha2Code),
        contains('US'),
      );
      expect(GlobeData.dateFormatByPattern('nope'), isNull);
    });
  });

  group('locale', () {
    test('uses the country code when present', () {
      expect(
        GlobeData.countryFromLocale(const Locale('en', 'IN'))?.alpha2Code,
        'IN',
      );
      expect(
        GlobeData.countryFromLocale(const Locale('en', 'GB'))?.alpha2Code,
        'GB',
      );
    });

    test('falls back to the language', () {
      expect(GlobeData.countryFromLocale(const Locale('ja'))?.alpha2Code, 'JP');
      expect(GlobeData.countryFromLocale(const Locale('en'))?.alpha2Code, 'US');
      expect(GlobeData.countryFromLocale(const Locale('de'))?.alpha2Code, 'DE');
      expect(
        GlobeData.countryFromLocale(const Locale('en', 'ZZ'))?.alpha2Code,
        'US',
      );
      expect(GlobeData.countryFromLocale(const Locale('xx')), isNull);
    });

    test('currency from locale', () {
      expect(GlobeData.currencyFromLocale(const Locale('hi'))?.code, 'INR');
    });
  });

  group('search', () {
    test('countries by name, alias, code and dial code', () {
      expect(GlobeData.searchCountries('india').first.alpha2Code, 'IN');
      expect(GlobeData.searchCountries('IND').first.alpha2Code, 'IN');
      expect(GlobeData.searchCountries('+91').first.alpha2Code, 'IN');
      expect(GlobeData.searchCountries('91').first.alpha2Code, 'IN');
      expect(GlobeData.searchCountries('ivory').first.alpha2Code, 'CI');
      expect(GlobeData.searchCountries('cote d iv').first.alpha2Code, 'CI');
      expect(GlobeData.searchCountries('aland').first.alpha2Code, 'AX');
      expect(GlobeData.searchCountries('zzzz'), isEmpty);
      expect(GlobeData.searchCountries('').length, GlobeData.countries.length);
    });

    test('currencies by code, name, symbol and country', () {
      expect(GlobeData.searchCurrencies('eur').first.code, 'EUR');
      expect(GlobeData.searchCurrencies('rupee').first.code, 'INR');
      expect(GlobeData.searchCurrencies('₹').first.code, 'INR');
      expect(GlobeData.searchCurrencies('germany').first.code, 'EUR');
    });

    test('dial codes and combined search', () {
      expect(GlobeData.searchDialCodes('44').first.code, '+44');
      final results = GlobeData.search('euro');
      expect(results.whereType<GlobeCurrency>().first.code, 'EUR');
    });
  });

  group('phone numbers', () {
    test('parse international numbers', () {
      final india = GlobeData.parsePhone('+91 98765 43210')!;
      expect(india.country.alpha2Code, 'IN');
      expect(india.nationalNumber, '9876543210');
      expect(india.e164, '+919876543210');
      expect(india.international, '+91 9876543210');
      expect(india.isValid, isTrue);
      expect(india.toString(), '+919876543210');

      expect(
        GlobeData.parsePhone('0044 7400 123456')!.country.alpha2Code,
        'GB',
      );
      expect(
        GlobeData.parsePhone('+1 (416) 555-1234')!.country.alpha2Code,
        'CA',
      );
      expect(GlobeData.parsePhone('+1 212 555 1234')!.country.alpha2Code, 'US');
      expect(GlobeData.parsePhone('+1 876 555 1234')!.country.alpha2Code, 'JM');
      expect(GlobeData.parsePhone('+7 771 000 9998')!.country.alpha2Code, 'KZ');
      expect(GlobeData.parsePhone('+7 912 345 6789')!.country.alpha2Code, 'RU');
      expect(GlobeData.parsePhone('+61 412 345 678')!.country.alpha2Code, 'AU');
      expect(GlobeData.parsePhone('+672 381234')!.country.alpha2Code, 'NF');
    });

    test('parse national numbers with a default country', () {
      final india = GlobeData.countryByAlpha2('IN')!;
      final phone = GlobeData.parsePhone('98765 43210', defaultCountry: india)!;
      expect(phone.country, india);
      expect(phone.isValid, isTrue);
      expect(GlobeData.parsePhone('98765 43210'), isNull);
    });

    test('national prefix is removed in E.164', () {
      final uk = GlobeData.countryByAlpha2('GB')!;
      final phone = GlobeData.parsePhone('07400 123456', defaultCountry: uk)!;
      expect(phone.isValid, isTrue);
      expect(phone.e164, '+447400123456');
    });

    test('invalid input', () {
      expect(GlobeData.parsePhone(''), isNull);
      expect(GlobeData.parsePhone('+'), isNull);
      expect(GlobeData.parsePhone('+999'), isNull);
      final tooShort = GlobeData.parsePhone('+91 123')!;
      expect(tooShort.isValid, isFalse);
      expect(
        GlobeData.countryByAlpha2('IN')!.isValidPhoneNumber('12345'),
        isFalse,
      );
    });

    test('equality and copyWith', () {
      final india = GlobeData.countryByAlpha2('IN')!;
      final first = GlobePhoneNumber(
        country: india,
        nationalNumber: '98765-43210',
      );
      final second = GlobePhoneNumber(
        country: india,
        nationalNumber: '9876543210',
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.copyWith(nationalNumber: '1').nationalNumber, '1');
      expect(
        GlobePhoneNumber(country: india, nationalNumber: '').isEmpty,
        isTrue,
      );
    });
  });

  group('formatting', () {
    final date = DateTime(2026, 11, 8, 14, 5, 9);

    test('dates by country and pattern', () {
      expect(GlobeData.formatDate(date, countryCode: 'US'), '11/08/2026');
      expect(GlobeData.formatDate(date, countryCode: 'IN'), '08/11/2026');
      expect(GlobeData.formatDate(date, countryCode: 'DE'), '08.11.2026');
      expect(GlobeData.formatDate(date, countryCode: 'JP'), '2026/11/08');
      expect(GlobeData.formatDate(date), '2026-11-08');
      expect(
        GlobeData.formatDate(date, pattern: 'EEE, d MMM yyyy'),
        'Sun, 8 Nov 2026',
      );
      expect(
        () => GlobeData.formatDate(date, countryCode: 'ZZ'),
        throwsArgumentError,
      );
    });

    test('date and time', () {
      expect(
        GlobeData.formatDateTime(date, countryCode: 'US', use24Hour: false),
        '11/08/2026 02:05 PM',
      );
      expect(
        GlobeData.formatDateTime(date, countryCode: 'IN', showSeconds: true),
        '08/11/2026 14:05:09',
      );
    });

    test('currency', () {
      expect(
        GlobeData.formatCurrency(1234567.5, currencyCode: 'INR'),
        '₹12,34,567.50',
      );
      expect(
        GlobeData.formatCurrency(1234.5, currencyCode: 'USD'),
        r'$1,234.50',
      );
      expect(GlobeData.formatCurrency(1234.5, currencyCode: 'JPY'), '¥1,235');
      expect(
        GlobeData.formatCurrency(
          1234.5,
          currencyCode: 'EUR',
          countryCode: 'DE',
        ),
        '1.234,50 €',
      );
      expect(
        GlobeData.formatCurrency(
          1234.5,
          currencyCode: 'AED',
          useNativeSymbol: true,
        ),
        contains('د.إ.'),
      );
      expect(
        () => GlobeData.formatCurrency(1, currencyCode: 'XXX'),
        throwsArgumentError,
      );
      expect(
        () =>
            GlobeData.formatCurrency(1, currencyCode: 'USD', countryCode: 'ZZ'),
        throwsArgumentError,
      );
    });
  });
}
