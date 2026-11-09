import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Picks [name] in the open country picker.
Future<void> _pickCountry(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField).last, name);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  group('GlobePhoneField', () {
    testWidgets('text set on the controller from outside switches country', (
      tester,
    ) async {
      final controller = TextEditingController();
      final countries = <String>[];
      GlobePhoneNumber? phone;
      await tester.pumpWidget(
        _app(
          GlobePhoneField(
            initialCountryCode: 'US',
            controller: controller,
            onCountryChanged: (country) => countries.add(country.alpha2Code),
            onChanged: (value) => phone = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.text = '+44 20 7946 0958';
      await tester.pumpAndSettle();
      expect(countries, ['GB']);
      expect(phone?.e164, '+442079460958');
      expect(controller.text, '2079460958');
      expect(find.text('+44'), findsOneWidget);
    });

    testWidgets('a country picked while a calling code is typed wins', (
      tester,
    ) async {
      GlobePhoneNumber? phone;
      await tester.pumpWidget(
        _app(
          GlobePhoneField(
            initialCountryCode: 'GB',
            onChanged: (value) => phone = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '+1 2');
      await tester.pump();
      await tester.tap(find.byType(GlobePickerButton<GlobeCountry>));
      await tester.pumpAndSettle();
      await _pickCountry(tester, 'Canada');
      expect(phone?.country.alpha2Code, 'CA');
      expect(phone?.nationalNumber, '2');
    });

    testWidgets('Form.reset brings back the starting country and number', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: const GlobePhoneField(initialCountryCode: 'US'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '+44 20 7946 0958');
      await tester.pumpAndSettle();
      expect(find.text('+44'), findsOneWidget);
      formKey.currentState!.reset();
      await tester.pumpAndSettle();
      expect(find.text('+1'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('a + is only accepted first', (tester) async {
      await tester.pumpWidget(_app(const GlobePhoneField()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '12+3');
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isNot(contains('+')));
    });

    testWidgets('an initial value with a shared controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, _) => Text('mirror:${value.text}'),
              ),
              GlobePhoneField(
                controller: controller,
                initialValue: '+91 98765 43210',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.text, '9876543210');
      expect(find.text('mirror:9876543210'), findsOneWidget);
    });
  });

  testWidgets('fields removed while their picker is open stay quiet', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    var changes = 0;
    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, isVisible, _) => isVisible
              ? Column(
                  children: [
                    GlobePhoneField(
                      initialCountryCode: 'US',
                      onCountryChanged: (_) => changes++,
                    ),
                  ],
                )
              : const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GlobePickerButton<GlobeCountry>));
    await tester.pumpAndSettle();
    visible.value = false;
    await tester.pump();
    await _pickCountry(tester, 'India');
    expect(tester.takeException(), isNull);
    expect(changes, 0);
  });

  group('GlobePickerView', () {
    testWidgets('resolves its selection once its data source is loaded', (
      tester,
    ) async {
      final source = GlobeDataSource(
        json: File('assets/globe_data.json').readAsStringSync(),
        translationsJson: File('assets/globe_translations.json')
            .readAsStringSync(),
        countryOverrides: const {
          'IN': {'name': 'Bharat'},
        },
      );
      addTearDown(
        () => GlobeData.loadFromJson(
          File('assets/globe_data.json').readAsStringSync(),
          translationsJson: File('assets/globe_translations.json')
              .readAsStringSync(),
        ),
      );
      final controller = GlobePickerController<GlobeCountry>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          GlobePickerView<GlobeCountry>(
            type: GlobePickerType.country,
            multiSelect: true,
            selected: const ['IN', 'US'],
            options: GlobePickerOptions(
              dataSource: source,
              // US is hidden, so it must not stay selected unseen.
              filter: const GlobeFilter(excludeCountries: ['US']),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Done (1)'), findsOneWidget);
      expect(GlobeData.countryByAlpha2('IN')?.name, 'Bharat');
    });

    testWidgets('a query set from outside cancels a pending debounce', (
      tester,
    ) async {
      final controller = GlobePickerController<GlobeCountry>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          GlobePickerView<GlobeCountry>(
            type: GlobePickerType.country,
            controller: controller,
            options: const GlobePickerOptions(
              search: GlobeSearchConfig(debounce: Duration(milliseconds: 300)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ger');
      await tester.pump(const Duration(milliseconds: 100));
      controller.search('fra');
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.query, 'fra');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'fra');
    });
  });

  test('a shared dial code names its main country first', () {
    final ukCode = GlobeData.dialCodeByCode('+44')!;
    expect(
      GlobeListTile.displayText(ukCode, GlobeField.countryName),
      startsWith('United Kingdom, '),
    );
  });
}
