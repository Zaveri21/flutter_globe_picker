# flutter_globe_picker 🌍

> **All-in-one world data and pickers for Flutter.**
> Countries, currencies, dial codes, date formats and flags, linked together,
> with fully customizable pickers, search, filters and a phone field.

[![pub package](https://img.shields.io/pub/v/flutter_globe_picker.svg)](https://pub.dev/packages/flutter_globe_picker)
[![pub points](https://img.shields.io/pub/points/flutter_globe_picker)](https://pub.dev/packages/flutter_globe_picker/score)
[![likes](https://img.shields.io/pub/likes/flutter_globe_picker)](https://pub.dev/packages/flutter_globe_picker/score)
[![CI](https://github.com/your-username/flutter_globe_picker/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/flutter_globe_picker/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

<!-- TODO: add a GIF of the pickers here -->

- **One package** instead of a country picker, a currency picker, a dial code picker, a flag package and a phone field.
- **Linked models**: pick a currency and read its countries and flags; pick a country and read its currency, dial code, date format and number format.
- **One filter** for every picker type.
- **Three levels of UI**: ready-made pickers, building blocks, or fully headless.
- **Fully customizable**: theme, texts, visible parts, and a builder for every part.
- **Offline, one JSON file**: all data ships in the package as one readable JSON file, with no network calls. Pickers load it by themselves; change any value or bring your own copy at runtime.
- **No extra packages for you to add**: the only dependency is `flutter_svg` (for SVG flags), which installs automatically.

| Data | Count | Source |
|---|---|---|
| Countries and territories | 250 (ISO 3166-1 + Kosovo) | Unicode CLDR |
| Currencies in use | 153 (ISO 4217) | Unicode CLDR |
| Dial codes | 232 | Google libphonenumber |
| Date formats | 11 | Unicode CLDR |
| SVG flags | 4:3 and 1:1 | flag-icons |

---

## Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Three ways to use it](#three-ways-to-use-it)
- [Linked models](#linked-models)
- [One filter for everything](#one-filter-for-everything)
- [What each row shows](#what-each-row-shows)
- [Search](#search)
- [Customize the UI](#customize-the-ui)
- [Favorites, recents, grouping, multi-select](#favorites-recents-grouping-multi-select)
- [Phone number field](#phone-number-field)
- [Form field and button](#form-field-and-button)
- [Controller](#controller)
- [Headless API](#headless-api)
- [Flags](#flags)
- [Localization, RTL and accessibility](#localization-rtl-and-accessibility)
- [Platform support](#platform-support)
- [Data](#data)
- [Migrating from other packages](#migrating-from-other-packages)
- [Roadmap](#roadmap)

---

## Installation

```yaml
dependencies:
  flutter_globe_picker: ^0.1.0
```

```dart
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
```

Requires Dart 3.11 and Flutter 3.41 or newer.

---

## Quick start

```dart
final country  = await GlobePicker.country(context);     // GlobeCountry?
final currency = await GlobePicker.currency(context);    // GlobeCurrency?
final dialCode = await GlobePicker.dialCode(context);    // GlobeDialCode?
final format   = await GlobePicker.dateFormat(context);  // GlobeDateFormat?
```

Every picker returns `null` when it is closed without a selection.

Pickers, fields and buttons load the bundled data by themselves the first time they need it. If your own code reads `GlobeData` directly, load it once before `runApp`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobeData.load();
  runApp(const MyApp());
}
```

Choose how it opens:

```dart
GlobePicker.currency(context); // bottom sheet (default)
GlobePicker.currency(context, mode: GlobePickerMode.dialog);
GlobePicker.currency(context, mode: GlobePickerMode.fullPage);
GlobePicker.currency(context, mode: GlobePickerMode.cupertinoSheet);
```

Or use one generic method. The result type follows the picker type:

```dart
final GlobeCurrency? currency = await GlobePicker.show(
  context,
  type: GlobePickerType.currency,
);
```

---

## Three ways to use it

### 1. Ready-made UI

`GlobePicker` opens a complete picker (title, search bar, list) as a bottom sheet, dialog, full page or Cupertino sheet. See [Quick start](#quick-start).

### 2. Building blocks

Embed the same picker anywhere, for example inside your own screen, sheet or dialog:

```dart
GlobePickerView(
  type: GlobePickerType.country,
  onSelected: (country) => setState(() => selected = country),
)
```

`GlobePickerView` fills the space it gets, so give it a bounded height (for example inside `Expanded` or a `SizedBox`).

The pieces are public too: `GlobeSearchBar`, `GlobeListTile`, `GlobeFlag`, `GlobePickerButton` and `GlobePickerController`.

### 3. Headless

`GlobePickerBuilder` does the filtering, sorting, searching, grouping and selection, and you draw everything:

```dart
GlobePickerBuilder(
  type: GlobePickerType.country,
  onSelected: (country) => print(country.name),
  builder: (context, snapshot) => Column(
    children: [
      TextField(onChanged: snapshot.search),
      Expanded(
        child: GridView.count(
          crossAxisCount: 4,
          children: [
            for (final country in snapshot.items)
              InkWell(
                onTap: () => snapshot.onItemTap(country),
                child: GlobeFlag.fromItem(country, type: GlobeFlagType.svg),
              ),
          ],
        ),
      ),
    ],
  ),
)
```

The snapshot gives you `items`, `sections`, `query`, `selection`, `isSelected()`, `search()`, `onItemTap()`, `confirm()` and `close()`.

Or skip the widgets entirely and use [`GlobeData`](#headless-api).

---

## Linked models

Every model can reach every other model. All four are subtypes of the sealed class `GlobeItem`, so a `switch` over them is checked by the compiler.

### `GlobeCountry`

```dart
final india = GlobeData.countryByAlpha2('IN')!;

india.name;               // India
india.alpha2Code;         // IN
india.alpha3Code;         // IND
india.numCode;            // 356
india.flagEmoji;          // 🇮🇳
india.capital;            // New Delhi
india.region;             // GlobeRegion.asia
india.subregion;          // Southern Asia
india.languages;          // [hi, en]
india.timezones;          // [Asia/Kolkata]
india.tld;                // .in

india.dialCode;           // +91
india.callingCode;        // +91
india.dialCodeInfo;       // GlobeDialCode

india.currency;           // GlobeCurrency? (null only for Antarctica)
india.currencies;         // every currency in use (Panama: PAB, USD)

india.dateFormat;         // GlobeDateFormat(dd/MM/yyyy)
india.numberFormat;       // separators and grouping: 12,34,567.50

india.phoneLengths;       // [10]
india.phoneExample;       // 8123456789
india.isValidPhoneNumber('98765 43210'); // true

india.isEUMember;         // false
india.isEurozone;         // false
india.isUNMember;         // true
```

### `GlobeCurrency`

```dart
final euro = GlobeData.currencyByCode('EUR')!;

euro.code;             // EUR
euro.name;             // Euro
euro.symbol;           // €
euro.nativeSymbol;     // €   (AED: د.إ.)
euro.numCode;          // 978
euro.decimalDigits;    // 2   (JPY: 0, KWD: 3)
euro.countries;        // every country using the euro
euro.primaryCountry;   // null for shared currencies (INR → India)

euro.format(1234.5);                                          // €1,234.50
euro.format(1234.5, country: GlobeData.countryByAlpha2('DE')); // 1.234,50 €
GlobeData.currencyByCode('INR')!.format(1234567.5);           // ₹12,34,567.50
```

### `GlobeDialCode`

```dart
final plusOne = GlobeData.dialCodeByCode('+1')!;
plusOne.countries;   // United States, Canada
plusOne.country;     // United States (main country)

GlobeData.countryByAlpha2('JM')!.dialCode; // +1876 (area code included)
```

### `GlobeDateFormat`

```dart
final usFormat = GlobeData.countryByAlpha2('US')!.dateFormat;
usFormat.pattern;                       // MM/dd/yyyy
usFormat.format(DateTime(2026, 11, 8)); // 11/08/2026
usFormat.countries;                     // countries writing dates this way
```

### Relationship map

```
             currencies          countries
  GlobeCountry ──────────▶ GlobeCurrency ──────────▶ GlobeCountry
       │
       ├── dialCodeInfo ──▶ GlobeDialCode ── countries ──▶ GlobeCountry
       │
       └── dateFormat ───▶ GlobeDateFormat ─ countries ──▶ GlobeCountry
```

---

## One filter for everything

`GlobeFilter` works with every picker type and with headless lists.

```dart
const appFilter = GlobeFilter(
  excludeCountries: ['AQ', 'BV', 'HM'],
  excludeCurrencies: ['XOF'],
  regions: [GlobeRegion.asia, GlobeRegion.europe],
);

GlobePicker.country(context, filter: appFilter);
GlobePicker.currency(context, filter: appFilter);
GlobePicker.dialCode(context, filter: appFilter);
```

| Option | Type | Applies to |
|---|---|---|
| `countries` / `excludeCountries` | `List<String>` (alpha-2) | every type |
| `regions` / `excludeRegions` | `List<GlobeRegion>` | every type |
| `where` | `bool Function(GlobeCountry)` | every type |
| `currencies` / `excludeCurrencies` | `List<String>` (ISO 4217) | currency picker |
| `dialCodes` / `excludeDialCodes` | `List<String>` (`+91` or `91`) | dial code picker |

**How it works:** country rules apply to every type. An item is kept when at least one of its countries passes them, so excluding a country also hides a dial code that only it uses. Currency and dial code rules only filter their own picker, so one shared filter can hide a currency without hiding the countries that use it. Codes are case-insensitive.

Presets:

```dart
GlobeFilter.europeanUnion; // 27 EU members
GlobeFilter.eurozone;      // 21 euro countries
GlobeFilter.unMembers;     // 193 UN members
```

Combine and modify:

```dart
final asianOnly = appFilter.copyWith(regions: [GlobeRegion.asia]);
final both = appFilter + GlobeFilter(where: (country) => country.isUNMember); // must pass both
```

Use it without UI:

```dart
final countries = appFilter.apply(GlobeData.countries);
final keep = appFilter.matches(someItem);
```

---

## What each row shows

```dart
GlobePicker.country(
  context,
  display: const GlobeDisplay(
    fields: [GlobeField.flag, GlobeField.countryName, GlobeField.capital],
    trailingFields: [GlobeField.dialCode],
    flagType: GlobeFlagType.svg,
    flagShape: GlobeFlagShape.circle,
  ),
);
```

The first text field is the title, the other text fields form the subtitle, and `trailingFields` appear at the end of the row. Every field works with every picker type.

| `GlobeField` | Shows |
|---|---|
| `flag` | emoji or SVG flag |
| `countryName` | country name |
| `alpha2Code` / `alpha3Code` / `numCode` | ISO codes |
| `dialCode` | dial code |
| `currencyName` / `currencyCode` / `currencySymbol` | currency |
| `dateFormat` / `dateExample` | date pattern / today's date in that pattern |
| `region` / `capital` | region / capital city |

`GlobeDisplay` also controls which parts are visible: `showTitle`, `showCloseButton`, `showDragHandle`, `showDividers`, `showSelectedIndicator` and `showSectionHeaders`.

---

## Search

Search ignores case, accents and punctuation. `cote d iv` finds "Côte d'Ivoire", `91` finds `+91` and aliases such as "Ivory Coast" match too. Exact matches come first, then prefixes, then other matches.

```dart
GlobePicker.country(
  context,
  search: const GlobeSearchConfig(
    hint: 'Search country or code',
    fields: [GlobeField.countryName, GlobeField.alpha2Code, GlobeField.dialCode],
    autoFocus: true,
    minChars: 1,
    debounce: Duration(milliseconds: 200),
  ),
);
```

Set `enabled: false` to hide the search bar.

---

## Customize the UI

Five levels, from small tweaks to a full redesign.

### 1. Theme

Every value is optional. Defaults come from your `ColorScheme` and `TextTheme`, so the pickers match light and dark mode with no setup.

```dart
GlobePicker.country(
  context,
  theme: const GlobePickerTheme(
    backgroundColor: Colors.white,
    borderRadius: 20,
    heightFactor: 0.9,
    titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    itemTitleStyle: TextStyle(fontSize: 16),
    selectedTileColor: Color(0x1A2196F3),
    flagWidth: 28,
    flagHeight: 20,
  ),
);
```

Set it once for the whole app:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [GlobePickerTheme(borderRadius: 24)],
  ),
);
```

### 2. Texts

```dart
const spanish = GlobeStrings(
  countryTitle: 'Selecciona un país',
  searchHint: 'Buscar',
  noResults: 'Sin resultados',
  done: 'Listo',
);
GlobePicker.country(context, strings: spanish);
```

### 3. Show or hide parts

```dart
display: const GlobeDisplay(
  showTitle: false,
  showDividers: true,
  showSelectedIndicator: false,
),
search: const GlobeSearchConfig(enabled: false),
```

### 4. Builders for each part

Replace any part and keep the rest:

```dart
GlobePicker.currency(
  context,
  builders: GlobePickerBuilders(
    itemBuilder: (context, currency, isSelected, onTap) => ListTile(
      leading: GlobeFlag.fromItem(currency, shape: GlobeFlagShape.circle),
      title: Text('${currency.name} (${currency.symbol})'),
      subtitle: Text(currency.format(1234.5)),
      selected: isSelected,
      onTap: onTap,
    ),
    headerBuilder: (context, snapshot) => const Text('Pick a currency'),
    searchBarBuilder: (context, textController, onChanged) =>
        TextField(controller: textController, onChanged: onChanged),
    sectionHeaderBuilder: (context, title) => Text(title),
    separatorBuilder: (context) => const Divider(),
    emptyBuilder: (context, query) => Text('Nothing for "$query"'),
    flagBuilder: (context, currency) => GlobeFlag.fromItem(currency),
    selectedIndicatorBuilder: (context, isSelected) => const Icon(Icons.done),
    footerBuilder: (context, snapshot) => Text('${snapshot.items.length} currencies'),
    containerBuilder: (context, child) => Padding(padding: const EdgeInsets.all(8), child: child),
  ),
);
```

With generic widgets such as `GlobePickerView`, name the item type so the builder callbacks are typed: `GlobePickerView<GlobeCurrency>(builders: GlobePickerBuilders(...))`.

### 5. Build it all yourself

Use [`GlobePickerBuilder`](#3-headless) and draw everything from the snapshot.

### Reuse options

`GlobePickerOptions` bundles filter, display, search, grouping, favorites, title, theme and texts so you can share them between pickers and widgets:

```dart
const options = GlobePickerOptions(
  filter: GlobeFilter(excludeCountries: ['AQ']),
  groupBy: GlobeGroupBy.alphabet,
  favorites: ['IN', 'US'],
);

GlobePicker.show(context, type: GlobePickerType.country, options: options);
GlobePickerView(type: GlobePickerType.country, options: options);
```

---

## Favorites, recents, grouping, multi-select

```dart
GlobePicker.country(
  context,
  favorites: const ['IN', 'US', 'GB'], // pinned on top
  selected: 'IN',                      // preselected
  showRecents: true,                   // recently picked on top
  groupBy: GlobeGroupBy.alphabet,      // or GlobeGroupBy.region
);
```

Multi-select returns a list, or `null` when closed without confirming:

```dart
final countries = await GlobePicker.countries(context, selected: const ['IN']);
final currencies = await GlobePicker.currencies(context);
final items = await GlobePicker.showMultiple(context, type: GlobePickerType.dialCode);
```

Recents are kept in memory for the app session. To keep them across launches, save and restore them with your own storage:

```dart
GlobeRecents.instance.restore(GlobePickerType.country, savedIds);
GlobeRecents.instance.addListener(() {
  save(GlobeRecents.instance.idsFor(GlobePickerType.country));
});
```

---

## Phone number field

```dart
GlobePhoneField(
  initialCountryCode: 'IN',        // otherwise from the device locale
  isRequired: true,
  onChanged: (phone) {
    phone.e164;      // +919876543210
    phone.isValid;   // checked against the country's numbering plan
    phone.country;   // GlobeCountry
  },
)
```

- The country button opens a searchable country picker with dial codes.
- Pasting `+44 7400 123456` or `0044…` switches the country automatically.
- Validation uses libphonenumber's numbering plans: possible lengths and number patterns.
- A leading trunk prefix is accepted (`07400 123456` in the UK becomes `+447400123456`).
- It works inside `Form`, with `validator`, `onSaved` and `autovalidateMode`.
- The hint shows an example number for the selected country.

---

## Form field and button

```dart
GlobePickerField(
  type: GlobePickerType.currency,
  decoration: const InputDecoration(labelText: 'Currency'),
  validator: (currency) => currency == null ? 'Select a currency' : null,
  onChanged: (currency) => print(currency?.code),
  showClearButton: true,
)

GlobePickerButton(
  type: GlobePickerType.currency,
  value: currency,
  onChanged: (value) => setState(() => currency = value),
)
```

---

## Controller

```dart
final controller = GlobePickerController<GlobeCountry>();

GlobePickerView(type: GlobePickerType.country, controller: controller);

controller.search('ind');
controller.select(GlobeData.countryByAlpha2('IN')!);
controller.toggle(GlobeData.countryByAlpha2('US')!);
controller.clearSelection();
controller.selected;   // first selected item
controller.selection;  // all selected items
```

Dispose the controller when you no longer need it.

---

## Headless API

Building your own UI? Import only the data: models, lookups, search, filters, phone parsing and formatting, without any widget.

```dart
import 'package:flutter_globe_picker/globe_data.dart';
```

Every model converts to and from JSON with the keys used in [`assets/globe_data.json`](assets/globe_data.json), so you can store it, send it to your backend or load your own data:

```dart
final json = GlobeData.countryByAlpha2('IN')!.toJson();
final country = GlobeCountry.fromJson(json);
final currency = GlobeCurrency.fromJson({'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'});
```

```dart
// Collections (sorted, unmodifiable)
GlobeData.countries;
GlobeData.currencies;
GlobeData.dialCodes;
GlobeData.dateFormats;

// Lookups
GlobeData.countryByAlpha2('IN');
GlobeData.countryByAlpha3('IND');
GlobeData.countryByNumCode(356);
GlobeData.countryByCode('IND');            // alpha-2, alpha-3 or numeric
GlobeData.countryByName('Ivory Coast');
GlobeData.countriesByRegion(GlobeRegion.europe);
GlobeData.countriesByDialCode('+1');       // every NANP country
GlobeData.dialCodeByCode('+44');
GlobeData.currencyByCode('INR');
GlobeData.currenciesBySymbol(r'$');
GlobeData.dateFormatByPattern('dd/MM/yyyy');

// The user's country and currency
GlobeData.countryFromLocale(Localizations.localeOf(context));
GlobeData.currencyFromLocale(Localizations.localeOf(context));

// Search
GlobeData.searchCountries('ind');
GlobeData.searchCurrencies('dollar');
GlobeData.searchDialCodes('44');
GlobeData.search('eur'); // countries and currencies

// Phone numbers
GlobeData.parsePhone('+1 416 555 1234');   // Canada, resolved by area code
GlobeData.parsePhone('98765 43210', defaultCountry: india);

// Formatting
GlobeData.formatDate(date, countryCode: 'US');            // 11/08/2026
GlobeData.formatDate(date, pattern: 'EEE, d MMM yyyy');    // Sun, 8 Nov 2026
GlobeData.formatDateTime(date, countryCode: 'US', use24Hour: false); // 11/08/2026 02:05 PM
GlobeData.formatCurrency(1234.5, currencyCode: 'EUR', countryCode: 'FR'); // 1 234,50 €
```

Month and weekday names are English by default. Pass `symbols: GlobeDateSymbols(...)` to use another language.

---

## Flags

```dart
GlobeFlag(code: 'IN');                                    // emoji or SVG (auto)
GlobeFlag(code: 'IN', type: GlobeFlagType.svg, width: 40);
GlobeFlag(code: 'IN', shape: GlobeFlagShape.circle);
GlobeFlag.fromItem(GlobeData.currencyByCode('EUR')!);     // EU flag
GlobeFlag.fromItem(dialCode);                             // main country's flag

country.flagEmoji;        // 🇮🇳
country.flagAssetPath();  // assets/flags/4x3/in.svg (package: flutter_globe_picker)
```

`GlobeFlagType.auto` (the default) uses emoji on Android, iOS, macOS and the web, and SVG on Windows and Linux, where flag emoji show as letters.

SVG flags come from [flag-icons](https://github.com/lipis/flag-icons) (MIT) in 4:3 and 1:1 shapes. They add about 4.6 MB of uncompressed assets to your app (much less once compressed).

---

## Localization, RTL and accessibility

- All picker texts can be translated with `GlobeStrings`.
- Country and currency names are in English. To show them in your language, give the names as data overrides (see [Change the data](#change-the-data)):

  ```dart
  GlobePicker.country(
    context,
    strings: const GlobeStrings(countryTitle: 'देश चुनें', searchHint: 'खोजें'),
    dataSource: const GlobeDataSource(
      countryOverrides: {'IN': {'name': 'भारत'}, 'JP': {'name': 'जापान'}},
    ),
  );
  ```
- Layouts use directional padding and work in right-to-left languages.
- Flags have semantic labels ("Flag of India"), section headers are marked as headers, and text scales with the system font size.

---

## Platform support

| Android | iOS | Web | macOS | Windows | Linux |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

The package is pure Dart and Flutter with no platform code.

---

## Data

All data ships in the package as one readable JSON file, [`assets/globe_data.json`](assets/globe_data.json): every country and every currency, plus a language → country table used by `GlobeData.countryFromLocale`.

```json
{
  "sources": { "cldr": "49.0.0", "libphonenumber": "v9.0.43", "tz": "2026f", "flagIcons": "7.6.0" },
  "countries": [
    {
      "name": "India",
      "alpha2Code": "IN",
      "alpha3Code": "IND",
      "numCode": "356",
      "capital": "New Delhi",
      "region": "asia",
      "dialCodes": ["+91"],
      "currencyCodes": ["INR"],
      "timezones": ["Asia/Kolkata"],
      "dateFormat": "dd/MM/yyyy",
      "phoneLengths": [10],
      "phoneExample": "8123456789"
    }
  ],
  "currencies": [
    { "code": "INR", "name": "Indian Rupee", "symbol": "₹", "numCode": "356", "decimalDigits": 2 }
  ],
  "languageCountries": { "hi": "IN", "ja": "JP" }
}
```

Shortened here: each country has every field of `GlobeCountry` (the keys of `toJson()`).

The file is generated from the sources below by `tool/build_data.dart`, with manual corrections from [`data/overrides.json`](data/overrides.json).

| Data | Source | License |
|---|---|---|
| Country names, codes, regions, currencies, symbols, date and number formats | [Unicode CLDR](https://cldr.unicode.org) 49 | Unicode License v3 |
| Dial codes, phone lengths, patterns and examples | [Google libphonenumber](https://github.com/google/libphonenumber) 9.0.43 | Apache 2.0 |
| Time zones | [IANA tz database](https://www.iana.org/time-zones) 2026f | Public domain |
| SVG flags and capitals | [flag-icons](https://github.com/lipis/flag-icons) 7.6.0 | MIT |

### Good to know

- **Empty values are expected.** Uninhabited territories (Antarctica, Bouvet Island, Heard Island) have no capital, languages or time zones. Kosovo has no ISO numeric code or domain. Seven territories without their own phone numbering (AQ, BV, GS, HM, PN, TF, UM) have no phone pattern, lengths or example, so the phone field accepts any number of 4 to 15 digits for them.
- **`phoneLeadingDigits` and `phoneOwnershipPattern` are usually `null`.** They are only needed to tell apart countries sharing a dial code, such as Kazakhstan inside `+7` or Canada inside `+1`.
- **`phoneLengths` covers mobile, landline and VoIP numbers.** Short codes, toll-free and premium numbers are left out.
- **`decimalDigits` follows CLDR**, which reflects everyday use: COP, HUF and IDR use 0 digits although ISO 4217 lists 2.
- **Saint Martin and Western Sahara** share every number range with Guadeloupe and Morocco, so their numbers are detected as those countries, as in libphonenumber.

### Change the data

Change any value at runtime, before it is used. Keys are alpha-2 or currency codes; values hold the fields to replace, with the JSON keys above. A code that does not exist yet adds a new entry (with every required field).

```dart
await GlobeData.load(
  countryOverrides: {
    'IN': {'name': 'Bharat', 'aliases': ['India']},
  },
  currencyOverrides: {
    'INR': {'symbol': 'Rs'},
  },
);
```

Or give the same overrides, your own copy of the JSON, or JSON text from your server to any widget with a `GlobeDataSource`. Widgets without one use the data already loaded, or load the bundled data:

```dart
// Your updated copy of globe_data.json, declared in your pubspec.
const myData = GlobeDataSource(assetKey: 'assets/my_globe_data.json');

GlobePicker.country(context, dataSource: myData);
GlobePickerView(type: GlobePickerType.country, options: const GlobePickerOptions(dataSource: myData));
GlobePhoneField(pickerOptions: const GlobePickerOptions(dataSource: myData));

// JSON text you downloaded.
GlobeData.loadFromJson(jsonText);
```

- The app has one data set: loading a source replaces it everywhere, and every picker, lookup and phone parser uses it.
- Keep `alpha2Code` (or a currency's `code`) unchanged: links between countries, currencies and dial codes use it.
- To hide items, use a [`GlobeFilter`](#one-filter-for-everything) instead of changing the data.
- `copyWith` changes a single model, for example to pass a custom list to a picker with `items`.
- In your own widgets that read `GlobeData` before it may be loaded, wrap them in `GlobeDataLoader`.

Found a mistake? Please open an issue with a source link. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Migrating from other packages

| From | To |
|---|---|
| `showCountryPicker(context: context, onSelect: ...)` (country_picker) | `final country = await GlobePicker.country(context);` |
| `showCurrencyPicker(context: context, onSelect: ...)` (currency_picker) | `final currency = await GlobePicker.currency(context);` |
| `CountryCodePicker(...)` (country_code_picker) | `GlobePickerButton(type: GlobePickerType.dialCode, ...)` or `GlobePhoneField(...)` |
| `country.phoneCode` | `country.callingCode` (`+91`) |
| `country.countryCode` | `country.alpha2Code` |
| `country.flagEmoji` | `country.flagEmoji` |

---

## Roadmap

- [ ] Phone number formatting as you type
- [ ] Translated currency names and picker texts
- [ ] Translated month and weekday names for date formatting
- [ ] Subdivisions (states and provinces)
- [ ] Postal code formats
- [ ] Optional separate flags package for smaller apps
- [ ] Scroll to the selected item when a picker opens

---

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the setup, how the data is built, and the checks every pull request must pass.

## License

MIT. See [LICENSE](LICENSE). Bundled data and flags have their own licenses, listed in [NOTICE](NOTICE).

If this package helps you, please give it a ⭐ on GitHub and a 👍 on pub.dev.
