import 'package:flutter_globe_picker/src/globe_data.dart';
import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';

/// What a picker lists. The type parameter is the item type the picker
/// returns, so results are typed without casts:
///
/// ```dart
/// final GlobeCurrency? currency = await GlobePicker.show(
///   context,
///   type: GlobePickerType.currency,
/// );
/// ```
final class GlobePickerType<T extends GlobeItem> {
  const GlobePickerType._({
    required this.name,
    required this._loadItems,
    required this._findById,
    required this.defaultFields,
    required this.defaultTrailingFields,
    required this.defaultSearchFields,
  });

  /// Countries, returns [GlobeCountry].
  static const country = GlobePickerType<GlobeCountry>._(
    name: 'country',
    loadItems: _countries,
    findById: GlobeData.countryByCode,
    defaultFields: [GlobeField.flag, GlobeField.countryName],
    defaultTrailingFields: [],
    defaultSearchFields: [
      GlobeField.countryName,
      GlobeField.alpha2Code,
      GlobeField.alpha3Code,
      GlobeField.dialCode,
    ],
  );

  /// Currencies, returns [GlobeCurrency].
  static const currency = GlobePickerType<GlobeCurrency>._(
    name: 'currency',
    loadItems: _currencies,
    findById: GlobeData.currencyByCode,
    defaultFields: [
      GlobeField.flag,
      GlobeField.currencyName,
      GlobeField.currencyCode,
    ],
    defaultTrailingFields: [GlobeField.currencySymbol],
    defaultSearchFields: [
      GlobeField.currencyCode,
      GlobeField.currencyName,
      GlobeField.currencySymbol,
      GlobeField.countryName,
    ],
  );

  /// Dial codes, returns [GlobeDialCode].
  static const dialCode = GlobePickerType<GlobeDialCode>._(
    name: 'dialCode',
    loadItems: _dialCodes,
    findById: GlobeData.dialCodeByCode,
    defaultFields: [GlobeField.flag, GlobeField.countryName],
    defaultTrailingFields: [GlobeField.dialCode],
    defaultSearchFields: [
      GlobeField.dialCode,
      GlobeField.countryName,
      GlobeField.alpha2Code,
    ],
  );

  /// Date formats, returns [GlobeDateFormat].
  static const dateFormat = GlobePickerType<GlobeDateFormat>._(
    name: 'dateFormat',
    loadItems: _dateFormats,
    findById: GlobeData.dateFormatByPattern,
    defaultFields: [GlobeField.dateFormat, GlobeField.countryName],
    defaultTrailingFields: [GlobeField.dateExample],
    defaultSearchFields: [GlobeField.dateFormat, GlobeField.countryName],
  );

  /// Every picker type.
  static const List<GlobePickerType<GlobeItem>> values = [
    country,
    currency,
    dialCode,
    dateFormat,
  ];

  /// Stable name, for example `country`.
  final String name;

  final List<T> Function() _loadItems;
  final T? Function(String id) _findById;

  /// Fields shown by default: the first text field is the title, the others
  /// form the subtitle.
  final List<GlobeField> defaultFields;

  /// Fields shown by default at the end of each row.
  final List<GlobeField> defaultTrailingFields;

  /// Fields searched by default.
  final List<GlobeField> defaultSearchFields;

  /// Every item of this type, in default order.
  List<T> get items => _loadItems();

  /// The item with this [id] (alpha-2 or alpha-3 code, currency code, dial
  /// code or date pattern), or `null`.
  T? itemById(String id) => _findById(id);

  @override
  String toString() => 'GlobePickerType.$name';
}

List<GlobeCountry> _countries() => GlobeData.countries;
List<GlobeCurrency> _currencies() => GlobeData.currencies;
List<GlobeDialCode> _dialCodes() => GlobeData.dialCodes;
List<GlobeDateFormat> _dateFormats() => GlobeData.dateFormats;
