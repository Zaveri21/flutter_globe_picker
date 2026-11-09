import 'dart:ui' show Locale;

import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GlobeCountry country(String code) => GlobeData.countryByAlpha2(code)!;

  group('parsePhone', () {
    test('valid numbers of every type, not only mobile and fixed line', () {
      final tollFree = GlobeData.parsePhone(
        '1800 123 456',
        defaultCountry: country('AU'),
      )!;
      expect(tollFree.isValid, isTrue);
      final dutch = GlobeData.parsePhone(
        '0800 1234',
        defaultCountry: country('NL'),
      )!;
      expect(dutch.e164, '+318001234');
    });

    test('invalid numbers that only fit the general pattern', () {
      // Fits the UAE general pattern but no number type.
      expect(GlobeData.parsePhone('+97190023456')?.isValid, isFalse);
    });

    test('pasted text: direction marks, full-width plus, other digits', () {
      for (final input in [
        '\u202a+91 98765 43210\u202c',
        '\u200e+91 98765 43210',
        '＋91 98765 43210',
        '+٩١٩٨٧٦٥٤٣٢١٠',
        '+९१९८७६५४३२१०',
      ]) {
        final phone = GlobeData.parsePhone(input);
        expect(phone?.e164, '+919876543210', reason: input);
        expect(phone?.isValid, isTrue, reason: input);
      }
    });

    test('extensions are dropped', () {
      for (final input in [
        '+44 7400 123456 ext. 123',
        '+44 7400 123456 x123',
        '+44 7400 123456 #123',
        '+44 7400 123456;ext=123',
      ]) {
        expect(
          GlobeData.parsePhone(input)?.e164,
          '+447400123456',
          reason: input,
        );
      }
    });

    test('international dialling prefixes of the default country', () {
      expect(
        GlobeData.parsePhone(
          '011 44 7400 123456',
          defaultCountry: country('US'),
        )?.e164,
        '+447400123456',
      );
      expect(
        GlobeData.parsePhone(
          '0011 44 7400 123456',
          defaultCountry: country('AU'),
        )?.e164,
        '+447400123456',
      );
      expect(GlobeData.parsePhone('0044 7400 123456')?.e164, '+447400123456');
      // Calling codes never start with 0: an Indian toll-free number.
      final indian = GlobeData.parsePhone(
        '000800 1234567',
        defaultCountry: country('IN'),
      );
      expect(indian?.country.alpha2Code, 'IN');
    });

    test('national numbers go to the country of the calling code owning '
        'them', () {
      expect(
        GlobeData.parsePhone(
          '07400 123456',
          defaultCountry: country('JE'),
        )?.country.alpha2Code,
        'GB',
      );
      expect(
        GlobeData.parsePhone(
          '(800) 212-3456',
          defaultCountry: country('CA'),
        )?.country.alpha2Code,
        'US',
      );
      // An incomplete number keeps the default country.
      expect(
        GlobeData.parsePhone(
          '7509',
          defaultCountry: country('JE'),
        )?.country.alpha2Code,
        'JE',
      );
    });

    test('a trunk prefix after the calling code', () {
      final manx = GlobeData.parsePhone('+44 07624 123456')!;
      expect(manx.country.alpha2Code, 'IM');
      expect(manx.e164, '+447624123456');
    });

    test('places without their own numbering use the main country', () {
      expect(
        GlobeData.parsePhone('1234', defaultCountry: country('BV'))?.isValid,
        isFalse,
      );
      expect(
        GlobeData.parsePhone(
          '412 34 567',
          defaultCountry: country('BV'),
        )?.isValid,
        isTrue,
      );
    });
  });

  test('the same number with and without trunk prefix is equal', () {
    final withPrefix = GlobePhoneNumber(
      country: country('GB'),
      nationalNumber: '07400 123456',
    );
    final withoutPrefix = GlobePhoneNumber(
      country: country('GB'),
      nationalNumber: '7400123456',
    );
    expect(withPrefix, withoutPrefix);
    expect(withPrefix.hashCode, withoutPrefix.hashCode);
  });

  test('a dial code search lists the main country first', () {
    expect(GlobeData.searchCountries('+44').first.alpha2Code, 'GB');
    expect(GlobeData.searchCountries('+1').first.alpha2Code, 'US');
    expect(GlobeData.searchCountries('+7').first.alpha2Code, 'RU');
    expect(GlobeData.searchCountries('+47').first.alpha2Code, 'NO');
  });

  test('filters take alpha-3 and numeric codes, and bracketed dial codes', () {
    const filter = GlobeFilter(countries: ['IND', '276', 'fr']);
    expect([
      for (final item in filter.apply(GlobeData.countries)) item.alpha2Code,
    ], unorderedEquals(['IN', 'DE', 'FR']));
    const jamaica = GlobeFilter(dialCodes: ['+1 (876)']);
    expect(
      [for (final item in jamaica.apply(GlobeData.dialCodes)) item.code],
      ['+1876'],
    );
  });

  test('locales with UK or a region number', () {
    expect(
      GlobeData.countryFromLocale(const Locale('en', 'UK'))?.alpha2Code,
      'GB',
    );
    expect(GlobeData.countryFromLocale(const Locale('es', '419')), isNull);
  });
}
