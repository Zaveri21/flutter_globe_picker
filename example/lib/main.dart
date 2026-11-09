import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/builders_page.dart';
import 'pages/data_explorer_page.dart';
import 'pages/display_page.dart';
import 'pages/filters_page.dart';
import 'pages/flags_page.dart';
import 'pages/forms_page.dart';
import 'pages/headless_page.dart';
import 'pages/inline_page.dart';
import 'pages/localization_page.dart';
import 'pages/picker_modes_page.dart';
import 'pages/search_page.dart';
import 'pages/theming_page.dart';
import 'shared/app_settings.dart';

Future<void> main() async {
  // Pickers load the data by themselves. Loading it up front makes it ready
  // for the pages that read GlobeData directly.
  WidgetsFlutterBinding.ensureInitialized();
  await GlobeData.load();
  runApp(const GlobePickerExampleApp());
}

/// Gallery of every flutter_globe_picker widget and use case.
class GlobePickerExampleApp extends StatefulWidget {
  const GlobePickerExampleApp({super.key});

  @override
  State<GlobePickerExampleApp> createState() => _GlobePickerExampleAppState();
}

class _GlobePickerExampleAppState extends State<GlobePickerExampleApp> {
  final _settings = AppSettings();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => MaterialApp(
          title: 'flutter_globe_picker',
          debugShowCheckedModeBanner: false,
          themeMode: _settings.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          locale: _settings.locale,
          supportedLocales: AppSettings.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const GalleryHomePage(),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) => ThemeData(
    colorSchemeSeed: _settings.seedColor,
    brightness: brightness,
    // An app-wide picker theme: every picker in the app uses it.
    extensions: [
      if (_settings.useAppWidePickerTheme)
        const GlobePickerTheme(borderRadius: 12, flagBorderRadius: 2),
    ],
  );
}

/// One entry of the gallery.
class _GalleryEntry {
  const _GalleryEntry(this.title, this.subtitle, this.icon, this.pageBuilder);

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder pageBuilder;
}

final _galleryEntries = <_GalleryEntry>[
  _GalleryEntry(
    'Picker modes',
    'Bottom sheet, dialog, full page, Cupertino, multi-select, generic show',
    Icons.open_in_new,
    (context) => const PickerModesPage(),
  ),
  _GalleryEntry(
    'Filters',
    'Presets, regions, include / exclude, custom rules, combining',
    Icons.filter_alt_outlined,
    (context) => const FiltersPage(),
  ),
  _GalleryEntry(
    'Display options',
    'Row fields, flags, grouping, favorites, recents, visible parts',
    Icons.view_list_outlined,
    (context) => const DisplayPage(),
  ),
  _GalleryEntry(
    'Search',
    'Hidden search, fields, minimum characters, debounce, autofocus',
    Icons.search,
    (context) => const SearchPage(),
  ),
  _GalleryEntry(
    'Theming and texts',
    'GlobePickerTheme, app-wide ThemeExtension, GlobeStrings',
    Icons.palette_outlined,
    (context) => const ThemingPage(),
  ),
  _GalleryEntry(
    'Custom builders',
    'Replace each part: row, header, search bar, empty view, footer...',
    Icons.build_outlined,
    (context) => const BuildersPage(),
  ),
  _GalleryEntry(
    'Inline view and controller',
    'GlobePickerView in a screen, driven by GlobePickerController',
    Icons.tune,
    (context) => const InlinePage(),
  ),
  _GalleryEntry(
    'Headless builder',
    'GlobePickerBuilder: your own grid and chips UI',
    Icons.dashboard_customize_outlined,
    (context) => const HeadlessPage(),
  ),
  _GalleryEntry(
    'Form widgets',
    'GlobePhoneField, GlobePickerField, GlobePickerButton in a Form',
    Icons.edit_note,
    (context) => const FormsPage(),
  ),
  _GalleryEntry(
    'Flags',
    'Emoji and SVG, rectangle, square and circle, every size',
    Icons.flag_outlined,
    (context) => const FlagsPage(),
  ),
  _GalleryEntry(
    'Localization and RTL',
    'Country names in 30 languages, right-to-left layouts',
    Icons.translate,
    (context) => const LocalizationPage(),
  ),
  _GalleryEntry(
    'Data explorer',
    'GlobeData: linked models, phone parser, date and money formatting',
    Icons.data_object,
    (context) => const DataExplorerPage(),
  ),
];

/// The list of demo pages, plus app-wide settings.
class GalleryHomePage extends StatelessWidget {
  const GalleryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_globe_picker'),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(
              settings.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: settings.toggleThemeMode,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final entry in _galleryEntries)
            ListTile(
              leading: Icon(entry.icon),
              title: Text(entry.title),
              subtitle: Text(entry.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: entry.pageBuilder)),
            ),
        ],
      ),
    );
  }
}
