import 'package:flutter/foundation.dart';

/// How numbers and money are written in a country, based on Unicode CLDR.
///
/// ```dart
/// final india = GlobeData.countryByAlpha2('IN')!;
/// india.numberFormat.formatNumber(1234567.5, decimalDigits: 2); // 12,34,567.50
/// ```
@immutable
class GlobeNumberFormat {
  /// Creates a number format from CLDR symbols and a currency pattern such
  /// as `¤#,##,##0.00`, where `¤` marks the currency symbol.
  const GlobeNumberFormat({
    required this.decimalSeparator,
    required this.groupSeparator,
    required this.currencyPattern,
  });

  static final _numberPartPattern = RegExp(r'[#0][#0,.]*');

  /// Decimal separator, for example `.` or `,`.
  final String decimalSeparator;

  /// Thousands separator, for example `,`, `.` or a narrow space.
  final String groupSeparator;

  /// CLDR currency pattern, where `¤` marks the currency symbol.
  final String currencyPattern;

  /// Whether the currency symbol is written before the amount (`$10`) or
  /// after it (`10 €`).
  bool get symbolBeforeAmount => _layout.prefix.contains('¤');

  /// Size of the group closest to the decimal separator (3 in most locales).
  int get primaryGroupSize => _layout.primaryGroupSize;

  /// Size of the other groups (2 in India, otherwise usually 3).
  int get secondaryGroupSize => _layout.secondaryGroupSize;

  /// Formats a plain number with this country's separators and grouping.
  ///
  /// Throws a [FormatException] when [currencyPattern] has no number part.
  String formatNumber(num value, {int decimalDigits = 0}) {
    final digits = _formatDigits(value, decimalDigits, _layout);
    return _isNegative(value, digits) ? '-$digits' : digits;
  }

  /// Formats [amount] with a currency [symbol] placed as this country does.
  ///
  /// Throws a [FormatException] when [currencyPattern] has no number part.
  String formatCurrency(
    num amount, {
    required String symbol,
    required int decimalDigits,
  }) {
    final layout = _layout;
    final digits = _formatDigits(amount, decimalDigits, layout);
    final prefix = layout.prefix.replaceAll('¤', symbol);
    final suffix = layout.suffix.replaceAll('¤', symbol);
    // CLDR currency spacing: a symbol ending (or starting) with a letter,
    // such as `RM` or `F CFA`, gets a no-break space next to the digits.
    final spaceBefore =
        symbol.isNotEmpty &&
            layout.prefix.endsWith('¤') &&
            !_symbolOrSpace.hasMatch(symbol.substring(symbol.length - 1))
        ? '\u00a0'
        : '';
    final spaceAfter =
        symbol.isNotEmpty &&
            layout.suffix.startsWith('¤') &&
            !_symbolOrSpace.hasMatch(symbol.substring(0, 1))
        ? '\u00a0'
        : '';
    final formatted = '$prefix$spaceBefore$digits$spaceAfter$suffix';
    final cleaned = symbol.isEmpty ? formatted.trim() : formatted;
    return _isNegative(amount, digits) ? '-$cleaned' : cleaned;
  }

  /// A currency or other symbol, or a space: no extra space is needed next
  /// to it.
  static final _symbolOrSpace = RegExp(r'[\p{S}\p{Z}\s]', unicode: true);

  static bool _isNegative(num value, String digits) =>
      value < 0 && (value.isInfinite || _hasNonZeroDigit(digits));

  /// Text before and after the number and the grouping sizes, read from
  /// [currencyPattern].
  _PatternLayout get _layout {
    final match = _numberPartPattern.firstMatch(currencyPattern);
    if (match == null) {
      throw FormatException('Invalid currency pattern', currencyPattern);
    }
    final integerPart = match.group(0)!.split('.').first;
    final groups = integerPart.split(',');
    final primaryGroupSize = groups.length > 1 ? groups.last.length : 0;
    return _PatternLayout(
      prefix: currencyPattern.substring(0, match.start),
      suffix: currencyPattern.substring(match.end),
      primaryGroupSize: primaryGroupSize,
      secondaryGroupSize: groups.length > 2
          ? groups[groups.length - 2].length
          : primaryGroupSize,
    );
  }

  /// The digits of [value] without its sign, grouped and with
  /// [decimalDigits] decimals (clamped to 0-20).
  String _formatDigits(num value, int decimalDigits, _PatternLayout layout) {
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return '∞';
    final decimals = decimalDigits.clamp(0, 20);
    final zeros = decimals > 0 ? '.${'0' * decimals}' : '';
    // Integers are written exactly, even beyond 2^53. toStringAsFixed
    // switches to exponent notation from 1e21 on, and doubles that large
    // have no fraction left, so write their integer digits.
    final fixed = value is int
        ? '${BigInt.from(value).abs()}$zeros'
        : value.abs() >= 1e21
        ? '${BigInt.from(value).abs()}$zeros'
        : value.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final grouped = _groupIntegerDigits(parts.first, layout);
    return parts.length > 1 ? '$grouped$decimalSeparator${parts[1]}' : grouped;
  }

  String _groupIntegerDigits(String digits, _PatternLayout layout) {
    final primary = layout.primaryGroupSize;
    final secondary = layout.secondaryGroupSize;
    if (primary <= 0 || digits.length <= primary) return digits;
    final groups = <String>[digits.substring(digits.length - primary)];
    var remaining = digits.substring(0, digits.length - primary);
    while (remaining.length > secondary) {
      groups.insert(0, remaining.substring(remaining.length - secondary));
      remaining = remaining.substring(0, remaining.length - secondary);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);
    return groups.join(groupSeparator);
  }

  static bool _hasNonZeroDigit(String text) => _nonZeroDigit.hasMatch(text);

  static final _nonZeroDigit = RegExp('[1-9]');

  @override
  bool operator ==(Object other) =>
      other is GlobeNumberFormat &&
      other.decimalSeparator == decimalSeparator &&
      other.groupSeparator == groupSeparator &&
      other.currencyPattern == currencyPattern;

  @override
  int get hashCode =>
      Object.hash(decimalSeparator, groupSeparator, currencyPattern);
}

/// Parsed parts of a CLDR currency pattern.
class _PatternLayout {
  const _PatternLayout({
    required this.prefix,
    required this.suffix,
    required this.primaryGroupSize,
    required this.secondaryGroupSize,
  });

  final String prefix;
  final String suffix;
  final int primaryGroupSize;
  final int secondaryGroupSize;
}
