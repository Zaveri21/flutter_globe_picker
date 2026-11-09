part of 'globe_models.dart';

/// An international dial code linked to every country that uses it.
///
/// ```dart
/// final plusOne = GlobeData.dialCodeByCode('+1')!;
/// plusOne.countries; // United States, Canada
/// plusOne.country;   // United States
/// ```
final class GlobeDialCode extends GlobeItem {
  /// Creates a dial code entry. `GlobeData.dialCodes` lists every one.
  /// [countries] must not be empty.
  const GlobeDialCode({required this.code, required this.countries});

  /// Dial code with a leading `+`, for example `+91` or `+1876`.
  final String code;

  /// Countries that use this dial code.
  @override
  final List<GlobeCountry> countries;

  /// The code without the leading `+`, for example `91`.
  String get digits => code.substring(1);

  /// The main country for this code (the United States for `+1`).
  GlobeCountry get country => countries.firstWhere(
    (country) => country.isMainCountryForDialCode,
    orElse: () => countries.first,
  );

  @override
  String get id => code;

  @override
  String get displayName => code;

  @override
  GlobeCountry get representativeCountry => country;

  @override
  bool operator ==(Object other) =>
      other is GlobeDialCode && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'GlobeDialCode($code)';
}
