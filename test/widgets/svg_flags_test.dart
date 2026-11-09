import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every country has both SVG flags bundled', () {
    for (final country in GlobeData.countries) {
      for (final aspect in GlobeFlagAspect.values) {
        expect(
          File(country.flagAssetPath(aspect)).existsSync(),
          isTrue,
          reason: '${country.alpha2Code} ${aspect.folder}',
        );
      }
    }
  });

  testWidgets('every bundled SVG flag parses with flutter_svg', (tester) async {
    final files = Directory('assets/flags')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.svg'))
        .toList();
    expect(files.length, greaterThan(500));
    await tester.runAsync(() async {
      for (final file in files) {
        final info = await vg.loadPicture(
          SvgStringLoader(file.readAsStringSync()),
          null,
        );
        expect(info.size.isEmpty, isFalse, reason: file.path);
        info.picture.dispose();
      }
    });
  });

  test('package asset key resolves', () async {
    final data = await rootBundle.load(
      'packages/flutter_globe_picker/assets/flags/4x3/in.svg',
    );
    expect(data.lengthInBytes, greaterThan(0));
  });
}
