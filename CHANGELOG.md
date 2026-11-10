## 0.1.2

- Removed screenshots that were not used, from the repository and from the published package.

## 0.1.1

- README screenshots load from the repository by full URL, so they show on pub.dev.

## 0.1.0

First release. Requires Dart 3.13.7 and Flutter 3.47.8 or newer.

- Linked models: `GlobeCountry`, `GlobeCurrency`, `GlobeDialCode` and `GlobeDateFormat`, all subtypes of the sealed `GlobeItem`.
- `copyWith`, `toJson` and `fromJson` on `GlobeCountry` and `GlobeCurrency`.
- Offline data for 250 countries and territories, 153 currencies, 232 dial codes and 11 date formats in one readable JSON file (`assets/globe_data.json`), generated from Unicode CLDR 49, libphonenumber 9.0.43, IANA tz 2026f and flag-icons 7.6.0.
- `GlobeData.load()` with `countryOverrides` and `currencyOverrides` to change or add data at runtime, `GlobeData.loadFromJson()` for your own JSON, and `GlobeDataSource` to give any picker or field its own data. Pickers load the bundled data by themselves.
- Country and currency names in 29 languages besides English (`assets/globe_translations.json`, linked to the data by code), with English as the fallback. Pickers show, sort and search them in the app's language; `translationOverrides` and `languages` customize them.
- `GlobeDataLoader` to build your own widgets once the data is loaded.
- `GlobePicker` with bottom sheet, dialog, full page and Cupertino sheet modes, single and multi-select.
- `GlobePickerView` for inline use and `GlobePickerBuilder` for fully custom UIs.
- `GlobeFilter` shared by every picker type, with EU, eurozone and UN presets.
- Accent-insensitive, ranked search over configurable fields.
- Full customization: `GlobePickerTheme` (also as a `ThemeExtension`), `GlobeStrings`, `GlobeDisplay` and `GlobePickerBuilders`.
- Favorites, recents (`GlobeRecents`), alphabet and region grouping.
- `GlobePhoneField` with libphonenumber-based validation (lengths, general pattern and every number type), E.164 output and automatic country detection from typing, pasting, autofill or the controller; `Form.reset` support.
- `GlobeData.parsePhone` understands each country's international prefix (`00`, `011`, `0011`), extensions, invisible direction marks, full-width `＋` and non-Latin digits, and resolves countries sharing a calling code like libphonenumber.
- `GlobePickerField` form field and `GlobePickerButton`.
- `GlobeFlag` with emoji and SVG flags in rectangle, square and circle shapes.
- Headless `GlobeData`: lookups, search, `countryFromLocale`, phone parsing, date and currency formatting.
