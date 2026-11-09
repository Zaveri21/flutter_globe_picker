import 'package:flutter/foundation.dart';

import 'package:flutter_globe_picker/src/models/globe_models.dart';

/// Controls a picker from outside: search text and selection.
///
/// ```dart
/// final controller = GlobePickerController<GlobeCountry>();
///
/// GlobePickerView(type: GlobePickerType.country, controller: controller);
///
/// controller.search('ind');
/// controller.select(GlobeData.countryByAlpha2('IN')!);
/// controller.clearSelection();
/// ```
///
/// Dispose the controller when it is no longer needed.
class GlobePickerController<T extends GlobeItem> extends ChangeNotifier {
  /// Creates a controller with an optional starting selection and query.
  GlobePickerController({
    Iterable<T> initialSelection = const [],
    String initialQuery = '',
  }) : _selection = initialSelection.toSet().toList(),
       _query = initialQuery;

  String _query;
  List<T> _selection;

  /// The current search text.
  String get query => _query;

  /// Selected items in selection order.
  List<T> get selection => List.unmodifiable(_selection);

  /// The first selected item, or `null`.
  T? get selected => _selection.isEmpty ? null : _selection.first;

  /// Whether [item] is selected.
  bool isSelected(T item) => _selection.contains(item);

  /// Sets the search text.
  void search(String query) {
    if (query == _query) return;
    _query = query;
    notifyListeners();
  }

  /// Clears the search text.
  void clearQuery() => search('');

  /// Selects only [item].
  void select(T item) {
    if (_selection.length == 1 && _selection.first == item) return;
    _selection = [item];
    notifyListeners();
  }

  /// Adds [item] to the selection, or removes it when already selected.
  void toggle(T item) {
    _selection = isSelected(item)
        ? (_selection.toList()..remove(item))
        : [..._selection, item];
    notifyListeners();
  }

  /// Removes [item] from the selection.
  void deselect(T item) {
    if (!isSelected(item)) return;
    _selection = _selection.toList()..remove(item);
    notifyListeners();
  }

  /// Replaces the whole selection.
  void setSelection(Iterable<T> items) {
    final next = items.toSet().toList();
    if (listEquals(next, _selection)) return;
    _selection = next;
    notifyListeners();
  }

  /// Clears the selection.
  void clearSelection() => setSelection(const []);
}
