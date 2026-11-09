import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps an app with one button that runs [open] and stores its result.
Future<void> _pumpLauncher(
  WidgetTester tester,
  Future<Object?> Function(BuildContext context) open,
  void Function(Object? result) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => onResult(await open(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(GlobeRecents.instance.clear);

  test('restored recents are canonical and unique', () {
    final recents = GlobeRecents.instance
      ..restore(GlobePickerType.country, ['in', 'IN', 'xx', 'jp']);
    expect(recents.idsFor(GlobePickerType.country), ['IN', 'JP']);
    recents.record(GlobePickerType.country, GlobeData.countryByAlpha2('JP')!);
    expect(
      [
        for (final country in recents.itemsFor(GlobePickerType.country))
          country.id,
      ],
      ['JP', 'IN'],
    );
  });

  for (final mode in GlobePickerMode.values) {
    testWidgets('${mode.name} returns the tapped item', (tester) async {
      Object? result = 'not set';
      await _pumpLauncher(
        tester,
        (context) => GlobePicker.currency(
          context,
          mode: mode,
          filter: const GlobeFilter(currencies: ['EUR', 'INR', 'USD']),
        ),
        (value) => result = value,
      );
      expect(find.text('Select currency'), findsOneWidget);
      await tester.tap(find.text('Euro'));
      await tester.pumpAndSettle();
      expect(result, isA<GlobeCurrency>());
      expect((result! as GlobeCurrency).code, 'EUR');
      expect(find.text('Select currency'), findsNothing);
      expect(GlobeRecents.instance.idsFor(GlobePickerType.currency), ['EUR']);
    });
  }

  testWidgets('close button returns null', (tester) async {
    Object? result = 'not set';
    await _pumpLauncher(
      tester,
      (context) => GlobePicker.country(context, mode: GlobePickerMode.dialog),
      (value) => result = value,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('show preselects an item and shows recents', (tester) async {
    GlobeRecents.instance.restore(GlobePickerType.country, ['JP']);
    await _pumpLauncher(
      tester,
      (context) => GlobePicker.show(
        context,
        type: GlobePickerType.country,
        selected: 'IN',
        showRecents: true,
        favorites: const ['IN'],
      ),
      (_) {},
    );
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('showMultiple returns the confirmed items', (tester) async {
    Object? result = 'not set';
    await _pumpLauncher(
      tester,
      (context) => GlobePicker.countries(
        context,
        selected: const ['IN'],
        filter: const GlobeFilter(countries: ['IN', 'US', 'FR']),
      ),
      (value) => result = value,
    );
    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done (2)'));
    await tester.pumpAndSettle();
    expect(
      (result! as List<GlobeCountry>).map((country) => country.alpha2Code),
      ['IN', 'FR'],
    );
  });

  testWidgets('showMultiple dismissed returns null', (tester) async {
    Object? result = 'not set';
    await _pumpLauncher(
      tester,
      GlobePicker.currencies,
      (value) => result = value,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('shortcuts infer typed builders', (tester) async {
    await _pumpLauncher(
      tester,
      (context) => GlobePicker.currency(
        context,
        filter: const GlobeFilter(currencies: ['INR']),
        builders: GlobePickerBuilders(
          itemBuilder: (context, currency, isSelected, onTap) => ListTile(
            title: Text('${currency.code} ${currency.symbol}'),
            onTap: onTap,
          ),
        ),
      ),
      (_) {},
    );
    expect(find.text('INR ₹'), findsOneWidget);
  });

  testWidgets('dial code and date format shortcuts', (tester) async {
    Object? result;
    await _pumpLauncher(
      tester,
      (context) => GlobePicker.dialCode(
        context,
        filter: const GlobeFilter(dialCodes: ['+91']),
      ),
      (value) => result = value,
    );
    await tester.tap(find.text('India'));
    await tester.pumpAndSettle();
    expect((result! as GlobeDialCode).code, '+91');

    await _pumpLauncher(
      tester,
      (context) => GlobePicker.dateFormat(
        context,
        filter: const GlobeFilter(countries: ['US']),
      ),
      (value) => result = value,
    );
    await tester.tap(find.text('MM/dd/yyyy'));
    await tester.pumpAndSettle();
    expect((result! as GlobeDateFormat).pattern, 'MM/dd/yyyy');
  });
}
