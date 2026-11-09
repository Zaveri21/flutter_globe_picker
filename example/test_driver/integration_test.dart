import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves the screenshots taken by `integration_test/screenshots_test.dart`
/// into the package's `screenshots/` folder, used by the README.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [arguments]) async {
    final file = File('../screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    stdout.writeln('Saved ${file.path}');
    return true;
  },
);
