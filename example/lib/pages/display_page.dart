import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

import '../shared/demo_widgets.dart';

/// Row content, flags, grouping, favorites, recents and visible parts, with
/// live switches.
class DisplayPage extends StatefulWidget {
  const DisplayPage({super.key});

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage>
    with ResultState<DisplayPage> {
  GlobeFlagType _flagType = GlobeFlagType.auto;
  GlobeFlagShape _flagShape = GlobeFlagShape.rectangle;
  GlobeGroupBy _groupBy = GlobeGroupBy.none;
  bool _showTitle = true;
  bool _showCloseButton = true;
  bool _showDragHandle = true;
  bool _showDividers = false;
  bool _showSelectedIndicator = true;
  bool _showSectionHeaders = true;
  bool _showFavorites = true;
  bool _showRecents = true;

  GlobeDisplay get _display => GlobeDisplay(
    flagType: _flagType,
    flagShape: _flagShape,
    showTitle: _showTitle,
    showCloseButton: _showCloseButton,
    showDragHandle: _showDragHandle,
    showDividers: _showDividers,
    showSelectedIndicator: _showSelectedIndicator,
    showSectionHeaders: _showSectionHeaders,
  );

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Display options',
      result: lastResult,
      children: [
        const DemoSection('Try your settings'),
        DemoButton(
          label: 'Open a country picker with the settings below',
          code: 'GlobePicker.country(context, display: GlobeDisplay(...))',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              display: _display,
              groupBy: _groupBy,
              favorites: _showFavorites ? const ['IN', 'US', 'GB'] : const [],
              showRecents: _showRecents,
              selected: 'IN',
            ),
          ),
        ),
        const DemoSection('Flags'),
        SegmentedButton<GlobeFlagType>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: GlobeFlagType.auto, label: Text('Auto')),
            ButtonSegment(value: GlobeFlagType.emoji, label: Text('Emoji')),
            ButtonSegment(value: GlobeFlagType.svg, label: Text('SVG')),
          ],
          selected: {_flagType},
          onSelectionChanged: (types) =>
              setState(() => _flagType = types.first),
        ),
        const SizedBox(height: 8),
        SegmentedButton<GlobeFlagShape>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: GlobeFlagShape.rectangle,
              label: Text('Rectangle'),
            ),
            ButtonSegment(value: GlobeFlagShape.square, label: Text('Square')),
            ButtonSegment(value: GlobeFlagShape.circle, label: Text('Circle')),
          ],
          selected: {_flagShape},
          onSelectionChanged: (shapes) =>
              setState(() => _flagShape = shapes.first),
        ),
        const DemoSection('Sections'),
        SegmentedButton<GlobeGroupBy>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: GlobeGroupBy.none, label: Text('None')),
            ButtonSegment(value: GlobeGroupBy.alphabet, label: Text('A-Z')),
            ButtonSegment(value: GlobeGroupBy.region, label: Text('Region')),
          ],
          selected: {_groupBy},
          onSelectionChanged: (groups) =>
              setState(() => _groupBy = groups.first),
        ),
        SwitchListTile(
          title: const Text('Favorites (IN, US, GB)'),
          value: _showFavorites,
          onChanged: (value) => setState(() => _showFavorites = value),
        ),
        SwitchListTile(
          title: const Text('Recently selected'),
          subtitle: const Text('Pick a few countries to fill it'),
          value: _showRecents,
          onChanged: (value) => setState(() => _showRecents = value),
        ),
        SwitchListTile(
          title: const Text('Section headers'),
          value: _showSectionHeaders,
          onChanged: (value) => setState(() => _showSectionHeaders = value),
        ),
        const DemoSection('Visible parts'),
        SwitchListTile(
          title: const Text('Title'),
          value: _showTitle,
          onChanged: (value) => setState(() => _showTitle = value),
        ),
        SwitchListTile(
          title: const Text('Close button'),
          value: _showCloseButton,
          onChanged: (value) => setState(() => _showCloseButton = value),
        ),
        SwitchListTile(
          title: const Text('Drag handle (bottom sheet)'),
          value: _showDragHandle,
          onChanged: (value) => setState(() => _showDragHandle = value),
        ),
        SwitchListTile(
          title: const Text('Dividers'),
          value: _showDividers,
          onChanged: (value) => setState(() => _showDividers = value),
        ),
        SwitchListTile(
          title: const Text('Selected check mark'),
          value: _showSelectedIndicator,
          onChanged: (value) => setState(() => _showSelectedIndicator = value),
        ),
        const DemoSection(
          'Row fields',
          description:
              'The first text field is the title, the rest the subtitle. '
              'Trailing fields appear at the end of the row.',
        ),
        DemoButton(
          label: 'Country with ISO codes and capital',
          code:
              'fields: [flag, countryName, alpha3Code, capital], '
              'trailingFields: [dialCode]',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              display: _display.copyWith(
                fields: [
                  GlobeField.flag,
                  GlobeField.countryName,
                  GlobeField.alpha3Code,
                  GlobeField.capital,
                ],
                trailingFields: [GlobeField.dialCode],
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'Country with currency and date format',
          code:
              'fields: [flag, countryName, currencyName], '
              'trailingFields: [currencySymbol, dateExample]',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              display: _display.copyWith(
                fields: [
                  GlobeField.flag,
                  GlobeField.countryName,
                  GlobeField.currencyName,
                ],
                trailingFields: [
                  GlobeField.currencySymbol,
                  GlobeField.dateExample,
                ],
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'Currency with countries and numeric code',
          code:
              'fields: [flag, currencyCode, countryName], '
              'trailingFields: [numCode]',
          onPressed: () => showResult(
            GlobePicker.currency(
              context,
              display: _display.copyWith(
                fields: [
                  GlobeField.flag,
                  GlobeField.currencyCode,
                  GlobeField.countryName,
                ],
                trailingFields: [GlobeField.numCode],
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'Dial code with region',
          code: 'fields: [flag, dialCode, countryName, region]',
          onPressed: () => showResult(
            GlobePicker.dialCode(
              context,
              display: _display.copyWith(
                fields: [
                  GlobeField.flag,
                  GlobeField.dialCode,
                  GlobeField.countryName,
                  GlobeField.region,
                ],
                trailingFields: const [],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
