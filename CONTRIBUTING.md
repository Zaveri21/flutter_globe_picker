# Contributing to flutter_globe_picker

Thanks for helping. This guide covers the setup, how the code and data are organized, and the checks every pull request must pass.

## Setup

```bash
git clone https://github.com/your-username/flutter_globe_picker.git
cd flutter_globe_picker
flutter pub get
flutter test
cd example && flutter run
```

## Project structure

```
flutter_globe_picker/
├── lib/
│   ├── flutter_globe_picker.dart   # everything: data and widgets
│   ├── globe_data.dart             # data only, no widgets
│   └── src/
│       ├── globe_data.dart         # GlobeData: loading, lookups, search, phone,
│       │                           # formatting
│       ├── globe_data_source.dart  # GlobeDataSource: where the data comes from
│       ├── models/                 # plain model classes: GlobeCountry, GlobeCurrency,
│       │                           # GlobeDialCode, GlobeDateFormat, GlobePhoneNumber,
│       │                           # GlobeRegion, plus the internal lookup index
│       ├── filter/                 # GlobeFilter
│       ├── search/                 # GlobeField, normalizer and ranked search index
│       ├── format/                 # date pattern formatter, number format
│       ├── picker/                 # GlobePicker, GlobePickerView, GlobePickerBuilder,
│       │                           # options, theme, strings, controller, recents
│       └── widgets/                # GlobeFlag, GlobeListTile, GlobeSearchBar,
│                                   # GlobePickerField, GlobePickerButton,
│                                   # GlobePhoneField, GlobeDataLoader
├── assets/globe_data.json          # all the data, built by the tool, shipped
├── assets/flags/                   # SVG flags (4x3 and 1x1), copied by the tool
├── data/overrides.json             # manual corrections read by the tool
├── tool/build_data.dart            # builds assets/globe_data.json and the flags
├── example/                        # demo app with every feature
└── test/                           # unit and widget tests
```

## How the data is built

All data comes from pinned upstream sources:

| Data | Source |
|---|---|
| Names, ISO codes, regions, currencies, symbols, date and number formats | Unicode CLDR (`cldr-json` npm packages) |
| Dial codes, phone lengths, patterns, examples | Google libphonenumber `PhoneNumberMetadata.xml` |
| Time zones | IANA tz `zone.tab` |
| SVG flags and capitals | flag-icons |

Run the generator from the package root:

```bash
dart run tool/build_data.dart
```

It downloads the sources once (cached in `.dart_tool/flutter_globe_picker_cache/`), validates them, and writes:

- `assets/globe_data.json`: every country and every currency in one readable file. The package ships it and loads it at runtime; there is no generated Dart code.
- `assets/flags/4x3/*.svg` and `assets/flags/1x1/*.svg`

The script fails with a clear message when the data is inconsistent (missing dial codes, unknown currencies, invalid phone patterns, unusual date formats).

### Fixing data

**Never edit `assets/globe_data.json` by hand**, because the next run of the tool overwrites it. Put corrections in [`data/overrides.json`](data/overrides.json), keyed by ISO code. The values replace the generated fields:

```json
{
  "countries": {
    "JM": { "dialCodes": ["+1876", "+1658"] }
  },
  "currencies": {
    "RSD": { "symbol": "дин." }
  }
}
```

Then run `dart run tool/build_data.dart` and commit the regenerated `assets/globe_data.json` together with the override. In the pull request, link the source that proves the correction.

### Updating upstream versions

Change the version constants at the top of `tool/build_data.dart`, delete `.dart_tool/flutter_globe_picker_cache/`, run the generator, review the JSON diff, and update the versions in `README.md`, `NOTICE` and `CHANGELOG.md`.

## Code style

- Run `dart format lib test tool example/lib` before committing.
- `flutter analyze` must report no issues. The rules in `analysis_options.yaml` include strict casts, strict inference and `public_member_api_docs`.
- Use meaningful names. No single-letter variables, including in lambdas (`(country) => country.name`, not `(c) => c.name`) and comparators (`(first, second)`).
- Every public class, method and field needs a `///` doc comment, ideally with a short example.
- Keep the public API exported only from `lib/flutter_globe_picker.dart`.
- Do not add dependencies. The package depends only on Flutter and `flutter_svg`.

## Tests

```bash
flutter test
```

- Data changes are covered by `test/data/data_integrity_test.dart`: unique codes, links between models, valid example phone numbers, and translations for every country.
- New features need unit tests, and widget tests when they add UI.
- Every bundled SVG flag must parse with flutter_svg (`test/widgets/svg_flags_test.dart`).

## Pull request checklist

- [ ] `dart format --output=none --set-exit-if-changed lib test tool example/lib` passes
- [ ] `flutter analyze` reports no issues (package and `example/`)
- [ ] `flutter test` passes
- [ ] Generated files are up to date (`dart run tool/build_data.dart` produces no diff)
- [ ] Public API changes are documented in `README.md` and `CHANGELOG.md`
- [ ] Data corrections link their source

## Before publishing a release

- [ ] Bump `version` in `pubspec.yaml` and add a `CHANGELOG.md` entry
- [ ] `dart pub publish --dry-run` shows no warnings
- [ ] Run `pana` locally and aim for full pub points
- [ ] Add screenshots to `pubspec.yaml` (`screenshots:`) and a GIF to the README
- [ ] The `repository`, `issue_tracker` and `documentation` URLs resolve
