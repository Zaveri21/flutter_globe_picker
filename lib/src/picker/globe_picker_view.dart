import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/src/globe_data.dart';
import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_builder.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_controller.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_options.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_theme.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_type.dart';
import 'package:flutter_globe_picker/src/widgets/globe_list_tile.dart';
import 'package:flutter_globe_picker/src/widgets/globe_search_bar.dart';

/// The complete picker UI (title, search bar, sectioned list) as a widget.
///
/// Embed it in your own screen, sheet or dialog, or let `GlobePicker` open
/// it for you.
///
/// ```dart
/// GlobePickerView(
///   type: GlobePickerType.country,
///   onSelected: (country) => setState(() => selected = country),
/// )
/// ```
class GlobePickerView<T extends GlobeItem> extends StatefulWidget {
  /// Creates a picker view.
  const GlobePickerView({
    required this.type,
    this.options = const GlobePickerOptions(),
    this.items,
    this.builders,
    this.controller,
    this.selected = const [],
    this.multiSelect = false,
    this.onSelected,
    this.onConfirm,
    this.onClose,
    this.useCupertinoSearch = false,
    super.key,
  });

  /// What to list.
  final GlobePickerType<T> type;

  /// Filter, display, search, grouping, theme and strings.
  final GlobePickerOptions options;

  /// Your own list of items. `null` lists every item of [type].
  final List<T>? items;

  /// Custom builders replacing parts of the default UI.
  final GlobePickerBuilders<T>? builders;

  /// Optional external controller for query and selection.
  final GlobePickerController<T>? controller;

  /// Ids selected when the view opens. Ignored when [controller] is given.
  final List<String> selected;

  /// Whether several items can be selected.
  final bool multiSelect;

  /// Called when an item is tapped in single select mode.
  final ValueChanged<T>? onSelected;

  /// Called with the selection when a multi-select view is confirmed.
  final ValueChanged<List<T>>? onConfirm;

  /// Called by the close button. The button is hidden when `null`.
  final VoidCallback? onClose;

  /// Uses an iOS style search field.
  final bool useCupertinoSearch;

  @override
  State<GlobePickerView<T>> createState() => _GlobePickerViewState<T>();
}

class _GlobePickerViewState<T extends GlobeItem>
    extends State<GlobePickerView<T>> {
  late final TextEditingController _searchTextController;
  GlobePickerController<T>? _ownedController;
  Timer? _debounceTimer;

  /// The query the search field last showed, to tell outside changes from
  /// typing.
  late String _lastQuery;

  /// Whether [GlobePickerView.selected] was resolved into the owned
  /// controller; it needs the data, which may still be loading.
  bool _selectionResolved = false;

  GlobePickerController<T> get _controller =>
      widget.controller ??
      (_ownedController ??= GlobePickerController<T>(
        initialSelection: GlobeData.isLoadedFrom(widget.options.dataSource)
            ? _resolveSelected()
            : const [],
      ));

  /// The preselected items that exist and that the filter and [items]
  /// show, so a confirm never returns an item the user could not see.
  List<T> _resolveSelected() {
    _selectionResolved = true;
    final items = widget.items;
    return [
      for (final id in widget.selected)
        if (widget.type.itemById(id) case final item?
            when widget.options.filter.matches(item) &&
                (items == null || items.contains(item)))
          item,
    ];
  }

  @override
  void initState() {
    super.initState();
    _lastQuery = _controller.query;
    _searchTextController = TextEditingController(text: _lastQuery);
    _controller.addListener(_syncSearchText);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owned = _ownedController;
    if (owned == null || _selectionResolved || widget.selected.isEmpty) return;
    _selectionResolved = true;
    GlobeData.ensureLoaded(
      widget.options.dataSource,
      DefaultAssetBundle.of(context),
    ).then((_) {
      if (mounted && identical(owned, _ownedController)) {
        owned.setSelection(_resolveSelected());
      }
    }, onError: (_) {}); // GlobeDataLoader reports load errors.
  }

  @override
  void didUpdateWidget(GlobePickerView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController)?.removeListener(
        _syncSearchText,
      );
      if (widget.controller != null) {
        _ownedController?.dispose();
        _ownedController = null;
      }
      _controller.addListener(_syncSearchText);
      _syncSearchText();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_syncSearchText);
    _ownedController?.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  /// Keeps the search field in sync when the query is changed from outside.
  /// Other changes (a selection) leave the field alone, even while a
  /// debounced query is pending.
  void _syncSearchText() {
    final query = _controller.query;
    if (query == _lastQuery) return;
    _lastQuery = query;
    if (_searchTextController.text != query) {
      // The outside change wins over what was typed before it.
      _debounceTimer?.cancel();
      _searchTextController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  void _handleSearchChanged(String query) {
    _debounceTimer?.cancel();
    final debounce = widget.options.search.debounce;
    if (debounce == Duration.zero) {
      _controller.search(query);
    } else {
      _debounceTimer = Timer(debounce, () {
        if (mounted) _controller.search(query);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobePickerBuilder<T>(
      type: widget.type,
      options: widget.options,
      items: widget.items,
      controller: _controller,
      multiSelect: widget.multiSelect,
      onSelected: widget.onSelected,
      onConfirm: widget.onConfirm,
      onClose: widget.onClose,
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, GlobePickerSnapshot<T> snapshot) {
    final options = widget.options;
    final builders = widget.builders;
    final theme = GlobePickerTheme.resolve(context, options.theme);

    final header =
        builders?.headerBuilder?.call(context, snapshot) ??
        (options.display.showTitle
            ? _DefaultHeader(
                title: options.title ?? snapshot.strings.titleFor(widget.type),
                theme: theme,
                closeTooltip: snapshot.strings.close,
                onClose: options.display.showCloseButton && snapshot.canClose
                    ? snapshot.close
                    : null,
              )
            : null);

    final searchBar = options.search.enabled
        ? (builders?.searchBarBuilder?.call(
                context,
                _searchTextController,
                _handleSearchChanged,
              ) ??
              Padding(
                padding: theme.searchPadding,
                child: GlobeSearchBar(
                  controller: _searchTextController,
                  onChanged: _handleSearchChanged,
                  hintText: options.search.hint ?? snapshot.strings.searchHint,
                  clearTooltip: snapshot.strings.clearSearch,
                  autofocus: options.search.autoFocus,
                  decoration: theme.searchDecoration,
                  style: theme.searchTextStyle,
                  useCupertinoStyle: widget.useCupertinoSearch,
                ),
              ))
        : null;

    final body = snapshot.isEmpty
        ? (builders?.emptyBuilder?.call(context, snapshot.query) ??
              _DefaultEmptyView(
                message: snapshot.strings.noResults,
                style: theme.emptyTextStyle,
              ))
        : _buildList(context, snapshot, theme);

    final footer =
        builders?.footerBuilder?.call(context, snapshot) ??
        (widget.multiSelect
            ? _DefaultConfirmBar(
                label: snapshot.strings.selectedCount(
                  snapshot.strings.done,
                  snapshot.selection.length,
                ),
                onConfirm: snapshot.confirm,
              )
            : null);

    final content = Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?header,
          ?searchBar,
          Expanded(child: body),
          ?footer,
        ],
      ),
    );
    return builders?.containerBuilder?.call(context, content) ?? content;
  }

  Widget _buildList(
    BuildContext context,
    GlobePickerSnapshot<T> snapshot,
    GlobePickerThemeData theme,
  ) {
    final options = widget.options;
    final display = options.display;
    final builders = widget.builders;
    final rows = <_PickerRow<T>>[];
    for (final section in snapshot.sections) {
      final title = section.title;
      if (display.showSectionHeaders && title != null) {
        rows.add(_SectionHeaderRow(title));
      }
      for (var index = 0; index < section.items.length; index++) {
        if (display.showDividers && index > 0) rows.add(_DividerRow<T>());
        rows.add(_ItemRow(section.items[index]));
      }
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      itemCount: rows.length,
      itemBuilder: (context, index) => switch (rows[index]) {
        _SectionHeaderRow(:final title) =>
          builders?.sectionHeaderBuilder?.call(context, title) ??
              _DefaultSectionHeader(title: title, theme: theme),
        _DividerRow() =>
          builders?.separatorBuilder?.call(context) ??
              Divider(height: 1, color: theme.dividerColor),
        _ItemRow(:final item) => _buildItem(context, snapshot, theme, item),
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    GlobePickerSnapshot<T> snapshot,
    GlobePickerThemeData theme,
    T item,
  ) {
    final options = widget.options;
    final display = options.display;
    final builders = widget.builders;
    final isSelected = snapshot.isSelected(item);
    void onTap() => snapshot.onItemTap(item);
    final customItem = builders?.itemBuilder?.call(
      context,
      item,
      isSelected,
      onTap,
    );
    if (customItem != null) return customItem;
    return GlobeListTile<T>(
      item: item,
      fields: display.fields ?? widget.type.defaultFields,
      trailingFields:
          display.trailingFields ?? widget.type.defaultTrailingFields,
      onTap: onTap,
      isSelected: isSelected,
      locale: snapshot.locale,
      theme: theme,
      strings: snapshot.strings,
      flagType: display.flagType,
      flagShape: display.flagShape,
      showSelectedIndicator: display.showSelectedIndicator,
      flag: builders?.flagBuilder?.call(context, item),
      selectedIndicator: builders?.selectedIndicatorBuilder?.call(
        context,
        isSelected,
      ),
    );
  }
}

sealed class _PickerRow<T extends GlobeItem> {
  const _PickerRow();
}

final class _SectionHeaderRow<T extends GlobeItem> extends _PickerRow<T> {
  const _SectionHeaderRow(this.title);
  final String title;
}

final class _DividerRow<T extends GlobeItem> extends _PickerRow<T> {
  const _DividerRow();
}

final class _ItemRow<T extends GlobeItem> extends _PickerRow<T> {
  const _ItemRow(this.item);
  final T item;
}

class _DefaultHeader extends StatelessWidget {
  const _DefaultHeader({
    required this.title,
    required this.theme,
    required this.closeTooltip,
    required this.onClose,
  });

  final String title;
  final GlobePickerThemeData theme;
  final String closeTooltip;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: theme.headerPadding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.titleStyle),
            ),
          ),
          if (onClose != null)
            IconButton(
              tooltip: closeTooltip,
              icon: Icon(Icons.close, color: theme.closeIconColor),
              onPressed: onClose,
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _DefaultSectionHeader extends StatelessWidget {
  const _DefaultSectionHeader({required this.title, required this.theme});

  final String title;
  final GlobePickerThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Container(
        color: theme.sectionHeaderBackgroundColor,
        padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 8),
        child: Text(title, style: theme.sectionHeaderStyle),
      ),
    );
  }
}

class _DefaultEmptyView extends StatelessWidget {
  const _DefaultEmptyView({required this.message, required this.style});

  final String message;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: style.color),
            const SizedBox(height: 12),
            Text(message, style: style, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DefaultConfirmBar extends StatelessWidget {
  const _DefaultConfirmBar({required this.label, required this.onConfirm});

  final String label;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(onPressed: onConfirm, child: Text(label)),
      ),
    );
  }
}
