import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_globe_picker/src/format/globe_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDatePattern', () {
    final date = DateTime(2026, 3, 5, 9, 7, 3, 45);

    test('numeric fields', () {
      expect(formatDatePattern(date, 'd/M/yy'), '5/3/26');
      expect(formatDatePattern(date, 'dd/MM/yyyy'), '05/03/2026');
      expect(formatDatePattern(date, 'y'), '2026');
      expect(formatDatePattern(date, 'HH:mm:ss'), '09:07:03');
      expect(formatDatePattern(date, 'H:m:s'), '9:7:3');
      expect(formatDatePattern(date, 'SSS'), '045');
    });

    test('names and 12-hour clock', () {
      expect(formatDatePattern(date, 'EEEE, MMMM d'), 'Thursday, March 5');
      expect(formatDatePattern(date, 'EEE MMM'), 'Thu Mar');
      expect(formatDatePattern(date, 'h:mm a'), '9:07 AM');
      expect(formatDatePattern(DateTime(2026, 1, 1, 0), 'hh a'), '12 AM');
      expect(formatDatePattern(DateTime(2026, 1, 1, 12), 'hh a'), '12 PM');
      expect(formatDatePattern(DateTime(2026, 1, 1, 23), 'h a'), '11 PM');
    });

    test('quoted text', () {
      expect(formatDatePattern(date, "d 'de' MMMM"), '5 de March');
      expect(formatDatePattern(date, "h 'o''clock'"), "9 o'clock");
      expect(formatDatePattern(date, "''"), "'");
      expect(formatDatePattern(date, "'unterminated"), 'unterminated');
    });

    test('custom symbols', () {
      const symbols = GlobeDateSymbols(
        monthNames: [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin', //
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
        ],
        shortMonthNames: [
          'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', //
          'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
        ],
        weekdayNames: [
          'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', //
          'dimanche',
        ],
        shortWeekdayNames: [
          'lun.',
          'mar.',
          'mer.',
          'jeu.',
          'ven.',
          'sam.',
          'dim.',
        ],
      );
      expect(
        formatDatePattern(date, 'EEEE d MMMM yyyy', symbols: symbols),
        'jeudi 5 mars 2026',
      );
    });
  });

  group('GlobeNumberFormat', () {
    test('western grouping', () {
      final format = GlobeNumberFormat(
        decimalSeparator: '.',
        groupSeparator: ',',
        currencyPattern: '¤#,##0.00',
      );
      expect(format.formatNumber(0), '0');
      expect(format.formatNumber(999), '999');
      expect(format.formatNumber(1000), '1,000');
      expect(format.formatNumber(1e21), '1,000,000,000,000,000,000,000');
      expect(format.formatNumber(-1e21), '-1,000,000,000,000,000,000,000');
      expect(
        format.formatNumber(1234567.891, decimalDigits: 2),
        '1,234,567.89',
      );
      expect(format.formatNumber(-1234.5, decimalDigits: 1), '-1,234.5');
      expect(format.formatNumber(-0.001, decimalDigits: 2), '0.00');
      expect(format.symbolBeforeAmount, isTrue);
      expect(format.primaryGroupSize, 3);
      expect(format.secondaryGroupSize, 3);
    });

    test('Indian grouping', () {
      final format = GlobeData.countryByAlpha2('IN')!.numberFormat;
      expect(format.formatNumber(1234567), '12,34,567');
      expect(format.formatNumber(123456789), '12,34,56,789');
      expect(format.primaryGroupSize, 3);
      expect(format.secondaryGroupSize, 2);
    });

    test('symbol after amount and empty symbol', () {
      final format = GlobeData.countryByAlpha2('FR')!.numberFormat;
      expect(format.symbolBeforeAmount, isFalse);
      expect(
        format.formatCurrency(-1234.5, symbol: '€', decimalDigits: 2),
        '-1 234,50 €',
      );
      expect(format.formatCurrency(5, symbol: '', decimalDigits: 2), '5,00');
    });

    test('equality and invalid patterns', () {
      GlobeNumberFormat create() => GlobeNumberFormat(
        decimalSeparator: '.',
        groupSeparator: ',',
        currencyPattern: '¤#,##0.00',
      );
      expect(create(), create());
      expect(create().hashCode, create().hashCode);
      const invalid = GlobeNumberFormat(
        decimalSeparator: '.',
        groupSeparator: ',',
        currencyPattern: '¤',
      );
      expect(() => invalid.formatNumber(1), throwsFormatException);
    });
  });

  group('GlobeCurrency.format', () {
    final euro = GlobeData.currencyByCode('EUR')!;

    test('uses the given country, then the issuer, then neutral', () {
      expect(euro.format(1234.5), '€1,234.50');
      expect(
        euro.format(1234.5, country: GlobeData.countryByAlpha2('DE')),
        '1.234,50 €',
      );
      expect(GlobeData.currencyByCode('INR')!.format(100000), '₹1,00,000.00');
    });

    test('options', () {
      expect(euro.format(10, showSymbol: false), '10.00');
      expect(euro.format(10, decimalDigits: 0), '€10');
      // Kuwait writes three decimals and the symbol after the amount.
      expect(GlobeData.currencyByCode('KWD')!.format(1), '1.000\u00a0د.ك.');
    });
  });

  group('edge values', () {
    const format = GlobeNumberFormat(
      decimalSeparator: '.',
      groupSeparator: ',',
      currencyPattern: '¤#,##0.00',
    );

    test('infinity, NaN, huge integers and decimal digits', () {
      expect(format.formatNumber(double.infinity), '∞');
      expect(format.formatNumber(double.negativeInfinity), '-∞');
      expect(format.formatNumber(double.nan), 'NaN');
      expect(format.formatNumber(9007199254740993), '9,007,199,254,740,993');
      expect(
        format.formatNumber(-9223372036854775807 - 1),
        '-9,223,372,036,854,775,808',
      );
      expect(format.formatNumber(1.5, decimalDigits: 99), startsWith('1.5'));
      expect(format.formatNumber(1.5, decimalDigits: -3), '2');
    });

    test('letter symbols get a space next to the digits', () {
      expect(
        format.formatCurrency(5, symbol: 'RM', decimalDigits: 2),
        'RM 5.00',
      );
      expect(
        format.formatCurrency(5, symbol: r'$', decimalDigits: 2),
        r'$5.00',
      );
      const after = GlobeNumberFormat(
        decimalSeparator: ',',
        groupSeparator: '.',
        currencyPattern: '#,##0.00¤',
      );
      expect(
        after.formatCurrency(5, symbol: 'Kč', decimalDigits: 2),
        '5,00 Kč',
      );
      expect(after.formatCurrency(5, symbol: '€', decimalDigits: 2), '5,00€');
    });
  });

  group('more date fields', () {
    final date = DateTime(2026, 2, 3, 0, 7, 9);

    test('narrow names, era, quarter, day of year, 1-24 and 0-11 hours', () {
      expect(GlobeData.formatDate(date, pattern: 'MMMMM EEEEE'), 'F T');
      expect(GlobeData.formatDate(date, pattern: 'G QQQ Q D'), 'AD Q1 1 34');
      expect(GlobeData.formatDate(date, pattern: 'kk:mm KK'), '24:07 00');
    });

    test('negative years keep their sign before the padding', () {
      expect(
        GlobeData.formatDate(DateTime(-5, 3, 1), pattern: 'yyyy-MM-dd'),
        '-0005-03-01',
      );
    });

    test('an unknown country throws even with a pattern', () {
      expect(
        () => GlobeData.formatDate(date, countryCode: 'ZZ', pattern: 'yyyy'),
        throwsArgumentError,
      );
    });
  });
}
