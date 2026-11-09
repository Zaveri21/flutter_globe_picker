part of 'globe_models.dart';

/// A currency in current use (ISO 4217), linked to the countries using it.
///
/// ```dart
/// final euro = GlobeData.currencyByCode('EUR')!;
/// euro.symbol;                       // €
/// euro.countries.length;             // 30+
/// euro.format(1234.5);               // €1,234.50
/// euro.format(1234.5, country: GlobeData.countryByAlpha2('DE')); // 1.234,50 €
/// ```
final class GlobeCurrency extends GlobeItem {
  /// Creates a currency. The bundled currencies are listed in
  /// `GlobeData.currencies`; create your own only for custom lists.
  const GlobeCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    this._nativeSymbol,
    this.numCode,
    this.decimalDigits = 2,
  });

  /// ISO 4217 code, for example `INR`.
  final String code;

  /// English name, for example `Indian Rupee`.
  final String name;

  /// Short symbol, for example `₹`, `$` or `€`.
  final String symbol;

  final String? _nativeSymbol;

  /// Symbol as written in the issuing country, for example `د.إ.` for AED.
  /// Same as [symbol] when not set.
  String get nativeSymbol => _nativeSymbol ?? symbol;

  /// ISO 4217 numeric code with three digits, for example `356`.
  final String? numCode;

  /// Number of digits after the decimal separator (2 for INR, 0 for JPY).
  final int decimalDigits;

  /// Countries that use this currency today.
  @override
  List<GlobeCountry> get countries =>
      worldIndex.countriesByCurrency[code] ?? const [];

  /// The issuing country, found from the ISO code (INR → India). `null`
  /// for shared currencies such as EUR, XOF or XCD.
  GlobeCountry? get primaryCountry => countries
      .where((country) => code.startsWith(country.alpha2Code))
      .firstOrNull;

  /// Formats [amount], for example `₹1,234.50`.
  ///
  /// Separators, grouping and symbol position follow [country], then
  /// [primaryCountry], then a neutral `¤#,##0.00` layout.
  /// Set [useNativeSymbol] to use [nativeSymbol], [showSymbol] to `false` to
  /// leave the symbol out, and [decimalDigits] to override the precision.
  String format(
    num amount, {
    GlobeCountry? country,
    bool useNativeSymbol = false,
    bool showSymbol = true,
    int? decimalDigits,
  }) {
    final numberFormat =
        (country ?? primaryCountry)?.numberFormat ?? _neutralNumberFormat;
    return numberFormat.formatCurrency(
      amount,
      symbol: showSymbol ? (useNativeSymbol ? nativeSymbol : symbol) : '',
      decimalDigits: decimalDigits ?? this.decimalDigits,
    );
  }

  static const _neutralNumberFormat = GlobeNumberFormat(
    decimalSeparator: '.',
    groupSeparator: ',',
    currencyPattern: '¤#,##0.00',
  );

  @override
  String get id => code;

  @override
  String get displayName => name;

  @override
  String localizedName(Locale? locale) => locale == null
      ? name
      : worldIndex.currencyNames[translationLanguageFor(locale)]?[code] ?? name;

  @override
  GlobeCountry? get representativeCountry =>
      primaryCountry ?? countries.firstOrNull;

  /// The euro shows the EU flag, other shared currencies show the flag of
  /// their first country.
  @override
  String? get flagCode =>
      code == 'EUR' ? 'eu' : representativeCountry?.alpha2Code.toLowerCase();

  /// Creates a currency from a map shaped like a currency in
  /// `assets/globe_data.json`, or the output of [toJson].
  factory GlobeCurrency.fromJson(Map<String, dynamic> json) => GlobeCurrency(
    code: json['code']! as String,
    name: json['name']! as String,
    symbol: json['symbol']! as String,
    nativeSymbol: json['nativeSymbol'] as String?,
    numCode: json['numCode'] as String?,
    decimalDigits: (json['decimalDigits'] as num?)?.toInt() ?? 2,
  );

  /// This currency as a JSON-compatible map with the keys used in
  /// `assets/globe_data.json`. [GlobeCurrency.fromJson] reads it back.
  Map<String, Object?> toJson() => {
    'code': code,
    'name': name,
    'symbol': symbol,
    'nativeSymbol': nativeSymbol,
    'numCode': numCode,
    'decimalDigits': decimalDigits,
  };

  /// Returns a copy with the given fields replaced, for example
  /// `GlobeData.currencyByCode('INR')!.copyWith(name: 'Rupee')`.
  ///
  /// Keep [code] unchanged: links to countries, and equality, use it.
  GlobeCurrency copyWith({
    String? code,
    String? name,
    String? symbol,
    String? nativeSymbol,
    String? numCode,
    int? decimalDigits,
  }) => GlobeCurrency(
    code: code ?? this.code,
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    nativeSymbol: nativeSymbol ?? _nativeSymbol,
    numCode: numCode ?? this.numCode,
    decimalDigits: decimalDigits ?? this.decimalDigits,
  );

  @override
  bool operator ==(Object other) =>
      other is GlobeCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'GlobeCurrency($code, $name)';
}
