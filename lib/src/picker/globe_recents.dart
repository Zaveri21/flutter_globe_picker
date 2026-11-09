import 'package:flutter/foundation.dart';

import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_type.dart';

/// Remembers recently selected items for pickers with `showRecents: true`.
///
/// Items are kept in memory for the app session. To keep them across app
/// launches, save [idsFor] in your own storage when the instance notifies
/// listeners, and call [restore] at startup:
///
/// ```dart
/// GlobeRecents.instance.restore(GlobePickerType.country, savedIds);
/// GlobeRecents.instance.addListener(() {
///   prefs.setStringList(
///     'recentCountries',
///     GlobeRecents.instance.idsFor(GlobePickerType.country),
///   );
/// });
/// ```
class GlobeRecents extends ChangeNotifier {
  GlobeRecents._();

  /// The shared instance used by every picker.
  static final GlobeRecents instance = GlobeRecents._();

  /// How many items are kept per picker type.
  int get maxEntries => _maxEntries;
  int _maxEntries = 5;
  set maxEntries(int value) {
    assert(value > 0, 'maxEntries must be positive');
    _maxEntries = value;
    var changed = false;
    for (final ids in _idsByType.values) {
      if (ids.length > value) {
        ids.removeRange(value, ids.length);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  final Map<String, List<String>> _idsByType = {};

  /// Recently selected ids for [type], most recent first.
  List<String> idsFor(GlobePickerType<GlobeItem> type) =>
      List.unmodifiable(_idsByType[type.name] ?? const <String>[]);

  /// Recently selected items for [type], most recent first.
  List<T> itemsFor<T extends GlobeItem>(GlobePickerType<T> type) => [
    for (final id in _idsByType[type.name] ?? const <String>[])
      ?type.itemById(id),
  ];

  /// Moves [item] to the front of the recent list of [type].
  void record<T extends GlobeItem>(GlobePickerType<T> type, T item) {
    final ids = _idsByType.putIfAbsent(type.name, () => [])
      ..remove(item.id)
      ..insert(0, item.id);
    if (ids.length > _maxEntries) ids.removeRange(_maxEntries, ids.length);
    notifyListeners();
  }

  /// Replaces the recent ids of [type], for example from saved preferences.
  /// Unknown ids are dropped and the others are stored in their canonical
  /// form (`in` becomes `IN`), once each.
  void restore(GlobePickerType<GlobeItem> type, List<String> ids) {
    _idsByType[type.name] = {for (final id in ids) ?type.itemById(id)?.id}
        .take(_maxEntries)
        .toList();
    notifyListeners();
  }

  /// Forgets recent items of [type], or of every type when `null`.
  void clear([GlobePickerType<GlobeItem>? type]) {
    if (type == null) {
      _idsByType.clear();
    } else {
      _idsByType.remove(type.name);
    }
    notifyListeners();
  }
}
