import 'package:flutter/foundation.dart';

import 'package:flutter_globe_picker/src/models/globe_models.dart';

/// A phone number split into its country and national number.
///
/// ```dart
/// final phone = GlobeData.parsePhone('+91 98765 43210')!;
/// phone.country.name;    // India
/// phone.nationalNumber;  // 9876543210
/// phone.e164;            // +919876543210
/// phone.isValid;         // true
/// ```
@immutable
class GlobePhoneNumber {
  /// Creates a phone number. [nationalNumber] may contain spaces, dashes or
  /// non-Latin digits; only the digits are kept.
  GlobePhoneNumber({required this.country, required String nationalNumber})
    : nationalNumber = normalizePhoneInput(nationalNumber)
          .replaceAll(_nonDigit, '');

  /// The country the number belongs to.
  final GlobeCountry country;

  /// Digits after the calling code, for example `9876543210`.
  final String nationalNumber;

  /// Calling code, for example `+91` (or `+1` for every NANP country).
  String get callingCode => country.callingCode;

  /// Whether the number matches the country's numbering plan.
  bool get isValid => country.isValidPhoneNumber(nationalNumber);

  /// Whether no digits were entered.
  bool get isEmpty => nationalNumber.isEmpty;

  /// The number in E.164 format, for example `+919876543210`. A leading
  /// trunk prefix (such as the `0` in UK numbers) is removed when the rest
  /// of the number is valid.
  String get e164 =>
      '$callingCode${country.normalizeNationalNumber(nationalNumber) ?? nationalNumber}';

  /// The number with a space after the calling code, for example
  /// `+91 9876543210`.
  String get international =>
      '$callingCode ${country.normalizeNationalNumber(nationalNumber) ?? nationalNumber}';

  /// Returns a copy with the given fields replaced.
  GlobePhoneNumber copyWith({GlobeCountry? country, String? nationalNumber}) =>
      GlobePhoneNumber(
        country: country ?? this.country,
        nationalNumber: nationalNumber ?? this.nationalNumber,
      );

  /// The national number without a trunk prefix when valid, so `07400…`
  /// and `7400…` in the UK are the same number.
  String get _comparable =>
      country.normalizeNationalNumber(nationalNumber) ?? nationalNumber;

  @override
  bool operator ==(Object other) =>
      other is GlobePhoneNumber &&
      other.country == country &&
      other._comparable == _comparable;

  @override
  int get hashCode => Object.hash(country, _comparable);

  @override
  String toString() => e164;
}

final _nonDigit = RegExp(r'\D');
