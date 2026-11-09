import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

import '../shared/demo_widgets.dart';

/// Every GlobeFilter rule, the presets and combining filters.
class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage>
    with ResultState<FiltersPage> {
  /// One filter shared by every picker type.
  static const _sharedFilter = GlobeFilter(
    excludeCountries: ['AQ', 'BV', 'HM'],
    regions: [GlobeRegion.asia, GlobeRegion.europe],
  );

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Filters',
      result: lastResult,
      children: [
        const DemoSection('Presets'),
        DemoButton(
          label: 'European Union (27)',
          code: 'filter: GlobeFilter.europeanUnion',
          onPressed: () => showResult(
            GlobePicker.country(context, filter: GlobeFilter.europeanUnion),
          ),
        ),
        DemoButton(
          label: 'Eurozone (21)',
          code: 'filter: GlobeFilter.eurozone',
          onPressed: () => showResult(
            GlobePicker.country(context, filter: GlobeFilter.eurozone),
          ),
        ),
        DemoButton(
          label: 'UN members (193)',
          code: 'filter: GlobeFilter.unMembers',
          onPressed: () => showResult(
            GlobePicker.country(context, filter: GlobeFilter.unMembers),
          ),
        ),
        const DemoSection('Country rules (apply to every type)'),
        DemoButton(
          label: 'Only India, US, UK, Japan',
          code: "GlobeFilter(countries: ['IN', 'US', 'GB', 'JP'])",
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              filter: const GlobeFilter(countries: ['IN', 'US', 'GB', 'JP']),
            ),
          ),
        ),
        DemoButton(
          label: 'Africa and Oceania only',
          code:
              'GlobeFilter(regions: [GlobeRegion.africa, GlobeRegion.oceania])',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              filter: const GlobeFilter(
                regions: [GlobeRegion.africa, GlobeRegion.oceania],
              ),
              groupBy: GlobeGroupBy.region,
            ),
          ),
        ),
        DemoButton(
          label: 'Custom rule: countries with more than one currency',
          code:
              'GlobeFilter(where: (country) => country.currencies.length > 1)',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              filter: GlobeFilter(
                where: (country) => country.currencies.length > 1,
              ),
              display: const GlobeDisplay(
                fields: [
                  GlobeField.flag,
                  GlobeField.countryName,
                  GlobeField.currencyCode,
                ],
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'Same country rule on the currency picker',
          code: "GlobeFilter(countries: ['IN', 'US', 'GB', 'JP'])",
          onPressed: () => showResult(
            GlobePicker.currency(
              context,
              filter: const GlobeFilter(countries: ['IN', 'US', 'GB', 'JP']),
            ),
          ),
        ),
        const DemoSection(
          'Currency and dial code rules',
          description: 'These only filter their own picker type.',
        ),
        DemoButton(
          label: 'Major currencies only',
          code: "GlobeFilter(currencies: ['USD', 'EUR', 'GBP', 'JPY', 'INR'])",
          onPressed: () => showResult(
            GlobePicker.currency(
              context,
              filter: const GlobeFilter(
                currencies: ['USD', 'EUR', 'GBP', 'JPY', 'INR'],
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'Dial codes without +1 and +7',
          code: "GlobeFilter(excludeDialCodes: ['+1', '7'])",
          onPressed: () => showResult(
            GlobePicker.dialCode(
              context,
              filter: const GlobeFilter(excludeDialCodes: ['+1', '7']),
            ),
          ),
        ),
        const DemoSection(
          'One filter for every picker',
          description: 'Asia and Europe, without AQ, BV and HM.',
        ),
        DemoButton(
          label: 'Countries',
          onPressed: () =>
              showResult(GlobePicker.country(context, filter: _sharedFilter)),
        ),
        DemoButton(
          label: 'Currencies',
          onPressed: () =>
              showResult(GlobePicker.currency(context, filter: _sharedFilter)),
        ),
        DemoButton(
          label: 'Dial codes',
          onPressed: () =>
              showResult(GlobePicker.dialCode(context, filter: _sharedFilter)),
        ),
        DemoButton(
          label: 'Date formats',
          onPressed: () => showResult(
            GlobePicker.dateFormat(context, filter: _sharedFilter),
          ),
        ),
        const DemoSection('Combining filters'),
        DemoButton(
          label: 'Shared filter + UN members only',
          code: '_sharedFilter + GlobeFilter.unMembers',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              filter: _sharedFilter + GlobeFilter.unMembers,
            ),
          ),
        ),
        DemoButton(
          label: 'Shared filter, but Asia only',
          code: '_sharedFilter.copyWith(regions: [GlobeRegion.asia])',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              filter: _sharedFilter.copyWith(regions: [GlobeRegion.asia]),
            ),
          ),
        ),
      ],
    );
  }
}
