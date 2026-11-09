// Takes the README screenshots on a running simulator or device:
//
//   cd example
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d <device id>
//
// Files are written to ../screenshots/<platform>_<name>.png.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_globe_picker_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobeData.load();
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
  });

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await binding.takeScreenshot('${Platform.operatingSystem}_$name');
  }

  /// Starts the example app fresh and opens the gallery page [title].
  Future<void> openPage(WidgetTester tester, String title) async {
    await tester.pumpWidget(GlobePickerExampleApp(key: UniqueKey()));
    await tester.pumpAndSettle();
    final page = find.text(title);
    await tester.scrollUntilVisible(page, 300);
    await tester.tap(page);
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.scrollUntilVisible(button, 200);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('country picker as a bottom sheet', (tester) async {
    await openPage(tester, 'Picker modes');
    await tapButton(tester, 'Country');
    await capture(tester, 'country_sheet');
  });

  testWidgets('iOS style sheet', (tester) async {
    await openPage(tester, 'Picker modes');
    await tester.tap(find.text('iOS'));
    await tester.pumpAndSettle();
    await tapButton(tester, 'Country');
    await capture(tester, 'cupertino_sheet');
  });

  testWidgets('currency picker', (tester) async {
    await openPage(tester, 'Picker modes');
    await tapButton(tester, 'Currency');
    await capture(tester, 'currency_sheet');
  });

  testWidgets('phone field detects the country', (tester) async {
    await openPage(tester, 'Form widgets');
    await tester.enterText(find.byType(TextFormField).first, '+447400123456');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await capture(tester, 'phone_field');
  });

  testWidgets('picker in Arabic, right to left', (tester) async {
    await openPage(tester, 'Localization and RTL');
    await tester.tap(find.widgetWithText(ChoiceChip, 'ar'));
    await tester.pumpAndSettle();
    await tapButton(tester, 'Countries sorted by translated name');
    await capture(tester, 'arabic_rtl');
  });

  testWidgets('headless builder grid', (tester) async {
    await openPage(tester, 'Headless builder');
    await capture(tester, 'headless_grid');
  });
}
