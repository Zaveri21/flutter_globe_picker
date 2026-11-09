import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

import '../shared/demo_widgets.dart';

/// Search bar settings.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with ResultState<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Search',
      result: lastResult,
      children: [
        const DemoSection(
          'Default search',
          description:
              'Ignores case, accents and punctuation. Try "cote d iv", '
              '"ivory", "91", "+44" or "IND".',
        ),
        DemoButton(
          label: 'Country picker',
          onPressed: () => showResult(GlobePicker.country(context)),
        ),
        DemoButton(
          label: 'Currency picker: try "germany", "rupee" or "₹"',
          onPressed: () => showResult(GlobePicker.currency(context)),
        ),
        const DemoSection('Settings'),
        DemoButton(
          label: 'Search by capital city only',
          code: "GlobeSearchConfig(fields: [GlobeField.capital], hint: 'Capital city')",
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              search: const GlobeSearchConfig(
                fields: [GlobeField.capital],
                hint: 'Capital city',
              ),
              display: const GlobeDisplay(
                fields: [
                  GlobeField.flag,
                  GlobeField.capital,
                  GlobeField.countryName,
                ],
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'Open with the keyboard',
          code: 'GlobeSearchConfig(autoFocus: true)',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              search: const GlobeSearchConfig(autoFocus: true),
            ),
          ),
        ),
        DemoButton(
          label: 'Start searching after 3 characters',
          code: 'GlobeSearchConfig(minChars: 3)',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              search: const GlobeSearchConfig(minChars: 3),
            ),
          ),
        ),
        DemoButton(
          label: 'Debounce 500 ms',
          code: 'GlobeSearchConfig(debounce: Duration(milliseconds: 500))',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              search: const GlobeSearchConfig(
                debounce: Duration(milliseconds: 500),
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'No search bar',
          code: 'GlobeSearchConfig(enabled: false)',
          onPressed: () => showResult(
            GlobePicker.dateFormat(
              context,
              search: const GlobeSearchConfig(enabled: false),
            ),
          ),
        ),
      ],
    );
  }
}
