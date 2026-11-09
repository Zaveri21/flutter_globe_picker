# flutter_globe_picker example

A gallery app with one page per feature, so you can try everything on a device.

```bash
cd example
flutter run            # or pick a device: flutter run -d <device id>
```

Requires Dart 3.13.7 and Flutter 3.47.8 or newer, like the package. Runs on Android, iOS, web, macOS, Windows and Linux. For iOS, start a simulator first (`open -a Simulator`) so it shows up in `flutter devices`.

`main.dart` loads the data once with `await GlobeData.load()` before `runApp`, because some pages read `GlobeData` directly. Pickers and fields would also load it by themselves.

| Page | What you can try |
|---|---|
| Picker modes | Every picker type as bottom sheet, dialog, full page and iOS sheet; multi-select; the generic `GlobePicker.show` |
| Filters | EU, eurozone and UN presets; country, region, currency and dial code rules; custom `where` rules; combining filters |
| Display options | Live switches for flags, shapes, sections, favorites, recents, title, close button, dividers and check marks; row fields |
| Search | Search fields, minimum characters, debounce, autofocus, no search bar |
| Theming and texts | App colors and dark mode, app-wide `GlobePickerTheme`, a custom theme per picker, translated `GlobeStrings` |
| Custom builders | Every builder: row, header, search bar, section header, separator, empty view, flag, check mark, footer, container |
| Inline view and controller | `GlobePickerView` in a screen, driven by `GlobePickerController` buttons |
| Headless builder | `GlobePickerBuilder` with a fully custom grid UI |
| Form widgets | `GlobePhoneField` variants, `GlobePickerField` for every type, `GlobePickerButton`, form validation and saving |
| Flags | Emoji and SVG flags in every shape and size, plus all 250 flags |
| Localization and RTL | Switch between 30 languages to see translated, re-sorted country and currency names and right-to-left layouts; fix one translation with `translationOverrides`; Hindi picker texts with `GlobeStrings`; reset to the bundled data |
| Data explorer | Every field of a country, money and date formatting, the phone parser and search, with live inputs |

The data the app shows comes from the package's `assets/globe_data.json` and `assets/globe_translations.json`.

Run the smoke tests with `flutter test`.
