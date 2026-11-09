import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

import '../shared/app_settings.dart';
import '../shared/demo_widgets.dart';

/// Switch the app language to see translated, re-sorted names and
/// right-to-left layouts. Also shows how to fix a translation and how to
/// translate the picker texts.
class LocalizationPage extends StatefulWidget {
  const LocalizationPage({super.key});

  @override
  State<LocalizationPage> createState() => _LocalizationPageState();
}

class _LocalizationPageState extends State<LocalizationPage>
    with ResultState<LocalizationPage> {
  static String _localeLabel(Locale locale) => locale.scriptCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.scriptCode}';

  /// Hindi texts for the picker UI.
  static const _hindiStrings = GlobeStrings(
    countryTitle: 'देश चुनें',
    searchHint: 'खोजें',
    noResults: 'कोई परिणाम नहीं',
    close: 'बंद करें',
  );

  /// The bundled data with one translation replaced.
  static const _fixedTranslation = GlobeDataSource(
    translationOverrides: {
      'hi': {
        'countries': {'IN': 'भारत गणराज्य'},
      },
    },
  );

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final currentLocale = Localizations.localeOf(context);
    final india = GlobeData.countryByAlpha2('IN')!;
    return DemoPage(
      title: 'Localization and RTL',
      result: lastResult,
      children: [
        const DemoSection(
          'App language',
          description:
              'Pickers follow Localizations.localeOf(context). Try ar, he, fa '
              'or ur for right-to-left layouts.',
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('device'),
              selected: settings.locale == null,
              onSelected: (_) => settings.locale = null,
            ),
            for (final locale in AppSettings.supportedLocales)
              ChoiceChip(
                label: Text(_localeLabel(locale)),
                selected: settings.locale == locale,
                onSelected: (_) => settings.locale = locale,
              ),
          ],
        ),
        ListTile(
          title: Text('India in ${_localeLabel(currentLocale)}'),
          subtitle: Text(
            '${india.localizedName(currentLocale)} · '
            '${india.currency!.localizedName(currentLocale)}',
          ),
        ),
        ListTile(
          title: const Text('Your country from the locale'),
          subtitle: Text(
            GlobeData.countryFromLocale(currentLocale)
                    ?.localizedName(currentLocale) ??
                'Unknown',
          ),
        ),
        const DemoSection('Pickers in this language'),
        DemoButton(
          label: 'Countries sorted by translated name',
          onPressed: () => showResult(GlobePicker.country(context)),
        ),
        DemoButton(
          label: 'Currencies with translated names',
          onPressed: () => showResult(GlobePicker.currency(context)),
        ),
        DemoButton(
          label: 'A-Z sections in this language',
          onPressed: () => showResult(
            GlobePicker.country(context, groupBy: GlobeGroupBy.alphabet),
          ),
        ),
        DemoButton(
          label: 'English names everywhere',
          code: 'GlobeDisplay(useLocalizedNames: false)',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              display: const GlobeDisplay(useLocalizedNames: false),
            ),
          ),
        ),
        const DemoSection(
          'Change translations',
          description:
              'A data source replaces the data for the whole app until you '
              'reset it. Switch to hi to see the change.',
        ),
        DemoButton(
          label: 'Fix one Hindi name',
          code: "translationOverrides: {'hi': {'countries': {'IN': '...'}}}",
          onPressed: () => showResult(
            GlobePicker.country(context, dataSource: _fixedTranslation),
          ),
        ),
        DemoButton(
          label: 'Picker texts in Hindi',
          code: 'GlobePicker.country(context, strings: hindiStrings)',
          onPressed: () =>
              showResult(GlobePicker.country(context, strings: _hindiStrings)),
        ),
        DemoButton(
          label: 'Reset to the bundled data',
          code: 'GlobeData.ensureLoaded(GlobeDataSource.bundled)',
          onPressed: () async {
            await GlobeData.ensureLoaded(GlobeDataSource.bundled);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}
