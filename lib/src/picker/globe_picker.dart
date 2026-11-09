import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_globe_picker/src/filter/globe_filter.dart';
import 'package:flutter_globe_picker/src/globe_data.dart';
import 'package:flutter_globe_picker/src/globe_data_source.dart';
import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_options.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_theme.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_type.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_view.dart';
import 'package:flutter_globe_picker/src/picker/globe_recents.dart';
import 'package:flutter_globe_picker/src/picker/globe_strings.dart';

/// Opens pickers as a bottom sheet, dialog, full page or Cupertino sheet.
///
/// Every method returns the selected item, or `null` when the picker is
/// closed without a selection.
///
/// ```dart
/// final country = await GlobePicker.country(context);
/// final currency = await GlobePicker.currency(
///   context,
///   mode: GlobePickerMode.dialog,
///   filter: const GlobeFilter(excludeCurrencies: ['XOF']),
/// );
/// ```
abstract final class GlobePicker {
  /// Opens a picker of any [type] and returns the selected item.
  ///
  /// [selected] preselects an item by id (alpha-2 code, currency code, dial
  /// code or date pattern). [options] holds shared settings; the named
  /// shortcuts (`filter`, `display`, ...) replace the matching option.
  /// [items] replaces the listed items and [builders] replaces parts of the
  /// UI.
  static Future<T?> show<T extends GlobeItem>(
    BuildContext context, {
    required GlobePickerType<T> type,
    GlobePickerMode mode = GlobePickerMode.bottomSheet,
    String? selected,
    GlobePickerOptions options = const GlobePickerOptions(),
    List<T>? items,
    GlobeFilter? filter,
    GlobeDisplay? display,
    GlobeSearchConfig? search,
    GlobeGroupBy? groupBy,
    List<String>? favorites,
    bool? showRecents,
    String? title,
    GlobePickerTheme? theme,
    GlobeStrings? strings,
    GlobeDataSource? dataSource,
    GlobePickerBuilders<T>? builders,
    bool useRootNavigator = false,
    bool isDismissible = true,
  }) async {
    final resolvedOptions = options.copyWith(
      filter: filter,
      display: display,
      search: search,
      groupBy: groupBy,
      favorites: favorites,
      showRecents: showRecents,
      title: title,
      theme: theme,
      strings: strings,
      dataSource: dataSource,
    );
    await GlobeData.ensureLoaded(resolvedOptions.dataSource);
    if (!context.mounted) return null;
    final result = await _present(
      context,
      mode: mode,
      options: resolvedOptions,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      buildView: (onSelected, onConfirm, onClose, useCupertinoSearch) =>
          GlobePickerView<T>(
            type: type,
            options: resolvedOptions,
            items: items,
            builders: builders,
            selected: [?selected],
            onSelected: onSelected,
            onClose: onClose,
            useCupertinoSearch: useCupertinoSearch,
          ),
    );
    if (result is T) {
      GlobeRecents.instance.record(type, result);
      return result;
    }
    return null;
  }

  /// Opens a multi-select picker and returns the selected items, or `null`
  /// when it is closed without confirming.
  static Future<List<T>?> showMultiple<T extends GlobeItem>(
    BuildContext context, {
    required GlobePickerType<T> type,
    GlobePickerMode mode = GlobePickerMode.bottomSheet,
    List<String> selected = const [],
    GlobePickerOptions options = const GlobePickerOptions(),
    List<T>? items,
    GlobeFilter? filter,
    GlobeDisplay? display,
    GlobeSearchConfig? search,
    GlobeGroupBy? groupBy,
    List<String>? favorites,
    String? title,
    GlobePickerTheme? theme,
    GlobeStrings? strings,
    GlobeDataSource? dataSource,
    GlobePickerBuilders<T>? builders,
    bool useRootNavigator = false,
    bool isDismissible = true,
  }) async {
    final resolvedOptions = options.copyWith(
      filter: filter,
      display: display,
      search: search,
      groupBy: groupBy,
      favorites: favorites,
      title: title,
      theme: theme,
      strings: strings,
      dataSource: dataSource,
    );
    await GlobeData.ensureLoaded(resolvedOptions.dataSource);
    if (!context.mounted) return null;
    final result = await _present(
      context,
      mode: mode,
      options: resolvedOptions,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      buildView: (_, onConfirm, onClose, useCupertinoSearch) =>
          GlobePickerView<T>(
            type: type,
            options: resolvedOptions,
            items: items,
            builders: builders,
            selected: selected,
            multiSelect: true,
            onConfirm: onConfirm,
            onClose: onClose,
            useCupertinoSearch: useCupertinoSearch,
          ),
    );
    return result is List<T> ? result : null;
  }

  /// Opens a country picker.
  static Future<GlobeCountry?> country(
    BuildContext context, {
    GlobePickerMode mode = GlobePickerMode.bottomSheet,
    String? selected,
    GlobeFilter? filter,
    GlobeDisplay? display,
    GlobeSearchConfig? search,
    GlobeGroupBy? groupBy,
    List<String>? favorites,
    bool? showRecents,
    String? title,
    GlobePickerTheme? theme,
    GlobeStrings? strings,
    GlobeDataSource? dataSource,
    GlobePickerBuilders<GlobeCountry>? builders,
  }) => show(
    context,
    type: GlobePickerType.country,
    mode: mode,
    selected: selected,
    filter: filter,
    display: display,
    search: search,
    groupBy: groupBy,
    favorites: favorites,
    showRecents: showRecents,
    title: title,
    theme: theme,
    strings: strings,
    dataSource: dataSource,
    builders: builders,
  );

  /// Opens a currency picker.
  static Future<GlobeCurrency?> currency(
    BuildContext context, {
    GlobePickerMode mode = GlobePickerMode.bottomSheet,
    String? selected,
    GlobeFilter? filter,
    GlobeDisplay? display,
    GlobeSearchConfig? search,
    GlobeGroupBy? groupBy,
    List<String>? favorites,
    bool? showRecents,
    String? title,
    GlobePickerTheme? theme,
    GlobeStrings? strings,
    GlobeDataSource? dataSource,
    GlobePickerBuilders<GlobeCurrency>? builders,
  }) => show(
    context,
    type: GlobePickerType.currency,
    mode: mode,
    selected: selected,
    filter: filter,
    display: display,
    search: search,
    groupBy: groupBy,
    favorites: favorites,
    showRecents: showRecents,
    title: title,
    theme: theme,
    strings: strings,
    dataSource: dataSource,
    builders: builders,
  );

  /// Opens a dial code picker.
  static Future<GlobeDialCode?> dialCode(
    BuildContext context, {
    GlobePickerMode mode = GlobePickerMode.bottomSheet,
    String? selected,
    GlobeFilter? filter,
    GlobeDisplay? display,
    GlobeSearchConfig? search,
    GlobeGroupBy? groupBy,
    List<String>? favorites,
    bool? showRecents,
    String? title,
    GlobePickerTheme? theme,
    GlobeStrings? strings,
    GlobeDataSource? dataSource,
    GlobePickerBuilders<GlobeDialCode>? builders,
  }) => show(
    context,
    type: GlobePickerType.dialCode,
    mode: mode,
    selected: selected,
    filter: filter,
    display: display,
    search: search,
    groupBy: groupBy,
    favorites: favorites,
    showRecents: showRecents,
    title: title,
    theme: theme,
    strings: strings,
    dataSource: dataSource,
    builders: builders,
  );

  /// Opens a date format picker.
  static Future<GlobeDateFormat?> dateFormat(
    BuildContext context, {
    GlobePickerMode mode = GlobePickerMode.bottomSheet,
    String? selected,
    GlobeFilter? filter,
    GlobeDisplay? display,
    GlobeSearchConfig? search,
    String? title,
    GlobePickerTheme? theme,
    GlobeStrings? strings,
    GlobeDataSource? dataSource,
    GlobePickerBuilders<GlobeDateFormat>? builders,
  }) => show(
    context,
    type: GlobePickerType.dateFormat,
    mode: mode,
    selected: selected,
    filter: filter,
    display: display,
    search: search,
    title: title,
    theme: theme,
    strings: strings,
    dataSource: dataSource,
    builders: builders,
  );

  /// Opens a multi-select country picker.
  static Future<List<GlobeCountry>?> countries(
    BuildContext context, {
    GlobePickerMode mode = GlobePickerMode.bottomSheet,
    List<String> selected = const [],
    GlobeFilter? filter,
    GlobeDisplay? display,
    GlobeSearchConfig? search,
    GlobeGroupBy? groupBy,
    List<String>? favorites,
    String? title,
    GlobePickerTheme? theme,
    GlobeStrings? strings,
    GlobeDataSource? dataSource,
    GlobePickerBuilders<GlobeCountry>? builders,
  }) => showMultiple(
    context,
    type: GlobePickerType.country,
    mode: mode,
    selected: selected,
    filter: filter,
    display: display,
    search: search,
    groupBy: groupBy,
    favorites: favorites,
    title: title,
    theme: theme,
    strings: strings,
    dataSource: dataSource,
    builders: builders,
  );

  /// Opens a multi-select currency picker.
  static Future<List<GlobeCurrency>?> currencies(
    BuildContext context, {
    GlobePickerMode mode = GlobePickerMode.bottomSheet,
    List<String> selected = const [],
    GlobeFilter? filter,
    GlobeDisplay? display,
    GlobeSearchConfig? search,
    GlobeGroupBy? groupBy,
    List<String>? favorites,
    String? title,
    GlobePickerTheme? theme,
    GlobeStrings? strings,
    GlobeDataSource? dataSource,
    GlobePickerBuilders<GlobeCurrency>? builders,
  }) => showMultiple(
    context,
    type: GlobePickerType.currency,
    mode: mode,
    selected: selected,
    filter: filter,
    display: display,
    search: search,
    groupBy: groupBy,
    favorites: favorites,
    title: title,
    theme: theme,
    strings: strings,
    dataSource: dataSource,
    builders: builders,
  );

  /// Shows the view built by [buildView] in the chosen [mode] and completes
  /// with the value the view pops with.
  static Future<Object?> _present(
    BuildContext context, {
    required GlobePickerMode mode,
    required GlobePickerOptions options,
    required bool useRootNavigator,
    required bool isDismissible,
    required Widget Function(
      ValueChanged<dynamic> onSelected,
      ValueChanged<dynamic> onConfirm,
      VoidCallback onClose,
      bool useCupertinoSearch,
    )
    buildView,
  }) {
    final theme = GlobePickerTheme.resolve(context, options.theme);
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);

    Widget viewFor(BuildContext routeContext, {bool cupertino = false}) {
      void pop([Object? value]) => Navigator.of(routeContext).pop(value);
      return buildView(pop, pop, pop, cupertino);
    }

    switch (mode) {
      case GlobePickerMode.bottomSheet:
        return showModalBottomSheet<Object?>(
          context: context,
          useRootNavigator: useRootNavigator,
          isScrollControlled: true,
          useSafeArea: true,
          isDismissible: isDismissible,
          enableDrag: isDismissible,
          backgroundColor: theme.backgroundColor,
          barrierColor: theme.barrierColor,
          elevation: theme.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(theme.borderRadius),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          builder: (sheetContext) => _KeyboardAwareSizedBox(
            heightFactor: theme.heightFactor,
            child: Column(
              children: [
                if (options.display.showDragHandle)
                  _DragHandle(color: theme.handleColor),
                Expanded(child: viewFor(sheetContext)),
              ],
            ),
          ),
        );
      case GlobePickerMode.dialog:
        return showDialog<Object?>(
          context: context,
          useRootNavigator: useRootNavigator,
          barrierDismissible: isDismissible,
          barrierColor: theme.barrierColor,
          builder: (dialogContext) {
            final screenHeight = MediaQuery.sizeOf(dialogContext).height;
            return Dialog(
              backgroundColor: theme.backgroundColor,
              elevation: theme.elevation,
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.dialogMaxWidth,
                  maxHeight: screenHeight * theme.dialogMaxHeightFactor,
                ),
                child: SizedBox(
                  height: screenHeight * theme.dialogMaxHeightFactor,
                  child: viewFor(dialogContext),
                ),
              ),
            );
          },
        );
      case GlobePickerMode.fullPage:
        return navigator.push<Object?>(
          MaterialPageRoute<Object?>(
            fullscreenDialog: true,
            builder: (pageContext) => Scaffold(
              backgroundColor: theme.backgroundColor,
              body: SafeArea(bottom: false, child: viewFor(pageContext)),
            ),
          ),
        );
      case GlobePickerMode.cupertinoSheet:
        return showCupertinoModalPopup<Object?>(
          context: context,
          useRootNavigator: useRootNavigator,
          barrierDismissible: isDismissible,
          builder: (sheetContext) => _KeyboardAwareSizedBox(
            heightFactor: theme.heightFactor,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(theme.borderRadius),
              ),
              child: ColoredBox(
                color: CupertinoTheme.of(sheetContext).scaffoldBackgroundColor,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: viewFor(sheetContext, cupertino: true),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// The small bar at the top of bottom sheets.
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Gives a modal picker a fixed share of the screen height, and moves its
/// content above the keyboard.
class _KeyboardAwareSizedBox extends StatelessWidget {
  const _KeyboardAwareSizedBox({
    required this.heightFactor,
    required this.child,
  });

  final double heightFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;
    final height = (availableHeight * heightFactor).clamp(0.0, availableHeight);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: (height - keyboardHeight).clamp(height * 0.4, height),
        child: child,
      ),
    );
  }
}
