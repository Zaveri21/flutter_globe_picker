import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('GlobePickerField', () {
    testWidgets('validates, opens the picker and updates', (tester) async {
      final formKey = GlobalKey<FormState>();
      GlobeCurrency? changed;
      GlobeCurrency? saved;
      await tester.pumpWidget(
        _host(
          Form(
            key: formKey,
            child: GlobePickerField(
              type: GlobePickerType.currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              pickerOptions: const GlobePickerOptions(
                filter: GlobeFilter(currencies: ['EUR', 'INR']),
              ),
              validator: (value) => value == null ? 'Required' : null,
              onChanged: (value) => changed = value,
              onSaved: (value) => saved = value,
              showClearButton: true,
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);

      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Indian Rupee'));
      await tester.pumpAndSettle();
      expect(changed?.code, 'INR');
      expect(find.textContaining('Indian Rupee'), findsOneWidget);
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved?.code, 'INR');

      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(changed, isNull);
    });

    testWidgets('initial value and custom display', (tester) async {
      await tester.pumpWidget(
        _host(
          GlobePickerField(
            type: GlobePickerType.country,
            initialValue: GlobeData.countryByAlpha2('JP'),
            selectedItemBuilder: (context, country) =>
                Text('chosen ${country.alpha3Code}'),
          ),
        ),
      );
      expect(find.text('chosen JPN'), findsOneWidget);
    });

    testWidgets('disabled field does not open', (tester) async {
      await tester.pumpWidget(
        _host(
          GlobePickerField(
            type: GlobePickerType.country,
            enabled: false,
            decoration: const InputDecoration(labelText: 'Country'),
          ),
        ),
      );
      await tester.tap(find.text('Country'));
      await tester.pumpAndSettle();
      expect(find.text('Select country'), findsNothing);
    });
  });

  group('GlobePickerButton', () {
    testWidgets('shows the code and changes', (tester) async {
      GlobeCurrency? value = GlobeData.currencyByCode('USD');
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => GlobePickerButton(
              type: GlobePickerType.currency,
              value: value,
              flagType: GlobeFlagType.emoji,
              pickerOptions: const GlobePickerOptions(
                filter: GlobeFilter(currencies: ['USD', 'EUR']),
              ),
              onChanged: (currency) => setState(() => value = currency),
            ),
          ),
        ),
      );
      expect(find.text('USD'), findsOneWidget);
      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Euro'));
      await tester.pumpAndSettle();
      expect(find.text('EUR'), findsOneWidget);
    });

    testWidgets('labels for every type', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              GlobePickerButton(
                type: GlobePickerType.country,
                value: GlobeData.countryByAlpha2('IN'),
                onChanged: (_) {},
              ),
              GlobePickerButton(
                type: GlobePickerType.dialCode,
                value: GlobeData.dialCodeByCode('+1876'),
                onChanged: (_) {},
              ),
              GlobePickerButton(
                type: GlobePickerType.dateFormat,
                value: GlobeData.dateFormatByPattern('dd.MM.yyyy'),
                onChanged: (_) {},
              ),
              GlobePickerButton(
                type: GlobePickerType.currency,
                value: GlobeData.currencyByCode('INR'),
                labelBuilder: (currency) => currency.symbol,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('IN'), findsOneWidget);
      expect(find.text('+1 876'), findsOneWidget);
      expect(find.text('dd.MM.yyyy'), findsOneWidget);
      expect(find.text('₹'), findsOneWidget);
    });
  });

  group('GlobePhoneField', () {
    testWidgets('reports E.164 numbers and validates', (tester) async {
      final formKey = GlobalKey<FormState>();
      GlobePhoneNumber? phone;
      await tester.pumpWidget(
        _host(
          Form(
            key: formKey,
            child: GlobePhoneField(
              initialCountryCode: 'IN',
              isRequired: true,
              onChanged: (value) => phone = value,
            ),
          ),
        ),
      );
      expect(find.text('+91'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('This field is required'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '12345');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Enter a valid phone number'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '98765 43210');
      expect(phone?.e164, '+919876543210');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('pasting an international number switches country', (
      tester,
    ) async {
      GlobeCountry? country;
      GlobePhoneNumber? phone;
      await tester.pumpWidget(
        _host(
          GlobePhoneField(
            initialCountryCode: 'IN',
            onCountryChanged: (value) => country = value,
            onChanged: (value) => phone = value,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '+44 7400 123456');
      await tester.pump();
      expect(country?.alpha2Code, 'GB');
      expect(phone?.e164, '+447400123456');
      expect(find.text('+44'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '7400123456');
    });

    testWidgets('typing a shared calling code waits for the area code', (
      tester,
    ) async {
      GlobePhoneNumber? phone;
      await tester.pumpWidget(
        _host(
          GlobePhoneField(
            initialCountryCode: 'IN',
            onChanged: (value) => phone = value,
          ),
        ),
      );
      final field = find.byType(TextFormField);
      var text = '';
      for (final character in '+12423456789'.split('')) {
        text += character;
        await tester.enterText(field, text);
        await tester.pump();
        text = tester
            .widget<TextField>(find.byType(TextField))
            .controller!
            .text;
      }
      expect(phone?.country.alpha2Code, 'BS');
      expect(phone?.e164, '+12423456789');
      expect(text, '2423456789');
    });

    testWidgets('typing a calling code used by one country switches at once', (
      tester,
    ) async {
      GlobeCountry? country;
      await tester.pumpWidget(
        _host(
          GlobePhoneField(
            initialCountryCode: 'US',
            onCountryChanged: (value) => country = value,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '+919');
      await tester.pump();
      expect(country?.alpha2Code, 'IN');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '9');
    });

    testWidgets('initial international value and country picker', (
      tester,
    ) async {
      GlobePhoneNumber? phone;
      await tester.pumpWidget(
        _host(
          GlobePhoneField(
            initialValue: '+1 416 555 1234',
            onChanged: (value) => phone = value,
            pickerOptions: const GlobePickerOptions(
              filter: GlobeFilter(countries: ['CA', 'JP']),
            ),
          ),
        ),
      );
      expect(find.text('+1'), findsOneWidget);
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text('+81'), findsOneWidget);
      await tester.tap(find.text('Japan'));
      await tester.pumpAndSettle();
      expect(find.text('+81'), findsOneWidget);
      expect(phone?.country.alpha2Code, 'JP');
    });

    testWidgets('uses the locale when no country is given', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'GB'),
          supportedLocales: const [Locale('en', 'GB')],
          home: const Scaffold(body: GlobePhoneField()),
        ),
      );
      expect(find.text('+44'), findsOneWidget);
    });
  });
}
