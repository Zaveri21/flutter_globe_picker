import 'dart:async';
import 'dart:io';

import 'package:flutter_globe_picker/flutter_globe_picker.dart';

/// Loads the package's JSON before the tests, like `GlobeData.load()` does
/// in the app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GlobeData.loadFromJson(
    File('../assets/globe_data.json').readAsStringSync(),
    translationsJson: File('../assets/globe_translations.json')
        .readAsStringSync(),
  );
  await testMain();
}
