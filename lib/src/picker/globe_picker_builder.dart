import 'package:flutter/widgets.dart';
import 'package:flutter_globe_picker/src/globe_data.dart';
import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_controller.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_options.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_type.dart';
import 'package:flutter_globe_picker/src/picker/globe_recents.dart';
import 'package:flutter_globe_picker/src/picker/globe_strings.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';
import 'package:flutter_globe_picker/src/search/globe_search.dart';
import 'package:flutter_globe_picker/src/widgets/globe_data_loader.dart';

/// Kind of a [GlobePickerSection].
enum GlobePickerSectionKind {
  /// Items pinned with `favorites`.
  favorites,

  /// Recently selected items.
  recents,

  /// A group made by `groupBy` (a letter or a region).
  group,

  /// The full list without grouping.
  all,

  /// Search results.
  results,
}

/// A titled part of the picker list.
@immutable
class GlobePickerSection<T extends GlobeItem> {
  /// Creates a section.
  const GlobePickerSection({
    required this.kind,
    required this.items,
    this.title,
  });

  /// What this section contains.
  final GlobePickerSectionKind kind;

  /// Header text, or `null` for a section without header.
  final String? title;

  /// Items in display order.
  final List<T> items;
}

/// Everything needed to draw a picker: the visible sections, the query,
/// the selection and the actions. Given to [GlobePickerBuilder.builder] and
/// to the builders in `GlobePickerBuilders`.
class GlobePickerSnapshot<T extends GlobeItem> {
  /// Creates a snapshot. Normally created by [GlobePickerBuilder].
  GlobePickerSnapshot({
    required this.type,
    required this.options,
    required this.sections,
    required this.query,
    required this.isSearching,
    required this.selection,
    required this.multiSelect,
    required this.locale,
    required this.strings,
    required this.controller,
    required this._onItemTap,
    required this._onConfirm,
    required this._onClose,
  });

  /// The picker type.
  final GlobePickerType<T> type;

  /// The options the picker was built with.
  final GlobePickerOptions options;

  /// Visible sections in order. Empty when a search finds nothing.
  final List<GlobePickerSection<T>> sections;

  /// Current search text.
  final String query;

  /// Whether a search is active (the query is long enough).
  final bool isSearching;

  /// Selected items.
  final List<T> selection;

  /// Whether several items can be selected.
  final bool multiSelect;

  /// Locale of the translated names shown, or `null` for English.
  final Locale? locale;

  /// Texts in use.
  final GlobeStrings strings;

  /// The controller holding query and selection.
  final GlobePickerController<T> controller;

  final void Function(T item) _onItemTap;
  final VoidCallback _onConfirm;
  final VoidCallback? _onClose;

  /// Every visible item once, in display order.
  late final List<T> items = () {
    final seen = <T>{};
    return [
      for (final section in sections)
        for (final item in section.items)
          if (seen.add(item)) item,
    ];
  }();

  /// Whether nothing is visible.
  bool get isEmpty => sections.every((section) => section.items.isEmpty);

  /// Whether [item] is selected.
  bool isSelected(T item) => selection.contains(item);

  /// Whether [item] is in the favorites list.
  bool isFavorite(T item) =>
      options.favorites.any((id) => type.itemById(id) == item);

  /// Selects [item] (single select) or toggles it (multi-select), exactly
  /// like tapping its row.
  void onItemTap(T item) => _onItemTap(item);

  /// Sets the search text.
  void search(String query) => controller.search(query);

  /// Confirms a multi-select picker with the current selection.
  void confirm() => _onConfirm();

  /// Closes the picker without a result (modal pickers only).
  void close() => _onClose?.call();

  /// Whether the picker can be closed by [close].
  bool get canClose => _onClose != null;
}

/// Headless picker: does the filtering, sorting, searching, grouping and
/// selection, and lets you draw everything yourself.
///
/// ```dart
/// GlobePickerBuilder(
///   type: GlobePickerType.currency,
///   onSelected: (currency) => print(currency.code),
///   builder: (context, snapshot) => Column(
///     children: [
///       TextField(onChanged: snapshot.search),
///       for (final currency in snapshot.items)
///         ListTile(
///           title: Text(currency.name),
///           onTap: () => snapshot.onItemTap(currency),
///         ),
///     ],
///   ),
/// );
/// ```
class GlobePickerBuilder<T extends GlobeItem> extends StatefulWidget {
  /// Creates a headless picker.
  const GlobePickerBuilder({
    required this.type,
    required this.builder,
    this.options = const GlobePickerOptions(),
    this.items,
    this.controller,
    this.multiSelect = false,
    this.onSelected,
    this.onConfirm,
    this.onClose,
    super.key,
  });

  /// What to list.
  final GlobePickerType<T> type;

  /// Draws the picker.
  final GlobeSnapshotBuilder<T> builder;

  /// Filter, search, grouping and favorites.
  final GlobePickerOptions options;

  /// Your own list of items. `null` lists every item of [type].
  final List<T>? items;

  /// Optional external controller for query and selection.
  final GlobePickerController<T>? controller;

  /// Whether several items can be selected.
  final bool multiSelect;

  /// Called when an item is tapped in single select mode.
  final ValueChanged<T>? onSelected;

  /// Called with the selection when a multi-select picker is confirmed.
  final ValueChanged<List<T>>? onConfirm;

  /// Called when the picker asks to close without a result.
  final VoidCallback? onClose;

  @override
  State<GlobePickerBuilder<T>> createState() => _GlobePickerBuilderState<T>();
}

class _GlobePickerBuilderState<T extends GlobeItem>
    extends State<GlobePickerBuilder<T>> {
  GlobePickerController<T>? _ownedController;
  List<T> _sourceItems = const [];
  Set<T> _sourceItemSet = const {};
  GlobeSearchIndex<T>? _searchIndex;
  Locale? _locale;
  Object? _sourceKey;

  GlobePickerController<T> get _controller =>
      widget.controller ?? (_ownedController ??= GlobePickerController<T>());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChange);
    if (widget.options.showRecents) {
      GlobeRecents.instance.addListener(_handleChange);
    }
  }

  @override
  void didUpdateWidget(GlobePickerBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController)?.removeListener(_handleChange);
      if (widget.controller != null) {
        _ownedController?.dispose();
        _ownedController = null;
      }
      _controller.addListener(_handleChange);
    }
    if (oldWidget.options.showRecents != widget.options.showRecents) {
      if (widget.options.showRecents) {
        GlobeRecents.instance.addListener(_handleChange);
      } else {
        GlobeRecents.instance.removeListener(_handleChange);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    GlobeRecents.instance.removeListener(_handleChange);
    _ownedController?.dispose();
    super.dispose();
  }

  void _handleChange() {
    if (mounted) setState(() {});
  }

  /// Rebuilds the filtered list and the search index when the inputs that
  /// affect them change, including newly loaded data.
  void _refreshSource(BuildContext context) {
    final options = widget.options;
    final locale = _translatedLocale(context);
    final searchFields =
        options.search.fields ?? widget.type.defaultSearchFields;
    final sourceKey = (
      widget.type,
      widget.items,
      options.filter,
      GlobeData.generation,
      locale == null ? '' : translationLanguageFor(locale),
      searchFields.map((field) => field.name).join(','),
    );
    if (sourceKey == _sourceKey) return;
    _sourceKey = sourceKey;
    _locale = locale;

    final filtered = options.filter.apply(widget.items ?? widget.type.items);
    _sourceItems = _sortCountriesByName(filtered, locale);
    _sourceItemSet = _sourceItems.toSet();
    _searchIndex = GlobeSearchIndex<T>(
      _sourceItems,
      fields: searchFields,
      locale: locale,
    );
  }

  /// The app's locale when names are shown translated and the loaded
  /// translations have its language; `null` means English.
  Locale? _translatedLocale(BuildContext context) {
    if (!widget.options.display.useLocalizedNames) return null;
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == null) return null;
    return GlobeData.languages.contains(translationLanguageFor(locale))
        ? locale
        : null;
  }

  /// Sorts the bundled countries by their name in [locale]. They are
  /// already sorted by English name, and other types keep their natural
  /// order (currency code, dial code, usage).
  List<T> _sortCountriesByName(List<T> items, Locale? locale) {
    if (locale == null ||
        widget.items != null ||
        !identical(widget.type, GlobePickerType.country)) {
      return items;
    }
    final sortKeys = {
      for (final item in items)
        item: normalizeSearchText(item.localizedName(locale)),
    };
    return items.toList()
      ..sort((first, second) => sortKeys[first]!.compareTo(sortKeys[second]!));
  }

  @override
  Widget build(BuildContext context) =>
      GlobeDataLoader(source: widget.options.dataSource, builder: _buildLoaded);

  Widget _buildLoaded(BuildContext context) {
    _refreshSource(context);
    final options = widget.options;
    final strings = options.strings ?? GlobeStrings.english;
    final query = _controller.query;
    final isSearching =
        options.search.enabled &&
        // A query of only punctuation, such as `+`, matches everything.
        normalizeSearchText(query).isNotEmpty &&
        query.trim().length >= options.search.minChars;

    final snapshot = GlobePickerSnapshot<T>(
      type: widget.type,
      options: options,
      sections: isSearching ? _searchSections(query) : _browseSections(strings),
      query: query,
      isSearching: isSearching,
      selection: _controller.selection,
      multiSelect: widget.multiSelect,
      locale: _locale,
      strings: strings,
      controller: _controller,
      onItemTap: _handleItemTap,
      onConfirm: () => widget.onConfirm?.call(_controller.selection),
      onClose: widget.onClose,
    );
    return widget.builder(context, snapshot);
  }

  void _handleItemTap(T item) {
    if (widget.multiSelect) {
      _controller.toggle(item);
    } else {
      _controller.select(item);
      widget.onSelected?.call(item);
    }
  }

  List<GlobePickerSection<T>> _searchSections(String query) {
    final results = _searchIndex?.search(query) ?? const [];
    if (results.isEmpty) return const [];
    return [
      GlobePickerSection(kind: GlobePickerSectionKind.results, items: results),
    ];
  }

  List<GlobePickerSection<T>> _browseSections(GlobeStrings strings) {
    final options = widget.options;
    final sections = <GlobePickerSection<T>>[];

    final favorites = <T>{
      for (final id in options.favorites)
        if (widget.type.itemById(id) case final item?
            when _sourceItemSet.contains(item))
          item,
    }.toList();
    if (favorites.isNotEmpty) {
      sections.add(
        GlobePickerSection(
          kind: GlobePickerSectionKind.favorites,
          title: strings.favorites,
          items: favorites,
        ),
      );
    }

    if (options.showRecents) {
      final recents = GlobeRecents.instance
          .itemsFor(widget.type)
          .where(_sourceItemSet.contains)
          .toList();
      if (recents.isNotEmpty) {
        sections.add(
          GlobePickerSection(
            kind: GlobePickerSectionKind.recents,
            title: strings.recents,
            items: recents,
          ),
        );
      }
    }

    switch (options.groupBy) {
      case GlobeGroupBy.none:
        sections.add(
          GlobePickerSection(
            kind: GlobePickerSectionKind.all,
            title: sections.isEmpty ? null : strings.allItems,
            items: _sourceItems,
          ),
        );
      case GlobeGroupBy.alphabet:
        sections.addAll(_groupByLetter());
      case GlobeGroupBy.region:
        sections.addAll(_groupByRegion(strings));
    }
    return sections;
  }

  List<GlobePickerSection<T>> _groupByLetter() {
    final titleField =
        (widget.options.display.fields ?? widget.type.defaultFields).firstWhere(
          (field) => field != GlobeField.flag,
          orElse: () => GlobeField.countryName,
        );
    final groups = <String, List<T>>{};
    for (final item in _sourceItems) {
      final values = globeFieldValues(item, titleField, locale: _locale);
      final label = values.isEmpty ? item.displayName : values.first;
      final normalized = normalizeSearchText(label);
      final letter = normalized.isEmpty
          ? '#'
          : String.fromCharCode(normalized.runes.first).toUpperCase();
      groups.putIfAbsent(letter, () => []).add(item);
    }
    final letters = groups.keys.toList()..sort();
    return [
      for (final letter in letters)
        GlobePickerSection(
          kind: GlobePickerSectionKind.group,
          title: letter,
          items: groups[letter]!,
        ),
    ];
  }

  List<GlobePickerSection<T>> _groupByRegion(GlobeStrings strings) {
    final groups = <String, List<T>>{};
    final regionOrder = <String, int>{};
    for (final item in _sourceItems) {
      final country =
          item.representativeCountry ??
          (item.countries.isEmpty ? null : item.countries.first);
      if (country == null) continue;
      final title = strings.regionName(country.region);
      regionOrder[title] = country.region.index;
      groups.putIfAbsent(title, () => []).add(item);
    }
    final titles = groups.keys.toList()
      ..sort(
        (first, second) => regionOrder[first]!.compareTo(regionOrder[second]!),
      );
    return [
      for (final title in titles)
        GlobePickerSection(
          kind: GlobePickerSectionKind.group,
          title: title,
          items: groups[title]!,
        ),
    ];
  }
}
