## 0.1.0

First release.

- Linked models: `GlobeCountry`, `GlobeCurrency`, `GlobeDialCode` and `GlobeDateFormat`, all subtypes of the sealed `GlobeItem`.
- `copyWith`, `toJson` and `fromJson` on `GlobeCountry` and `GlobeCurrency`.
- `package:flutter_globe_picker/globe_data.dart`: the data, lookups, search and formatting without any widget, for your own UI.
- Offline data for 250 countries and territories, 153 currencies, 232 dial codes and 11 date formats in one readable JSON file (`assets/globe_data.json`), generated from Unicode CLDR 49, libphonenumber 9.0.43, IANA tz 2026f and flag-icons 7.6.0.
- `GlobeData.load()` with `countryOverrides` and `currencyOverrides` to change or add data at runtime, `GlobeData.loadFromJson()` for your own JSON, and `GlobeDataSource` to give any picker or field its own data. Pickers load the bundled data by themselves.
- `GlobeDataLoader` to build your own widgets once the data is loaded.
- `GlobePicker` with bottom sheet, dialog, full page and Cupertino sheet modes, single and multi-select.
- `GlobePickerView` for inline use and `GlobePickerBuilder` for fully custom UIs.
- `GlobeFilter` shared by every picker type, with EU, eurozone and UN presets.
- Accent-insensitive, ranked search over configurable fields.
- Full customization: `GlobePickerTheme` (also as a `ThemeExtension`), `GlobeStrings`, `GlobeDisplay` and `GlobePickerBuilders`.
- Favorites, recents (`GlobeRecents`), alphabet and region grouping.
- `GlobePhoneField` with libphonenumber-based validation, E.164 output and automatic country detection.
- `GlobePickerField` form field and `GlobePickerButton`.
- `GlobeFlag` with emoji and SVG flags in rectangle, square and circle shapes.
- Headless `GlobeData`: lookups, search, `countryFromLocale`, phone parsing, date and currency formatting.
