part of 'globe_models.dart';

/// Shape of a bundled SVG flag.
enum GlobeFlagAspect {
  /// 4:3 rectangle.
  rectangle('4x3'),

  /// 1:1 square, also used for circular flags.
  square('1x1');

  const GlobeFlagAspect(this.folder);

  /// Asset folder name.
  final String folder;
}

/// A country or territory from ISO 3166-1 (plus Kosovo), linked to its
/// currencies, dial codes and date format.
///
/// ```dart
/// final india = GlobeData.countryByAlpha2('IN')!;
/// india.name;               // India
/// india.dialCode;           // +91
/// india.currency?.code;     // INR
/// india.dateFormat.pattern; // dd/MM/yyyy
/// ```
final class GlobeCountry extends GlobeItem {
  /// Creates a country. The bundled countries are listed in
  /// `GlobeData.countries`; create your own only for custom lists.
  const GlobeCountry({
    required this.name,
    required this.alpha2Code,
    required this.alpha3Code,
    required this.region,
    required this.subregion,
    required this.dialCodes,
    required this.currencyCodes,
    required this.dateFormatPattern,
    this.aliases = const [],
    this.numCode,
    this.capital,
    this.languages = const [],
    this.timezones = const [],
    this.tld,
    this.decimalSeparator = '.',
    this.groupSeparator = ',',
    this.currencyPattern = '¤#,##0.00',
    this.phoneLengths = const [],
    this.phoneExample,
    this.nationalPrefix,
    this.phoneInternationalPrefix,
    this.phonePattern,
    this.phoneLeadingDigits,
    this.phoneTypesPattern,
    this.isMainCountryForDialCode = false,
    this.isEUMember = false,
    this.isEurozone = false,
    this.isUNMember = false,
  });

  /// English name, for example `India`.
  final String name;

  /// Other English names used for search, for example `Ivory Coast`.
  final List<String> aliases;

  /// ISO 3166-1 alpha-2 code, for example `IN`.
  final String alpha2Code;

  /// ISO 3166-1 alpha-3 code, for example `IND`.
  final String alpha3Code;

  /// ISO 3166-1 numeric code with three digits, for example `356`.
  /// `null` for Kosovo, which has no ISO numeric code.
  final String? numCode;

  /// Capital city in English, if known.
  final String? capital;

  /// Continent level region.
  final GlobeRegion region;

  /// UN M.49 subregion in English, for example `Southern Asia`.
  final String subregion;

  /// Every dial code of this country (the Dominican Republic has three).
  /// Must not be empty.
  /// Countries in the North American Numbering Plan include their area code,
  /// for example `+1876` (Jamaica).
  final List<String> dialCodes;

  /// ISO 4217 codes of the currencies in use, main currency first.
  final List<String> currencyCodes;

  /// Usual numeric date pattern, for example `dd/MM/yyyy`.
  final String dateFormatPattern;

  /// Official languages as BCP 47 codes, most spoken first.
  final List<String> languages;

  /// IANA time zones, for example `Asia/Kolkata`.
  final List<String> timezones;

  /// Country code top-level domain, for example `.in`. `null` for Kosovo.
  final String? tld;

  /// Decimal separator used here, for example `.` or `,`.
  final String decimalSeparator;

  /// Thousands separator used here, for example `,`, `.` or a narrow space.
  final String groupSeparator;

  /// CLDR currency pattern used here, for example `¤#,##,##0.00`.
  final String currencyPattern;

  /// Possible lengths of a national phone number (after [callingCode]).
  final List<int> phoneLengths;

  /// Example mobile number in national format without spaces.
  final String? phoneExample;

  /// Trunk prefix dialled before national numbers, for example `0`.
  final String? nationalPrefix;

  /// libphonenumber pattern of the prefix dialled to call abroad, for
  /// example `00`, or `011` in the United States.
  final String? phoneInternationalPrefix;

  /// libphonenumber pattern a valid national number matches.
  final String? phonePattern;

  /// libphonenumber leading digits that identify this country's numbers
  /// when it shares a calling code (for example Kazakhstan inside `+7`).
  final String? phoneLeadingDigits;

  /// libphonenumber patterns of every number type (mobile, fixed line, toll
  /// free...) combined. A valid number matches one of them; they also tell
  /// apart countries sharing a calling code (Canada inside `+1`).
  final String? phoneTypesPattern;

  /// Whether this is the main country of its calling code: the only country
  /// using it, or the main one when it is shared (the United States for `+1`).
  final bool isMainCountryForDialCode;

  /// Whether this country is a member of the European Union.
  final bool isEUMember;

  /// Whether this country uses the euro as an EU member.
  final bool isEurozone;

  /// Whether this country is a member of the United Nations.
  final bool isUNMember;

  /// Main dial code, for example `+91`.
  String get dialCode => dialCodes.first;

  /// The country calling code without area codes, for example `+1` for
  /// Jamaica and `+91` for India. Phone numbers are entered after it.
  String get callingCode => dialCode.startsWith('+1') ? '+1' : dialCode;

  /// The dial code entry linked to the other countries that share it.
  GlobeDialCode get dialCodeInfo => dialCodeEntries.first;

  /// Dial code entries for every code in [dialCodes].
  List<GlobeDialCode> get dialCodeEntries => [
    for (final code in dialCodes)
      worldIndex.dialCodesByCode[code] ??
          GlobeDialCode(code: code, countries: [this]),
  ];

  /// Main currency, or `null` for Antarctica.
  GlobeCurrency? get currency => currencies.firstOrNull;

  /// Every currency in current use (Panama uses PAB and USD).
  List<GlobeCurrency> get currencies => [
    for (final code in currencyCodes) ?worldIndex.currenciesByCode[code],
  ];

  /// Usual numeric date format, linked to the other countries using it.
  GlobeDateFormat get dateFormat =>
      worldIndex.dateFormatsByPattern[dateFormatPattern] ??
      GlobeDateFormat(pattern: dateFormatPattern, countries: [this]);

  /// How numbers and money are written here.
  GlobeNumberFormat get numberFormat => GlobeNumberFormat(
    decimalSeparator: decimalSeparator,
    groupSeparator: groupSeparator,
    currencyPattern: currencyPattern,
  );

  /// Flag emoji built from the alpha-2 code, for example 🇮🇳.
  String get flagEmoji => flagEmojiFor(alpha2Code);

  /// Asset path of the SVG flag inside this package. Use it with
  /// `package: 'flutter_globe_picker'`, or use the `GlobeFlag` widget.
  String flagAssetPath([GlobeFlagAspect aspect = GlobeFlagAspect.rectangle]) =>
      'assets/flags/${aspect.folder}/${alpha2Code.toLowerCase()}.svg';

  /// Whether [nationalNumber] (digits after [callingCode]) is a valid phone
  /// number here. Spaces, dashes and brackets are ignored, and a leading
  /// [nationalPrefix] is accepted.
  bool isValidPhoneNumber(String nationalNumber) =>
      normalizeNationalNumber(nationalNumber) != null;

  /// Returns [nationalNumber] as plain digits without the trunk prefix, or
  /// `null` when it is not valid for this country.
  String? normalizeNationalNumber(String nationalNumber) {
    final digits = normalizePhoneInput(nationalNumber)
        .replaceAll(_nonDigit, '');
    if (digits.isEmpty) return null;
    if (_matchesPhoneRules(digits)) return digits;
    final prefix = nationalPrefix;
    if (prefix != null &&
        prefix.isNotEmpty &&
        digits.startsWith(prefix) &&
        _matchesPhoneRules(digits.substring(prefix.length))) {
      return digits.substring(prefix.length);
    }
    return null;
  }

  bool _matchesPhoneRules(String digits) {
    final typesPattern = phoneTypesPattern;
    final pattern = phonePattern;
    if (pattern == null) {
      // No numbering plan of its own (Bouvet Island, US Minor Outlying
      // Islands): use the main country of the calling code (Norway, US).
      final main = worldIndex.mainCountryForCallingCode(callingCode);
      if (main != null && main != this) return main._matchesPhoneRules(digits);
      return digits.length >= 4 && digits.length <= 15;
    }
    final lengthAllowed =
        phoneLengths.isEmpty || phoneLengths.contains(digits.length);
    // Like libphonenumber: the general pattern, then a real number type
    // (mobile, fixed line, toll free...).
    return lengthAllowed &&
        worldIndex.fullMatchPattern(pattern).hasMatch(digits) &&
        (typesPattern == null ||
            worldIndex.fullMatchPattern(typesPattern).hasMatch(digits));
  }

  /// Whether a national number belongs to this country rather than another
  /// one sharing its calling code. Follows libphonenumber: NANP area codes,
  /// then leading digits, then the country's number type patterns.
  bool _ownsNationalNumber(String digits) {
    if (_ownsDigits(digits)) return true;
    // A trunk prefix typed after the calling code: `+44 07624 …`.
    final prefix = nationalPrefix;
    return prefix != null &&
        prefix.isNotEmpty &&
        digits.length > prefix.length &&
        digits.startsWith(prefix) &&
        _ownsDigits(digits.substring(prefix.length));
  }

  bool _ownsDigits(String digits) {
    if (dialCode.startsWith('+1') && dialCode != '+1') {
      return dialCodes.any((code) => digits.startsWith(code.substring(2)));
    }
    final leadingDigits = phoneLeadingDigits;
    if (leadingDigits != null) {
      return worldIndex.prefixPattern(leadingDigits).hasMatch(digits);
    }
    final ownership = phoneTypesPattern;
    return ownership != null &&
        worldIndex.fullMatchPattern(ownership).hasMatch(digits);
  }

  @override
  String get id => alpha2Code;

  @override
  String get displayName => name;

  @override
  String localizedName(Locale? locale) => locale == null
      ? name
      : worldIndex.countryNames[translationLanguageFor(locale)]?[alpha2Code] ??
            name;

  @override
  List<GlobeCountry> get countries => [this];

  @override
  GlobeCountry get representativeCountry => this;

  /// Creates a country from a map shaped like a country in
  /// `assets/globe_data.json`, or the output of [toJson]. Missing optional
  /// fields get their defaults; other keys, such as `names`, are ignored.
  factory GlobeCountry.fromJson(Map<String, dynamic> json) => GlobeCountry(
    name: json['name']! as String,
    aliases: List.unmodifiable(
      (json['aliases'] as List? ?? const []).cast<String>(),
    ),
    alpha2Code: json['alpha2Code']! as String,
    alpha3Code: json['alpha3Code']! as String,
    numCode: json['numCode'] as String?,
    capital: json['capital'] as String?,
    region: GlobeRegion.values.byName(json['region']! as String),
    subregion: json['subregion']! as String,
    dialCodes: List.unmodifiable((json['dialCodes']! as List).cast<String>()),
    currencyCodes: List.unmodifiable(
      (json['currencyCodes']! as List).cast<String>(),
    ),
    dateFormatPattern: json['dateFormat']! as String,
    languages: List.unmodifiable(
      (json['languages'] as List? ?? const []).cast<String>(),
    ),
    timezones: List.unmodifiable(
      (json['timezones'] as List? ?? const []).cast<String>(),
    ),
    tld: json['tld'] as String?,
    decimalSeparator: json['decimalSeparator'] as String? ?? '.',
    groupSeparator: json['groupSeparator'] as String? ?? ',',
    currencyPattern: json['currencyPattern'] as String? ?? '¤#,##0.00',
    phoneLengths: List.unmodifiable([
      for (final length in json['phoneLengths'] as List? ?? const [])
        (length as num).toInt(),
    ]),
    phoneExample: json['phoneExample'] as String?,
    nationalPrefix: json['nationalPrefix'] as String?,
    phoneInternationalPrefix: json['phoneInternationalPrefix'] as String?,
    phonePattern: json['phonePattern'] as String?,
    phoneLeadingDigits: json['phoneLeadingDigits'] as String?,
    phoneTypesPattern: json['phoneTypesPattern'] as String?,
    isMainCountryForDialCode:
        json['isMainCountryForDialCode'] as bool? ?? false,
    isEUMember: json['isEUMember'] as bool? ?? false,
    isEurozone: json['isEurozone'] as bool? ?? false,
    isUNMember: json['isUNMember'] as bool? ?? false,
  );

  /// This country as a JSON-compatible map with the keys used in
  /// `assets/globe_data.json`. [GlobeCountry.fromJson] reads it back.
  Map<String, Object?> toJson() => {
    'name': name,
    'aliases': aliases,
    'alpha2Code': alpha2Code,
    'alpha3Code': alpha3Code,
    'numCode': numCode,
    'capital': capital,
    'region': region.name,
    'subregion': subregion,
    'dialCodes': dialCodes,
    'currencyCodes': currencyCodes,
    'dateFormat': dateFormatPattern,
    'languages': languages,
    'timezones': timezones,
    'tld': tld,
    'decimalSeparator': decimalSeparator,
    'groupSeparator': groupSeparator,
    'currencyPattern': currencyPattern,
    'phoneLengths': phoneLengths,
    'phoneExample': phoneExample,
    'nationalPrefix': nationalPrefix,
    'phoneInternationalPrefix': phoneInternationalPrefix,
    'phonePattern': phonePattern,
    'phoneLeadingDigits': phoneLeadingDigits,
    'phoneTypesPattern': phoneTypesPattern,
    'isMainCountryForDialCode': isMainCountryForDialCode,
    'isEUMember': isEUMember,
    'isEurozone': isEurozone,
    'isUNMember': isUNMember,
  };

  /// Returns a copy with the given fields replaced, for example to fix or
  /// extend the bundled data before passing it to a picker:
  ///
  /// ```dart
  /// final india = GlobeData.countryByAlpha2('IN')!;
  /// final custom = india.copyWith(name: 'Bharat', aliases: ['India']);
  /// ```
  ///
  /// Keep [alpha2Code] unchanged: links to currencies, dial codes and
  /// localized names, and equality, use it.
  GlobeCountry copyWith({
    String? name,
    String? alpha2Code,
    String? alpha3Code,
    GlobeRegion? region,
    String? subregion,
    List<String>? dialCodes,
    List<String>? currencyCodes,
    String? dateFormatPattern,
    List<String>? aliases,
    String? numCode,
    String? capital,
    List<String>? languages,
    List<String>? timezones,
    String? tld,
    String? decimalSeparator,
    String? groupSeparator,
    String? currencyPattern,
    List<int>? phoneLengths,
    String? phoneExample,
    String? nationalPrefix,
    String? phoneInternationalPrefix,
    String? phonePattern,
    String? phoneLeadingDigits,
    String? phoneTypesPattern,
    bool? isMainCountryForDialCode,
    bool? isEUMember,
    bool? isEurozone,
    bool? isUNMember,
  }) => GlobeCountry(
    name: name ?? this.name,
    alpha2Code: alpha2Code ?? this.alpha2Code,
    alpha3Code: alpha3Code ?? this.alpha3Code,
    region: region ?? this.region,
    subregion: subregion ?? this.subregion,
    dialCodes: dialCodes ?? this.dialCodes,
    currencyCodes: currencyCodes ?? this.currencyCodes,
    dateFormatPattern: dateFormatPattern ?? this.dateFormatPattern,
    aliases: aliases ?? this.aliases,
    numCode: numCode ?? this.numCode,
    capital: capital ?? this.capital,
    languages: languages ?? this.languages,
    timezones: timezones ?? this.timezones,
    tld: tld ?? this.tld,
    decimalSeparator: decimalSeparator ?? this.decimalSeparator,
    groupSeparator: groupSeparator ?? this.groupSeparator,
    currencyPattern: currencyPattern ?? this.currencyPattern,
    phoneLengths: phoneLengths ?? this.phoneLengths,
    phoneExample: phoneExample ?? this.phoneExample,
    nationalPrefix: nationalPrefix ?? this.nationalPrefix,
    phoneInternationalPrefix:
        phoneInternationalPrefix ?? this.phoneInternationalPrefix,
    phonePattern: phonePattern ?? this.phonePattern,
    phoneLeadingDigits: phoneLeadingDigits ?? this.phoneLeadingDigits,
    phoneTypesPattern: phoneTypesPattern ?? this.phoneTypesPattern,
    isMainCountryForDialCode:
        isMainCountryForDialCode ?? this.isMainCountryForDialCode,
    isEUMember: isEUMember ?? this.isEUMember,
    isEurozone: isEurozone ?? this.isEurozone,
    isUNMember: isUNMember ?? this.isUNMember,
  );

  @override
  bool operator ==(Object other) =>
      other is GlobeCountry && other.alpha2Code == alpha2Code;

  @override
  int get hashCode => alpha2Code.hashCode;

  @override
  String toString() => 'GlobeCountry($alpha2Code, $name)';
}

/// Builds a flag emoji from regional indicator symbols, for example `IN`
/// becomes 🇮🇳. Returns an empty string for codes that are not two letters.
String flagEmojiFor(String alpha2Code) {
  final code = alpha2Code.toUpperCase();
  if (!_alpha2Pattern.hasMatch(code)) return '';
  const regionalIndicatorA = 0x1F1E6;
  return String.fromCharCodes(
    code.codeUnits.map((unit) => regionalIndicatorA + unit - 0x41),
  );
}

final _nonDigit = RegExp(r'\D');
final _alpha2Pattern = RegExp(r'^[A-Z]{2}$');

/// Cleans phone input as typed or pasted: removes invisible direction marks,
/// reads full-width `＋` as `+` and non-Latin digits (Arabic, Devanagari,
/// full-width and others) as `0`-`9`, and drops an extension such as
/// `ext. 123`, `x123` or `#123`.
///
/// Internal: used by `GlobeData.parsePhone` and the phone models.
String normalizePhoneInput(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (_invisibleMarks.contains(rune)) continue;
    if (rune == 0xFF0B) {
      buffer.write('+');
      continue;
    }
    final digit = _decimalDigitValue(rune);
    if (digit != null) {
      buffer.writeCharCode(0x30 + digit);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString().replaceFirst(_phoneExtension, '');
}

/// The value of a Unicode decimal digit, or `null` for other characters.
int? _decimalDigitValue(int rune) {
  for (final zero in _digitZeros) {
    if (rune >= zero && rune <= zero + 9) return rune - zero;
  }
  return null;
}

/// Code points of `0` in the decimal digit sets people type numbers with.
const _digitZeros = [
  0x0030, 0x0660, 0x06F0, 0x07C0, 0x0966, 0x09E6, 0x0A66, 0x0AE6, //
  0x0B66, 0x0BE6, 0x0C66, 0x0CE6, 0x0D66, 0x0DE6, 0x0E50, 0x0ED0,
  0x0F20, 0x1040, 0x1090, 0x17E0, 0x1810, 0xFF10,
];

/// Direction marks and other invisible characters that come with pasted
/// numbers.
const _invisibleMarks = {
  0x200B, 0x200C, 0x200D, 0x200E, 0x200F, 0x202A, 0x202B, 0x202C, //
  0x202D, 0x202E, 0x2060, 0x2066, 0x2067, 0x2068, 0x2069, 0xFEFF,
};

/// An extension at the end of a number: `ext. 12`, `extension 12`, `x12`,
/// `#12` or `;ext=12`.
final _phoneExtension = RegExp(
  r'\s*(?:;ext=|(?:ext\.?|extension|x|#)\s*)\d+\s*$',
  caseSensitive: false,
);
