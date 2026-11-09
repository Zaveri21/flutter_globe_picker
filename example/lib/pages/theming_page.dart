import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

import '../shared/app_settings.dart';
import '../shared/demo_widgets.dart';

/// GlobePickerTheme per picker and app-wide, app colors, and GlobeStrings.
class ThemingPage extends StatefulWidget {
  const ThemingPage({super.key});

  @override
  State<ThemingPage> createState() => _ThemingPageState();
}

class _ThemingPageState extends State<ThemingPage>
    with ResultState<ThemingPage> {
  static const _seedColors = {
    'Indigo': Colors.indigo,
    'Teal': Colors.teal,
    'Orange': Colors.deepOrange,
    'Pink': Colors.pink,
  };

  static const _spanishStrings = GlobeStrings(
    countryTitle: 'Selecciona un país',
    currencyTitle: 'Selecciona una moneda',
    searchHint: 'Buscar',
    noResults: 'Sin resultados',
    favorites: 'Favoritos',
    allItems: 'Todos',
    close: 'Cerrar',
    done: 'Listo',
  );

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return DemoPage(
      title: 'Theming and texts',
      result: lastResult,
      children: [
        const DemoSection(
          'App colors',
          description:
              'With no theme set, pickers use your ColorScheme. Change the '
              'seed color or dark mode and open a picker.',
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in _seedColors.entries)
              ChoiceChip(
                label: Text(entry.key),
                selected: settings.seedColor == entry.value,
                onSelected: (_) => settings.seedColor = entry.value,
              ),
          ],
        ),
        SwitchListTile(
          title: const Text('Dark mode'),
          value: Theme.of(context).brightness == Brightness.dark,
          onChanged: (_) => settings.toggleThemeMode(),
        ),
        DemoButton(
          label: 'Open with app colors',
          onPressed: () => showResult(GlobePicker.country(context)),
        ),
        const DemoSection(
          'App-wide picker theme',
          description:
              'A GlobePickerTheme in ThemeData.extensions styles every picker '
              'in the app.',
        ),
        SwitchListTile(
          title: const Text('Use app-wide GlobePickerTheme'),
          subtitle: const Text(
            'ThemeData(extensions: [GlobePickerTheme(borderRadius: 12)])',
          ),
          value: settings.useAppWidePickerTheme,
          onChanged: (value) => settings.useAppWidePickerTheme = value,
        ),
        DemoButton(
          label: 'Open a dialog picker',
          onPressed: () => showResult(
            GlobePicker.currency(context, mode: GlobePickerMode.dialog),
          ),
        ),
        const DemoSection(
          'Theme for one picker',
          description: 'Merged over the app-wide theme.',
        ),
        DemoButton(
          label: 'Rounded, tall, custom colors and text',
          code: 'theme: GlobePickerTheme(borderRadius: 32, heightFactor: 0.95, ...)',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              theme: GlobePickerTheme(
                borderRadius: 32,
                heightFactor: 0.95,
                backgroundColor: Colors.amber.shade50,
                handleColor: Colors.amber.shade700,
                titleStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.brown,
                ),
                itemTitleStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.brown,
                ),
                itemTrailingStyle: const TextStyle(color: Colors.brown),
                selectedTileColor: Colors.amber.shade200,
                selectedIconColor: Colors.brown,
                sectionHeaderStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
                flagWidth: 40,
                flagHeight: 28,
                flagBorderRadius: 8,
              ),
              display: const GlobeDisplay(
                trailingFields: [GlobeField.dialCode],
              ),
              groupBy: GlobeGroupBy.alphabet,
              selected: 'IN',
            ),
          ),
        ),
        DemoButton(
          label: 'Square search bar with a border',
          code:
              'theme: GlobePickerTheme(searchDecoration: InputDecoration(...))',
          onPressed: () => showResult(
            GlobePicker.currency(
              context,
              theme: const GlobePickerTheme(
                searchDecoration: InputDecoration(
                  filled: false,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.travel_explore),
                ),
                dividerColor: Colors.grey,
              ),
              display: const GlobeDisplay(showDividers: true),
            ),
          ),
        ),
        DemoButton(
          label: 'Compact dialog',
          code: 'theme: GlobePickerTheme(dialogMaxWidth: 360, ...)',
          onPressed: () => showResult(
            GlobePicker.dialCode(
              context,
              mode: GlobePickerMode.dialog,
              theme: const GlobePickerTheme(
                dialogMaxWidth: 360,
                dialogMaxHeightFactor: 0.6,
                borderRadius: 8,
                itemPadding: EdgeInsetsDirectional.only(start: 12, end: 12),
              ),
            ),
          ),
        ),
        const DemoSection(
          'Texts',
          description: 'Every text can be replaced with GlobeStrings.',
        ),
        DemoButton(
          label: 'Spanish texts',
          code:
              "strings: GlobeStrings(countryTitle: 'Selecciona un país', ...)",
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              strings: _spanishStrings,
              favorites: const ['ES', 'MX', 'AR'],
            ),
          ),
        ),
        DemoButton(
          label: 'Spanish multi-select with a custom count',
          code: "selectedCount: (done, count) => '\$done · \$count'",
          onPressed: () => showResult(
            GlobePicker.currencies(
              context,
              strings: _spanishStrings.copyWith(
                selectedCount: (done, count) => '$done · $count',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
