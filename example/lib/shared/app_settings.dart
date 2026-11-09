import 'package:flutter/material.dart';

/// App-wide demo settings: theme mode, color, locale and the app-wide
/// picker theme switch.
class AppSettings extends ChangeNotifier {
  /// Locales of the language switcher. These are the languages with bundled
  /// country names.
  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('gu'),
    Locale('he'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('mr'),
    Locale('ms'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sv'),
    Locale('ta'),
    Locale('te'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  Color _seedColor = Colors.indigo;
  bool _useAppWidePickerTheme = false;

  /// Light, dark or system.
  ThemeMode get themeMode => _themeMode;

  /// The selected locale, or `null` for the device locale.
  Locale? get locale => _locale;

  /// Seed color of the app color scheme.
  Color get seedColor => _seedColor;

  /// Whether a `GlobePickerTheme` is set as a theme extension.
  bool get useAppWidePickerTheme => _useAppWidePickerTheme;

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  set locale(Locale? value) {
    _locale = value;
    notifyListeners();
  }

  set seedColor(Color value) {
    _seedColor = value;
    notifyListeners();
  }

  set useAppWidePickerTheme(bool value) {
    _useAppWidePickerTheme = value;
    notifyListeners();
  }
}

/// Makes [AppSettings] available to every page.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    required AppSettings settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()!.notifier!;
}
