import 'package:flutter/material.dart';
import 'package:flutter_globe_picker_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every gallery page opens without errors', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GlobePickerExampleApp());
    final pageTitles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data!)
        .toList();
    expect(pageTitles, hasLength(12));

    for (final title in pageTitles) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: title);
      expect(find.widgetWithText(AppBar, title), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a picker opens from the modes page and returns a result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GlobePickerExampleApp());
    await tester.tap(find.text('Picker modes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Country'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'japan');
    await tester.pump();
    await tester.tap(find.text('Japan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Japan · JP'), findsOneWidget);
  });
}
