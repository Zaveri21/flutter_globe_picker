part of 'globe_models.dart';

/// A numeric date format, linked to the countries that use it.
///
/// ```dart
/// final format = GlobeData.countryByAlpha2('US')!.dateFormat;
/// format.pattern;                       // MM/dd/yyyy
/// format.format(DateTime(2026, 11, 8)); // 11/08/2026
/// ```
final class GlobeDateFormat extends GlobeItem {
  /// Creates a date format entry. `GlobeData.dateFormats` lists every one.
  const GlobeDateFormat({required this.pattern, required this.countries});

  /// Pattern such as `dd/MM/yyyy`, `MM/dd/yyyy` or `yyyy-MM-dd`.
  final String pattern;

  /// Countries that usually write dates this way.
  @override
  final List<GlobeCountry> countries;

  /// Formats [dateTime] with [pattern].
  String format(
    DateTime dateTime, {
    GlobeDateSymbols symbols = GlobeDateSymbols.english,
  }) => formatDatePattern(dateTime, pattern, symbols: symbols);

  @override
  String get id => pattern;

  @override
  String get displayName => pattern;

  /// Date formats are shared by many countries, so they have no flag.
  @override
  GlobeCountry? get representativeCountry => null;

  @override
  bool operator ==(Object other) =>
      other is GlobeDateFormat && other.pattern == pattern;

  @override
  int get hashCode => pattern.hashCode;

  @override
  String toString() => 'GlobeDateFormat($pattern)';
}
