import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('GlobeFlag', () {
    testWidgets('emoji, svg and fallback', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const GlobeFlag(code: 'in', type: GlobeFlagType.emoji),
              const GlobeFlag(code: 'zz', type: GlobeFlagType.emoji),
              const GlobeFlag(
                code: 'US',
                type: GlobeFlagType.svg,
                shape: GlobeFlagShape.circle,
              ),
              GlobeFlag.fromItem(
                GlobeData.currencyByCode('EUR')!,
                type: GlobeFlagType.svg,
              ),
            ],
          ),
        ),
      );
      expect(find.text('🇮🇳'), findsOneWidget);
      expect(find.text('\u{1F3F3}\u{FE0F}'), findsOneWidget);
      expect(find.byType(SvgPicture), findsNWidgets(2));
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.bySemanticsLabel('Flag of India'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Flag of the European Union'),
        findsOneWidget,
      );
    });

    testWidgets('sizes', (tester) async {
      await tester.pumpWidget(
        _host(const Center(child: GlobeFlag(code: 'IN', width: 40))),
      );
      expect(tester.getSize(find.byType(GlobeFlag)), const Size(40, 30));
      await tester.pumpWidget(
        _host(
          const Center(
            child: GlobeFlag(
              code: 'IN',
              width: 40,
              shape: GlobeFlagShape.square,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(GlobeFlag)), const Size(40, 40));
    });

    test('auto uses SVG only where emoji flags are missing', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(GlobeFlag.usesSvg(GlobeFlagType.auto), isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(GlobeFlag.usesSvg(GlobeFlagType.auto), isFalse);
      debugDefaultTargetPlatformOverride = null;
      expect(GlobeFlag.usesSvg(GlobeFlagType.svg), isTrue);
      expect(GlobeFlag.usesSvg(GlobeFlagType.emoji), isFalse);
    });
  });

  group('GlobePickerTheme', () {
    test('copyWith, merge and lerp', () {
      const base = GlobePickerTheme(borderRadius: 10, flagWidth: 20);
      final copy = base.copyWith(borderRadius: 30);
      expect(copy.borderRadius, 30);
      expect(copy.flagWidth, 20);
      final merged = base.merge(const GlobePickerTheme(flagWidth: 40));
      expect(merged.borderRadius, 10);
      expect(merged.flagWidth, 40);
      expect(base.merge(null), same(base));
      final halfway = base.lerp(const GlobePickerTheme(borderRadius: 20), 0.5);
      expect(halfway.borderRadius, 15);
      expect(base.lerp(null, 0.5), same(base));
    });

    testWidgets('resolve fills every value from the color scheme', (
      tester,
    ) async {
      late GlobePickerThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: Colors.teal),
          home: Builder(
            builder: (context) {
              resolved = GlobePickerTheme.resolve(
                context,
                const GlobePickerTheme(heightFactor: 2),
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved.heightFactor, 1.0);
      expect(resolved.borderRadius, 28);
      expect(resolved.selectedIconColor, isNotNull);
    });
  });

  group('GlobeStrings', () {
    test('defaults, titles and copyWith', () {
      const strings = GlobeStrings.english;
      expect(strings.titleFor(GlobePickerType.country), 'Select country');
      expect(strings.titleFor(GlobePickerType.currency), 'Select currency');
      expect(strings.titleFor(GlobePickerType.dialCode), 'Select dial code');
      expect(
        strings.titleFor(GlobePickerType.dateFormat),
        'Select date format',
      );
      expect(strings.selectedCount('Done', 0), 'Done');
      expect(strings.selectedCount('Done', 3), 'Done (3)');
      expect(strings.regionName(GlobeRegion.europe), 'Europe');
      expect(strings.moreCount(4), '+4');
      final spanish = strings.copyWith(done: 'Listo');
      expect(spanish.done, 'Listo');
      expect(spanish.searchHint, 'Search');
    });
  });

  group('GlobePickerController', () {
    test('query and selection', () {
      final controller = GlobePickerController<GlobeCountry>();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final india = GlobeData.countryByAlpha2('IN')!;
      final japan = GlobeData.countryByAlpha2('JP')!;

      controller.search('ind');
      controller.search('ind');
      expect(controller.query, 'ind');
      controller.clearQuery();
      expect(controller.query, '');

      controller.select(india);
      controller.select(india);
      expect(controller.selected, india);
      controller.toggle(japan);
      expect(controller.selection, [india, japan]);
      controller.toggle(india);
      expect(controller.selection, [japan]);
      controller.deselect(india);
      controller.deselect(japan);
      expect(controller.selected, isNull);
      controller.setSelection([india, india, japan]);
      expect(controller.selection, [india, japan]);
      controller.clearSelection();
      expect(controller.selection, isEmpty);
      expect(() => controller.selection.add(india), throwsUnsupportedError);
      expect(notifications, 8);
    });
  });

  group('GlobeRecents', () {
    tearDown(() {
      GlobeRecents.instance
        ..maxEntries = 5
        ..clear();
    });

    test('records, limits, restores and clears', () {
      final recents = GlobeRecents.instance..clear();
      for (final code in ['IN', 'US', 'JP', 'FR', 'DE', 'IT']) {
        recents.record(
          GlobePickerType.country,
          GlobeData.countryByAlpha2(code)!,
        );
      }
      expect(recents.idsFor(GlobePickerType.country), [
        'IT',
        'DE',
        'FR',
        'JP',
        'US',
      ]);
      recents.record(GlobePickerType.country, GlobeData.countryByAlpha2('JP')!);
      expect(recents.idsFor(GlobePickerType.country).first, 'JP');
      recents.maxEntries = 2;
      expect(recents.idsFor(GlobePickerType.country), ['JP', 'IT']);
      recents.restore(GlobePickerType.currency, ['EUR', 'XXX', 'INR']);
      expect(
        recents
            .itemsFor(GlobePickerType.currency)
            .map((currency) => currency.code),
        // Unknown ids are dropped before the limit applies.
        ['EUR', 'INR'],
      );
      recents.clear(GlobePickerType.country);
      expect(recents.idsFor(GlobePickerType.country), isEmpty);
      expect(recents.idsFor(GlobePickerType.currency), isNotEmpty);
    });
  });

  group('GlobePickerType', () {
    test('items and lookup by id', () {
      expect(GlobePickerType.country.items.length, 250);
      expect(GlobePickerType.country.itemById('ind')?.alpha2Code, 'IN');
      expect(GlobePickerType.currency.itemById('eur')?.code, 'EUR');
      expect(GlobePickerType.dialCode.itemById('91')?.code, '+91');
      expect(GlobePickerType.dateFormat.itemById('dd/MM/yyyy'), isNotNull);
      expect(GlobePickerType.values, hasLength(4));
      expect(GlobePickerType.country.toString(), 'GlobePickerType.country');
    });
  });

  group('GlobeListTile.displayText', () {
    test('summaries and codes', () {
      expect(
        GlobeListTile.displayText(
          GlobeData.dialCodeByCode('+44')!,
          GlobeField.countryName,
        ),
        matches(RegExp(r'^.+, .+ \+\d+$')),
      );
      expect(
        GlobeListTile.displayText(
          GlobeData.currencyByCode('INR')!,
          GlobeField.countryName,
        ),
        'India',
      );
      expect(
        GlobeListTile.displayText(
          GlobeData.countryByAlpha2('JM')!,
          GlobeField.dialCode,
        ),
        '+1 876',
      );
      expect(
        GlobeListTile.displayText(
          GlobeData.countryByAlpha2('IN')!,
          GlobeField.flag,
        ),
        isNull,
      );
    });
  });
}
