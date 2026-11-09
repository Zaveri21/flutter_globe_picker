import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/src/filter/globe_filter.dart';
import 'package:flutter_globe_picker/src/globe_data_source.dart';
import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_builder.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_theme.dart';
import 'package:flutter_globe_picker/src/picker/globe_strings.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';

/// How a modal picker opens.
enum GlobePickerMode {
  /// Material bottom sheet (default).
  bottomSheet,

  /// Centered dialog.
  dialog,

  /// Full screen page pushed on the navigator.
  fullPage,

  /// iOS style modal sheet with a Cupertino search field.
  cupertinoSheet,
}

/// How the list is split into sections.
enum GlobeGroupBy {
  /// One continuous list.
  none,

  /// A, B, C section headers.
  alphabet,

  /// One section per region (Africa, Americas, ...).
  region,
}

/// How flags are drawn.
enum GlobeFlagType {
  /// SVG flags on platforms without flag emoji (Windows, Linux), emoji
  /// elsewhere.
  auto,

  /// Emoji flags. Small and fast, but Windows shows letters instead.
  emoji,

  /// Bundled SVG flags. Look the same on every platform.
  svg,
}

/// Shape of a flag.
enum GlobeFlagShape {
  /// 4:3 rectangle with rounded corners.
  rectangle,

  /// 1:1 square with rounded corners.
  square,

  /// Circle.
  circle,
}

/// What each row shows and which parts of the picker are visible.
@immutable
class GlobeDisplay {
  /// Creates display options.
  const GlobeDisplay({
    this.fields,
    this.trailingFields,
    this.flagType = GlobeFlagType.auto,
    this.flagShape = GlobeFlagShape.rectangle,
    this.showTitle = true,
    this.showCloseButton = true,
    this.showDragHandle = true,
    this.showDividers = false,
    this.showSelectedIndicator = true,
    this.showSectionHeaders = true,
    this.useLocalizedNames = true,
  });

  /// Row content: the first text field is the title, the other text fields
  /// form the subtitle, and [GlobeField.flag] adds the flag. `null` uses the
  /// picker type's defaults.
  final List<GlobeField>? fields;

  /// Text shown at the end of each row, for example the dial code. `null`
  /// uses the picker type's defaults, an empty list shows nothing.
  final List<GlobeField>? trailingFields;

  /// Emoji or SVG flags.
  final GlobeFlagType flagType;

  /// Flag shape.
  final GlobeFlagShape flagShape;

  /// Shows the title row.
  final bool showTitle;

  /// Shows the close button in the title row.
  final bool showCloseButton;

  /// Shows the drag handle on bottom sheets.
  final bool showDragHandle;

  /// Draws a divider between rows.
  final bool showDividers;

  /// Shows a check mark on selected rows.
  final bool showSelectedIndicator;

  /// Shows section headers (Favorites, Recent, A, B, ...).
  final bool showSectionHeaders;

  /// Shows country and currency names in the app's language, sorted by
  /// them, when the loaded translations have it. English otherwise.
  final bool useLocalizedNames;

  /// Returns a copy with the given options replaced.
  GlobeDisplay copyWith({
    List<GlobeField>? fields,
    List<GlobeField>? trailingFields,
    GlobeFlagType? flagType,
    GlobeFlagShape? flagShape,
    bool? showTitle,
    bool? showCloseButton,
    bool? showDragHandle,
    bool? showDividers,
    bool? showSelectedIndicator,
    bool? showSectionHeaders,
    bool? useLocalizedNames,
  }) => GlobeDisplay(
    fields: fields ?? this.fields,
    trailingFields: trailingFields ?? this.trailingFields,
    flagType: flagType ?? this.flagType,
    flagShape: flagShape ?? this.flagShape,
    showTitle: showTitle ?? this.showTitle,
    showCloseButton: showCloseButton ?? this.showCloseButton,
    showDragHandle: showDragHandle ?? this.showDragHandle,
    showDividers: showDividers ?? this.showDividers,
    showSelectedIndicator: showSelectedIndicator ?? this.showSelectedIndicator,
    showSectionHeaders: showSectionHeaders ?? this.showSectionHeaders,
    useLocalizedNames: useLocalizedNames ?? this.useLocalizedNames,
  );
}

/// Search bar behaviour.
@immutable
class GlobeSearchConfig {
  /// Creates search options.
  const GlobeSearchConfig({
    this.enabled = true,
    this.hint,
    this.fields,
    this.autoFocus = false,
    this.minChars = 1,
    this.debounce = Duration.zero,
  }) : assert(minChars >= 0, 'minChars cannot be negative');

  /// Shows the search bar.
  final bool enabled;

  /// Hint text. `null` uses [GlobeStrings.searchHint].
  final String? hint;

  /// Searched fields. `null` uses the picker type's defaults.
  final List<GlobeField>? fields;

  /// Opens the keyboard when the picker opens.
  final bool autoFocus;

  /// Queries shorter than this show the full list.
  final int minChars;

  /// Waits this long after the last keystroke before searching.
  final Duration debounce;

  /// Returns a copy with the given options replaced.
  GlobeSearchConfig copyWith({
    bool? enabled,
    String? hint,
    List<GlobeField>? fields,
    bool? autoFocus,
    int? minChars,
    Duration? debounce,
  }) => GlobeSearchConfig(
    enabled: enabled ?? this.enabled,
    hint: hint ?? this.hint,
    fields: fields ?? this.fields,
    autoFocus: autoFocus ?? this.autoFocus,
    minChars: minChars ?? this.minChars,
    debounce: debounce ?? this.debounce,
  );
}

/// Builds one row. Call [onTap] to select the item.
typedef GlobeItemBuilder<T extends GlobeItem> = Widget Function(
  BuildContext context,
  T item,
  bool isSelected,
  VoidCallback onTap,
);

/// Builds a part of the picker from its current state.
typedef GlobeSnapshotBuilder<T extends GlobeItem> = Widget Function(
  BuildContext context,
  GlobePickerSnapshot<T> snapshot,
);

/// Builds the search bar. Call [onChanged] with the new query.
typedef GlobeSearchBarBuilder = Widget Function(
  BuildContext context,
  TextEditingController textController,
  ValueChanged<String> onChanged,
);

/// Builds a section header from its title.
typedef GlobeSectionHeaderBuilder = Widget Function(
  BuildContext context,
  String title,
);

/// Builds the widget shown when a search finds nothing.
typedef GlobeEmptyBuilder = Widget Function(BuildContext context, String query);

/// Wraps the whole picker, for example to add a background or padding.
typedef GlobeContainerBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

/// Replace any part of the default picker UI. Every builder is optional;
/// parts without a builder use the default look.
///
/// The shortcuts infer the item type:
///
/// ```dart
/// GlobePicker.currency(
///   context,
///   builders: GlobePickerBuilders(
///     itemBuilder: (context, currency, isSelected, onTap) => ListTile(
///       title: Text('${currency.name} (${currency.symbol})'),
///       onTap: onTap,
///     ),
///   ),
/// );
/// ```
///
/// With generic widgets such as `GlobePickerView`, name the item type so the
/// callbacks are typed: `GlobePickerView<GlobeCurrency>(...)` or
/// `GlobePickerBuilders<GlobeCurrency>(...)`.
@immutable
class GlobePickerBuilders<T extends GlobeItem> {
  /// Creates builders.
  const GlobePickerBuilders({
    this.itemBuilder,
    this.headerBuilder,
    this.searchBarBuilder,
    this.sectionHeaderBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
    this.flagBuilder,
    this.selectedIndicatorBuilder,
    this.footerBuilder,
    this.containerBuilder,
  });

  /// Builds each row.
  final GlobeItemBuilder<T>? itemBuilder;

  /// Builds the title row.
  final GlobeSnapshotBuilder<T>? headerBuilder;

  /// Builds the search bar.
  final GlobeSearchBarBuilder? searchBarBuilder;

  /// Builds section headers.
  final GlobeSectionHeaderBuilder? sectionHeaderBuilder;

  /// Builds the divider between rows (when dividers are shown).
  final WidgetBuilder? separatorBuilder;

  /// Builds the "No results" view.
  final GlobeEmptyBuilder? emptyBuilder;

  /// Builds the flag of a row.
  final Widget Function(BuildContext context, T item)? flagBuilder;

  /// Builds the selected indicator of a row.
  final Widget Function(BuildContext context, bool isSelected)?
  selectedIndicatorBuilder;

  /// Builds a footer below the list. Multi-select pickers show a Done button
  /// here by default.
  final GlobeSnapshotBuilder<T>? footerBuilder;

  /// Wraps the whole picker.
  final GlobeContainerBuilder? containerBuilder;
}

/// Every non-visual-builder option of a picker in one reusable object.
///
/// It is not generic, so one instance can be shared by pickers of different
/// types. Typed parts (`items` and `builders`) are passed separately.
///
/// ```dart
/// const options = GlobePickerOptions(
///   filter: GlobeFilter(excludeCountries: ['AQ']),
///   groupBy: GlobeGroupBy.alphabet,
/// );
/// ```
@immutable
class GlobePickerOptions {
  /// Creates picker options.
  const GlobePickerOptions({
    this.filter = GlobeFilter.none,
    this.display = const GlobeDisplay(),
    this.search = const GlobeSearchConfig(),
    this.groupBy = GlobeGroupBy.none,
    this.favorites = const [],
    this.showRecents = false,
    this.title,
    this.theme,
    this.strings,
    this.dataSource,
  });

  /// Filter applied to the list.
  final GlobeFilter filter;

  /// Row content and visible parts.
  final GlobeDisplay display;

  /// Search bar behaviour.
  final GlobeSearchConfig search;

  /// Section grouping.
  final GlobeGroupBy groupBy;

  /// Ids pinned in a Favorites section at the top (alpha-2 codes, currency
  /// codes, dial codes or date patterns).
  final List<String> favorites;

  /// Shows recently selected items at the top. See `GlobeRecents`.
  final bool showRecents;

  /// Title text. `null` uses the strings' title for the picker type.
  final String? title;

  /// Visual style. Merged over the app's `GlobePickerTheme`.
  final GlobePickerTheme? theme;

  /// Texts. `null` uses English.
  final GlobeStrings? strings;

  /// Where the data comes from, for example your updated copy of
  /// `globe_data.json` or a few overrides. `null` uses the data already
  /// loaded, or the bundled data, which the picker then loads by itself.
  final GlobeDataSource? dataSource;

  /// Returns a copy with the given options replaced.
  GlobePickerOptions copyWith({
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
  }) => GlobePickerOptions(
    filter: filter ?? this.filter,
    display: display ?? this.display,
    search: search ?? this.search,
    groupBy: groupBy ?? this.groupBy,
    favorites: favorites ?? this.favorites,
    showRecents: showRecents ?? this.showRecents,
    title: title ?? this.title,
    theme: theme ?? this.theme,
    strings: strings ?? this.strings,
    dataSource: dataSource ?? this.dataSource,
  );
}
