# Contributing to flutter_globe_picker

Thanks for helping. This guide covers the setup, how the code and data are organized, and the checks every pull request must pass.

## Setup

```bash
git clone https://github.com/Zaveri21/flutter_globe_picker.git
cd flutter_globe_picker
git config core.hooksPath .githooks   # once: enables the pre-commit checks
flutter pub get
flutter test
cd example && flutter run
```

Requires Dart 3.13.7 and Flutter 3.47.8 or newer.

The pre-commit hook in `.githooks/pre-commit` runs the format check, `flutter analyze` and the tests of the package and the example before every commit. There is no CI workflow: the hook is the gate.

## Project structure

```
flutter_globe_picker/
├── lib/
│   ├── flutter_globe_picker.dart   # the only public import: data and widgets
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
├── example/                        # demo app with every feature
└── test/                           # unit and widget tests
```

## The data

All data lives in two readable JSON files in `assets/`, which the package ships and loads at runtime (there is no generated code):

- `assets/globe_data.json`: every country and every currency.
- `assets/globe_translations.json`: their names in 29 languages, linked to the data by alpha-2 and currency code.
- `assets/flags/4x3/*.svg` and `assets/flags/1x1/*.svg`: the flags.

They were built from these sources, whose versions are listed under `sources` in `globe_data.json`:

| Data | Source |
|---|---|
| Names, ISO codes, regions, currencies, symbols, date and number formats, translations | Unicode CLDR |
| Dial codes, phone lengths, patterns, examples | Google libphonenumber `PhoneNumberMetadata.xml` |
| Time zones | IANA tz `zone.tab` |
| SVG flags and capitals | flag-icons |

### Fixing data

Edit the JSON files directly. The README's Data section describes every field.

- Keep both files sorted as they are (countries by alpha-2 code, currencies by code) and keep the existing formatting, so diffs stay readable.
- A country or currency you add needs every required field in `globe_data.json` and a name in every language of `globe_translations.json`. The tests check both.
- Run `flutter test`: `test/data/data_integrity_test.dart` and `test/data/loading_test.dart` check codes, links, phone patterns and example numbers, and translations.
- In the pull request, link the source that proves the correction (CLDR, libphonenumber, ISO, ITU).

When a source publishes a new release (libphonenumber does several times a year), apply its changes to the JSON the same way, and update the version under `sources` and in `README.md`, `NOTICE` and `CHANGELOG.md`.

## Code style

- Run `dart format lib test example/lib example/test` before committing (the hook checks it).
- `flutter analyze` must report no issues. The rules in `analysis_options.yaml` include strict casts, strict inference and `public_member_api_docs`.
- Use meaningful names. No single-letter variables, including in lambdas (`(country) => country.name`, not `(c) => c.name`) and comparators (`(first, second)`).
- Every public class, method and field needs a `///` doc comment, ideally with a short example.
- Keep the public API exported only from `lib/flutter_globe_picker.dart`.
- Inside `lib/`, import with full `package:flutter_globe_picker/...` paths (enforced by `always_use_package_imports`).
- Do not add dependencies. The package depends only on Flutter and `flutter_svg`.

## Tests

```bash
flutter test
```

- Data changes are covered by `test/data/data_integrity_test.dart`: unique codes, links between models, valid example phone numbers. `test/data/loading_test.dart` covers loading, overrides and translations (every language names every country and currency).
- New features need unit tests, and widget tests when they add UI.
- Every bundled SVG flag must parse with flutter_svg (`test/widgets/svg_flags_test.dart`).

## Screenshots

The README and pub.dev screenshots in `screenshots/` are taken from the example app by `example/integration_test/screenshots_test.dart`. Start an Android emulator and an iOS simulator, then for each device:

```bash
cd example
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart -d <device id>
```

This writes `screenshots/<platform>_<name>.png` at full size. Shrink them to 400 px wide JPEG files (macOS):

```bash
cd screenshots
for file in *.png; do
  sips --resampleWidth 400 -s format jpeg -s formatOptions 85 "$file" --out "${file%.png}.jpg" && rm "$file"
done
```

The README shows six of them and `pubspec.yaml` lists four under `screenshots:`.

## Pull request checklist

- [ ] The pre-commit hook passes (format, analyze, package and example tests)
- [ ] Data corrections keep `assets/` formatting and sorting
- [ ] Public API changes are documented in `README.md` and `CHANGELOG.md`
- [ ] Data corrections link their source

## Before publishing a release

- [ ] Bump `version` in `pubspec.yaml` and add a `CHANGELOG.md` entry
- [ ] `dart pub publish --dry-run` shows no warnings
- [ ] Run `pana` locally and aim for full pub points
- [ ] Screenshots are up to date (see [Screenshots](#screenshots))
- [ ] The `repository`, `issue_tracker` and `documentation` URLs resolve
