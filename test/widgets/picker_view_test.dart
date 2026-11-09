import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows title, search and the list', (tester) async {
    await tester.pumpWidget(
      _host(const GlobePickerView(type: GlobePickerType.country)),
    );
    expect(find.text('Select country'), findsOneWidget);
    expect(find.byType(GlobeSearchBar), findsOneWidget);
    expect(find.text('Afghanistan'), findsOneWidget);
    expect(find.byTooltip('Close'), findsNothing);
  });

  testWidgets('search narrows the list and tap selects', (tester) async {
    GlobeCountry? selected;
    await tester.pumpWidget(
      _host(
        GlobePickerView(
          type: GlobePickerType.country,
          onSelected: (country) => selected = country,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'india');
    await tester.pump();
    expect(find.text('Afghanistan'), findsNothing);
    await tester.tap(find.text('India'));
    await tester.pump();
    expect(selected?.alpha2Code, 'IN');
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('clear button resets the search', (tester) async {
    await tester.pumpWidget(
      _host(const GlobePickerView(type: GlobePickerType.country)),
    );
    await tester.enterText(find.byType(TextField), 'india');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Afghanistan'), findsOneWidget);
  });

  testWidgets('debounced search waits for the delay', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.country,
          options: GlobePickerOptions(
            search: GlobeSearchConfig(debounce: Duration(milliseconds: 300)),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'japan');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Afghanistan'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Afghanistan'), findsNothing);
    expect(find.text('Japan'), findsOneWidget);
  });

  testWidgets('minChars keeps the full list for short queries', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.country,
          options: GlobePickerOptions(search: GlobeSearchConfig(minChars: 3)),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'ja');
    await tester.pump();
    expect(find.text('Afghanistan'), findsOneWidget);
  });

  testWidgets('shows the empty view', (tester) async {
    await tester.pumpWidget(
      _host(const GlobePickerView(type: GlobePickerType.currency)),
    );
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('No results found'), findsOneWidget);
  });

  testWidgets('favorites and grouping sections', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.country,
          options: GlobePickerOptions(
            favorites: ['IN', 'us', 'ZZ'],
            groupBy: GlobeGroupBy.alphabet,
          ),
        ),
      ),
    );
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('region grouping and hidden headers', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.country,
          options: GlobePickerOptions(groupBy: GlobeGroupBy.region),
        ),
      ),
    );
    expect(find.text('Africa'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.country,
          options: GlobePickerOptions(
            groupBy: GlobeGroupBy.region,
            display: GlobeDisplay(showSectionHeaders: false, showTitle: false),
          ),
        ),
      ),
    );
    expect(find.text('Africa'), findsNothing);
    expect(find.text('Select country'), findsNothing);
  });

  testWidgets('filter and custom items', (tester) async {
    await tester.pumpWidget(
      _host(
        GlobePickerView(
          type: GlobePickerType.currency,
          items: [
            GlobeData.currencyByCode('USD')!,
            GlobeData.currencyByCode('EUR')!,
            GlobeData.currencyByCode('INR')!,
          ],
          options: const GlobePickerOptions(
            filter: GlobeFilter(excludeCurrencies: ['USD']),
          ),
        ),
      ),
    );
    expect(find.text('Euro'), findsOneWidget);
    expect(find.text('Indian Rupee'), findsOneWidget);
    expect(find.text('US Dollar'), findsNothing);
  });

  testWidgets('row fields and trailing fields', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.country,
          options: GlobePickerOptions(
            filter: GlobeFilter(countries: ['IN']),
            display: GlobeDisplay(
              fields: [
                GlobeField.flag,
                GlobeField.countryName,
                GlobeField.alpha3Code,
                GlobeField.capital,
              ],
              trailingFields: [GlobeField.dialCode],
              flagType: GlobeFlagType.emoji,
            ),
          ),
        ),
      ),
    );
    expect(find.text('India'), findsOneWidget);
    expect(find.text('IND · New Delhi'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('🇮🇳'), findsOneWidget);
  });

  testWidgets('dial code rows format NANP codes', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.dialCode,
          options: GlobePickerOptions(
            filter: GlobeFilter(dialCodes: ['+1876']),
          ),
        ),
      ),
    );
    expect(find.text('Jamaica'), findsOneWidget);
    expect(find.text('+1 876'), findsOneWidget);
  });

  testWidgets('date format rows show an example date', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.dateFormat,
          options: GlobePickerOptions(filter: GlobeFilter(countries: ['US'])),
        ),
      ),
    );
    expect(find.text('MM/dd/yyyy'), findsOneWidget);
  });

  testWidgets('multi-select confirms the selection', (tester) async {
    List<GlobeCountry>? confirmed;
    await tester.pumpWidget(
      _host(
        GlobePickerView(
          type: GlobePickerType.country,
          multiSelect: true,
          selected: const ['IN'],
          options: const GlobePickerOptions(
            filter: GlobeFilter(countries: ['IN', 'US', 'FR']),
          ),
          onConfirm: (countries) => confirmed = countries,
        ),
      ),
    );
    expect(find.text('Done (1)'), findsOneWidget);
    await tester.tap(find.text('France'));
    await tester.pump();
    await tester.tap(find.text('India'));
    await tester.pump();
    await tester.tap(find.text('United States'));
    await tester.pump();
    await tester.tap(find.text('Done (2)'));
    expect(confirmed?.map((country) => country.alpha2Code), ['FR', 'US']);
  });

  testWidgets('external controller drives search and selection', (
    tester,
  ) async {
    final controller = GlobePickerController<GlobeCountry>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        GlobePickerView(type: GlobePickerType.country, controller: controller),
      ),
    );
    controller.search('japan');
    await tester.pump();
    expect(find.text('Japan'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'japan',
    );
    controller.select(GlobeData.countryByAlpha2('JP')!);
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('every builder can replace its part', (tester) async {
    await tester.pumpWidget(
      _host(
        GlobePickerView<GlobeCurrency>(
          type: GlobePickerType.currency,
          multiSelect: true,
          options: const GlobePickerOptions(
            filter: GlobeFilter(currencies: ['EUR', 'INR']),
            display: GlobeDisplay(showDividers: true),
          ),
          builders: GlobePickerBuilders(
            headerBuilder: (context, snapshot) =>
                Text('header ${snapshot.items.length}'),
            searchBarBuilder: (context, controller, onChanged) =>
                TextField(key: const Key('search'), onChanged: onChanged),
            itemBuilder: (context, currency, isSelected, onTap) => ListTile(
              title: Text('item ${currency.code} $isSelected'),
              onTap: onTap,
            ),
            separatorBuilder: (context) => const Text('separator'),
            emptyBuilder: (context, query) => Text('nothing for $query'),
            footerBuilder: (context, snapshot) =>
                Text('footer ${snapshot.selection.length}'),
            containerBuilder: (context, child) => ColoredBox(
              key: const Key('container'),
              color: Colors.red,
              child: child,
            ),
          ),
        ),
      ),
    );
    expect(find.text('header 2'), findsOneWidget);
    expect(find.text('item EUR false'), findsOneWidget);
    expect(find.text('separator'), findsOneWidget);
    expect(find.text('footer 0'), findsOneWidget);
    expect(find.byKey(const Key('container')), findsOneWidget);
    await tester.tap(find.text('item EUR false'));
    await tester.pump();
    expect(find.text('item EUR true'), findsOneWidget);
    expect(find.text('footer 1'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('search')), 'qqq');
    await tester.pump();
    expect(find.text('nothing for qqq'), findsOneWidget);
  });

  testWidgets('GlobePickerBuilder is fully headless', (tester) async {
    GlobeCountry? selected;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fr'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GlobePickerBuilder(
            type: GlobePickerType.country,
            options: const GlobePickerOptions(
              filter: GlobeFilter(countries: ['DE', 'IN']),
            ),
            onSelected: (country) => selected = country,
            builder: (context, snapshot) => Column(
              children: [
                for (final country in snapshot.items)
                  GestureDetector(
                    onTap: () => snapshot.onItemTap(country),
                    child: Text(country.name),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final names = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(names, ['Germany', 'India']);
    await tester.tap(find.text('India'));
    expect(selected?.alpha2Code, 'IN');
  });

  testWidgets('theme extension and options theme are applied', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            GlobePickerTheme(titleStyle: TextStyle(fontSize: 31)),
          ],
        ),
        home: const Scaffold(
          body: GlobePickerView(
            type: GlobePickerType.country,
            options: GlobePickerOptions(
              title: 'Pick one',
              theme: GlobePickerTheme(
                titleStyle: TextStyle(color: Color(0xFF123456)),
              ),
            ),
          ),
        ),
      ),
    );
    final title = tester.widget<Text>(find.text('Pick one'));
    expect(title.style?.fontSize, 31);
    expect(title.style?.color, const Color(0xFF123456));
  });

  testWidgets('custom strings', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlobePickerView(
          type: GlobePickerType.currency,
          options: GlobePickerOptions(
            strings: GlobeStrings(
              currencyTitle: 'Moneda',
              searchHint: 'Buscar',
              noResults: 'Nada',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Moneda'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('Nada'), findsOneWidget);
  });
}
