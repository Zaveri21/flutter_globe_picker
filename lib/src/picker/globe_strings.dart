import 'package:flutter/foundation.dart';

import 'package:flutter_globe_picker/src/models/globe_region.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_type.dart';

/// Every text the pickers and fields show. English by default.
///
/// ```dart
/// const spanish = GlobeStrings(
///   countryTitle: 'Selecciona un país',
///   searchHint: 'Buscar',
///   noResults: 'Sin resultados',
/// );
/// GlobePicker.country(context, strings: spanish);
/// ```
@immutable
class GlobeStrings {
  /// Creates strings. Anything left out stays English.
  const GlobeStrings({
    this.countryTitle = 'Select country',
    this.currencyTitle = 'Select currency',
    this.dialCodeTitle = 'Select dial code',
    this.dateFormatTitle = 'Select date format',
    this.searchHint = 'Search',
    this.noResults = 'No results found',
    this.favorites = 'Favorites',
    this.recents = 'Recent',
    this.allItems = 'All',
    this.close = 'Close',
    this.done = 'Done',
    this.clearSearch = 'Clear search',
    this.phoneNumberLabel = 'Phone number',
    this.invalidPhoneNumber = 'Enter a valid phone number',
    this.requiredField = 'This field is required',
    this.selectCountry = 'Select country',
    this.selectedCount = _defaultSelectedCount,
    this.regionName = _defaultRegionName,
    this.moreCount = _defaultMoreCount,
  });

  /// English strings.
  static const english = GlobeStrings();

  /// Title of the country picker.
  final String countryTitle;

  /// Title of the currency picker.
  final String currencyTitle;

  /// Title of the dial code picker.
  final String dialCodeTitle;

  /// Title of the date format picker.
  final String dateFormatTitle;

  /// Hint inside the search bar.
  final String searchHint;

  /// Shown when the search finds nothing.
  final String noResults;

  /// Header of the favorites section.
  final String favorites;

  /// Header of the recently selected section.
  final String recents;

  /// Header of the full list when favorites or recents are shown above it.
  final String allItems;

  /// Label of the close button.
  final String close;

  /// Label of the confirm button in multi-select pickers.
  final String done;

  /// Tooltip of the button that clears the search.
  final String clearSearch;

  /// Default label of the phone field.
  final String phoneNumberLabel;

  /// Error shown by the phone field for an invalid number.
  final String invalidPhoneNumber;

  /// Error shown when a required field is empty.
  final String requiredField;

  /// Accessibility label of the country button in the phone field.
  final String selectCountry;

  /// Text of the confirm button with a count, for example `Done (3)`.
  final String Function(String done, int count) selectedCount;

  /// Name of a region, used by region section headers.
  final String Function(GlobeRegion region) regionName;

  /// Summary of extra items, for example `+3`.
  final String Function(int count) moreCount;

  /// The picker title for [type].
  String titleFor(GlobePickerType<dynamic> type) => switch (type.name) {
    'currency' => currencyTitle,
    'dialCode' => dialCodeTitle,
    'dateFormat' => dateFormatTitle,
    _ => countryTitle,
  };

  /// Returns a copy with the given strings replaced.
  GlobeStrings copyWith({
    String? countryTitle,
    String? currencyTitle,
    String? dialCodeTitle,
    String? dateFormatTitle,
    String? searchHint,
    String? noResults,
    String? favorites,
    String? recents,
    String? allItems,
    String? close,
    String? done,
    String? clearSearch,
    String? phoneNumberLabel,
    String? invalidPhoneNumber,
    String? requiredField,
    String? selectCountry,
    String Function(String done, int count)? selectedCount,
    String Function(GlobeRegion region)? regionName,
    String Function(int count)? moreCount,
  }) => GlobeStrings(
    countryTitle: countryTitle ?? this.countryTitle,
    currencyTitle: currencyTitle ?? this.currencyTitle,
    dialCodeTitle: dialCodeTitle ?? this.dialCodeTitle,
    dateFormatTitle: dateFormatTitle ?? this.dateFormatTitle,
    searchHint: searchHint ?? this.searchHint,
    noResults: noResults ?? this.noResults,
    favorites: favorites ?? this.favorites,
    recents: recents ?? this.recents,
    allItems: allItems ?? this.allItems,
    close: close ?? this.close,
    done: done ?? this.done,
    clearSearch: clearSearch ?? this.clearSearch,
    phoneNumberLabel: phoneNumberLabel ?? this.phoneNumberLabel,
    invalidPhoneNumber: invalidPhoneNumber ?? this.invalidPhoneNumber,
    requiredField: requiredField ?? this.requiredField,
    selectCountry: selectCountry ?? this.selectCountry,
    selectedCount: selectedCount ?? this.selectedCount,
    regionName: regionName ?? this.regionName,
    moreCount: moreCount ?? this.moreCount,
  );

  static String _defaultSelectedCount(String done, int count) =>
      count == 0 ? done : '$done ($count)';

  static String _defaultRegionName(GlobeRegion region) => region.label;

  static String _defaultMoreCount(int count) => '+$count';
}
