import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Visual style of the pickers. Every value is optional: anything left out
/// comes from your app's [ColorScheme] and [TextTheme], so the pickers match
/// light and dark mode with no setup.
///
/// Pass it to one picker:
///
/// ```dart
/// GlobePicker.country(context, theme: const GlobePickerTheme(borderRadius: 24));
/// ```
///
/// Or set it once for the whole app:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(extensions: const [GlobePickerTheme(borderRadius: 24)]),
/// );
/// ```
@immutable
class GlobePickerTheme extends ThemeExtension<GlobePickerTheme> {
  /// Creates a picker theme.
  const GlobePickerTheme({
    this.backgroundColor,
    this.barrierColor,
    this.elevation,
    this.borderRadius,
    this.heightFactor,
    this.dialogMaxWidth,
    this.dialogMaxHeightFactor,
    this.handleColor,
    this.headerPadding,
    this.titleStyle,
    this.closeIconColor,
    this.searchPadding,
    this.searchDecoration,
    this.searchTextStyle,
    this.itemPadding,
    this.itemTitleStyle,
    this.itemSubtitleStyle,
    this.itemTrailingStyle,
    this.selectedTileColor,
    this.selectedIconColor,
    this.sectionHeaderStyle,
    this.sectionHeaderBackgroundColor,
    this.dividerColor,
    this.emptyTextStyle,
    this.flagWidth,
    this.flagHeight,
    this.flagBorderRadius,
  });

  /// Background of the sheet, dialog or page.
  final Color? backgroundColor;

  /// Color behind modal pickers.
  final Color? barrierColor;

  /// Elevation of modal pickers.
  final double? elevation;

  /// Corner radius of the sheet or dialog.
  final double? borderRadius;

  /// Height of the bottom sheet as a fraction of the screen (0 to 1).
  final double? heightFactor;

  /// Maximum width of the dialog.
  final double? dialogMaxWidth;

  /// Maximum height of the dialog as a fraction of the screen (0 to 1).
  final double? dialogMaxHeightFactor;

  /// Color of the bottom sheet drag handle.
  final Color? handleColor;

  /// Padding around the title row.
  final EdgeInsetsGeometry? headerPadding;

  /// Style of the title.
  final TextStyle? titleStyle;

  /// Color of the close icon.
  final Color? closeIconColor;

  /// Padding around the search bar.
  final EdgeInsetsGeometry? searchPadding;

  /// Decoration of the search bar. Merged with the default decoration.
  final InputDecoration? searchDecoration;

  /// Text style of the search bar.
  final TextStyle? searchTextStyle;

  /// Padding inside each row.
  final EdgeInsetsGeometry? itemPadding;

  /// Style of the row title.
  final TextStyle? itemTitleStyle;

  /// Style of the row subtitle.
  final TextStyle? itemSubtitleStyle;

  /// Style of the text at the end of a row (dial code, symbol, ...).
  final TextStyle? itemTrailingStyle;

  /// Background of selected rows.
  final Color? selectedTileColor;

  /// Color of the selected check mark.
  final Color? selectedIconColor;

  /// Style of section headers (Favorites, A, B, ...).
  final TextStyle? sectionHeaderStyle;

  /// Background of section headers.
  final Color? sectionHeaderBackgroundColor;

  /// Color of row dividers.
  final Color? dividerColor;

  /// Style of the "No results" text.
  final TextStyle? emptyTextStyle;

  /// Width of flags in rows.
  final double? flagWidth;

  /// Height of flags in rows.
  final double? flagHeight;

  /// Corner radius of rectangular flags.
  final double? flagBorderRadius;

  /// The theme set on the nearest [Theme], or `null`.
  static GlobePickerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobePickerTheme>();

  /// Combines the app theme, [override] and defaults from [ColorScheme] into
  /// a theme where every value is set.
  static GlobePickerThemeData resolve(
    BuildContext context, [
    GlobePickerTheme? override,
  ]) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final merged = (maybeOf(context) ?? const GlobePickerTheme()).merge(
      override,
    );
    return GlobePickerThemeData(
      backgroundColor: merged.backgroundColor ?? colors.surfaceContainerLow,
      barrierColor: merged.barrierColor ?? Colors.black54,
      elevation: merged.elevation ?? 1,
      borderRadius: merged.borderRadius ?? 28,
      heightFactor: (merged.heightFactor ?? 0.85).clamp(0.2, 1.0),
      dialogMaxWidth: merged.dialogMaxWidth ?? 480,
      dialogMaxHeightFactor: (merged.dialogMaxHeightFactor ?? 0.8).clamp(
        0.2,
        1.0,
      ),
      handleColor:
          merged.handleColor ?? colors.onSurfaceVariant.withValues(alpha: 0.4),
      headerPadding:
          merged.headerPadding ??
          const EdgeInsetsDirectional.fromSTEB(24, 16, 12, 8),
      titleStyle:
          merged.titleStyle ??
          text.titleLarge?.copyWith(color: colors.onSurface) ??
          TextStyle(fontSize: 22, color: colors.onSurface),
      closeIconColor: merged.closeIconColor ?? colors.onSurfaceVariant,
      searchPadding:
          merged.searchPadding ?? const EdgeInsets.fromLTRB(16, 4, 16, 8),
      searchDecoration: merged.searchDecoration,
      searchTextStyle:
          merged.searchTextStyle ??
          text.bodyLarge ??
          const TextStyle(fontSize: 16),
      itemPadding:
          merged.itemPadding ??
          const EdgeInsetsDirectional.only(start: 24, end: 20),
      itemTitleStyle:
          merged.itemTitleStyle ??
          text.bodyLarge?.copyWith(color: colors.onSurface) ??
          TextStyle(fontSize: 16, color: colors.onSurface),
      itemSubtitleStyle:
          merged.itemSubtitleStyle ??
          text.bodyMedium?.copyWith(color: colors.onSurfaceVariant) ??
          TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
      itemTrailingStyle:
          merged.itemTrailingStyle ??
          text.bodyMedium?.copyWith(color: colors.onSurfaceVariant) ??
          TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
      selectedTileColor:
          merged.selectedTileColor ??
          colors.secondaryContainer.withValues(alpha: 0.6),
      selectedIconColor: merged.selectedIconColor ?? colors.primary,
      sectionHeaderStyle:
          merged.sectionHeaderStyle ??
          text.labelLarge?.copyWith(color: colors.primary) ??
          TextStyle(fontSize: 14, color: colors.primary),
      sectionHeaderBackgroundColor:
          merged.sectionHeaderBackgroundColor ?? Colors.transparent,
      dividerColor: merged.dividerColor ?? colors.outlineVariant,
      emptyTextStyle:
          merged.emptyTextStyle ??
          text.bodyLarge?.copyWith(color: colors.onSurfaceVariant) ??
          TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
      flagWidth: merged.flagWidth ?? 32,
      flagHeight: merged.flagHeight ?? 24,
      flagBorderRadius: merged.flagBorderRadius ?? 4,
    );
  }

  /// Returns a theme where the values set in [other] replace these.
  GlobePickerTheme merge(GlobePickerTheme? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      barrierColor: other.barrierColor,
      elevation: other.elevation,
      borderRadius: other.borderRadius,
      heightFactor: other.heightFactor,
      dialogMaxWidth: other.dialogMaxWidth,
      dialogMaxHeightFactor: other.dialogMaxHeightFactor,
      handleColor: other.handleColor,
      headerPadding: other.headerPadding,
      titleStyle: titleStyle?.merge(other.titleStyle) ?? other.titleStyle,
      closeIconColor: other.closeIconColor,
      searchPadding: other.searchPadding,
      searchDecoration: other.searchDecoration,
      searchTextStyle:
          searchTextStyle?.merge(other.searchTextStyle) ??
          other.searchTextStyle,
      itemPadding: other.itemPadding,
      itemTitleStyle:
          itemTitleStyle?.merge(other.itemTitleStyle) ?? other.itemTitleStyle,
      itemSubtitleStyle:
          itemSubtitleStyle?.merge(other.itemSubtitleStyle) ??
          other.itemSubtitleStyle,
      itemTrailingStyle:
          itemTrailingStyle?.merge(other.itemTrailingStyle) ??
          other.itemTrailingStyle,
      selectedTileColor: other.selectedTileColor,
      selectedIconColor: other.selectedIconColor,
      sectionHeaderStyle:
          sectionHeaderStyle?.merge(other.sectionHeaderStyle) ??
          other.sectionHeaderStyle,
      sectionHeaderBackgroundColor: other.sectionHeaderBackgroundColor,
      dividerColor: other.dividerColor,
      emptyTextStyle:
          emptyTextStyle?.merge(other.emptyTextStyle) ?? other.emptyTextStyle,
      flagWidth: other.flagWidth,
      flagHeight: other.flagHeight,
      flagBorderRadius: other.flagBorderRadius,
    );
  }

  @override
  GlobePickerTheme copyWith({
    Color? backgroundColor,
    Color? barrierColor,
    double? elevation,
    double? borderRadius,
    double? heightFactor,
    double? dialogMaxWidth,
    double? dialogMaxHeightFactor,
    Color? handleColor,
    EdgeInsetsGeometry? headerPadding,
    TextStyle? titleStyle,
    Color? closeIconColor,
    EdgeInsetsGeometry? searchPadding,
    InputDecoration? searchDecoration,
    TextStyle? searchTextStyle,
    EdgeInsetsGeometry? itemPadding,
    TextStyle? itemTitleStyle,
    TextStyle? itemSubtitleStyle,
    TextStyle? itemTrailingStyle,
    Color? selectedTileColor,
    Color? selectedIconColor,
    TextStyle? sectionHeaderStyle,
    Color? sectionHeaderBackgroundColor,
    Color? dividerColor,
    TextStyle? emptyTextStyle,
    double? flagWidth,
    double? flagHeight,
    double? flagBorderRadius,
  }) => GlobePickerTheme(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    barrierColor: barrierColor ?? this.barrierColor,
    elevation: elevation ?? this.elevation,
    borderRadius: borderRadius ?? this.borderRadius,
    heightFactor: heightFactor ?? this.heightFactor,
    dialogMaxWidth: dialogMaxWidth ?? this.dialogMaxWidth,
    dialogMaxHeightFactor: dialogMaxHeightFactor ?? this.dialogMaxHeightFactor,
    handleColor: handleColor ?? this.handleColor,
    headerPadding: headerPadding ?? this.headerPadding,
    titleStyle: titleStyle ?? this.titleStyle,
    closeIconColor: closeIconColor ?? this.closeIconColor,
    searchPadding: searchPadding ?? this.searchPadding,
    searchDecoration: searchDecoration ?? this.searchDecoration,
    searchTextStyle: searchTextStyle ?? this.searchTextStyle,
    itemPadding: itemPadding ?? this.itemPadding,
    itemTitleStyle: itemTitleStyle ?? this.itemTitleStyle,
    itemSubtitleStyle: itemSubtitleStyle ?? this.itemSubtitleStyle,
    itemTrailingStyle: itemTrailingStyle ?? this.itemTrailingStyle,
    selectedTileColor: selectedTileColor ?? this.selectedTileColor,
    selectedIconColor: selectedIconColor ?? this.selectedIconColor,
    sectionHeaderStyle: sectionHeaderStyle ?? this.sectionHeaderStyle,
    sectionHeaderBackgroundColor:
        sectionHeaderBackgroundColor ?? this.sectionHeaderBackgroundColor,
    dividerColor: dividerColor ?? this.dividerColor,
    emptyTextStyle: emptyTextStyle ?? this.emptyTextStyle,
    flagWidth: flagWidth ?? this.flagWidth,
    flagHeight: flagHeight ?? this.flagHeight,
    flagBorderRadius: flagBorderRadius ?? this.flagBorderRadius,
  );

  @override
  GlobePickerTheme lerp(covariant GlobePickerTheme? other, double progress) {
    if (other == null) return this;
    return GlobePickerTheme(
      backgroundColor: Color.lerp(
        backgroundColor,
        other.backgroundColor,
        progress,
      ),
      barrierColor: Color.lerp(barrierColor, other.barrierColor, progress),
      elevation: lerpDouble(elevation, other.elevation, progress),
      borderRadius: lerpDouble(borderRadius, other.borderRadius, progress),
      heightFactor: lerpDouble(heightFactor, other.heightFactor, progress),
      dialogMaxWidth: lerpDouble(
        dialogMaxWidth,
        other.dialogMaxWidth,
        progress,
      ),
      dialogMaxHeightFactor: lerpDouble(
        dialogMaxHeightFactor,
        other.dialogMaxHeightFactor,
        progress,
      ),
      handleColor: Color.lerp(handleColor, other.handleColor, progress),
      headerPadding: EdgeInsetsGeometry.lerp(
        headerPadding,
        other.headerPadding,
        progress,
      ),
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, progress),
      closeIconColor: Color.lerp(
        closeIconColor,
        other.closeIconColor,
        progress,
      ),
      searchPadding: EdgeInsetsGeometry.lerp(
        searchPadding,
        other.searchPadding,
        progress,
      ),
      searchDecoration: progress < 0.5
          ? searchDecoration
          : other.searchDecoration,
      searchTextStyle: TextStyle.lerp(
        searchTextStyle,
        other.searchTextStyle,
        progress,
      ),
      itemPadding: EdgeInsetsGeometry.lerp(
        itemPadding,
        other.itemPadding,
        progress,
      ),
      itemTitleStyle: TextStyle.lerp(
        itemTitleStyle,
        other.itemTitleStyle,
        progress,
      ),
      itemSubtitleStyle: TextStyle.lerp(
        itemSubtitleStyle,
        other.itemSubtitleStyle,
        progress,
      ),
      itemTrailingStyle: TextStyle.lerp(
        itemTrailingStyle,
        other.itemTrailingStyle,
        progress,
      ),
      selectedTileColor: Color.lerp(
        selectedTileColor,
        other.selectedTileColor,
        progress,
      ),
      selectedIconColor: Color.lerp(
        selectedIconColor,
        other.selectedIconColor,
        progress,
      ),
      sectionHeaderStyle: TextStyle.lerp(
        sectionHeaderStyle,
        other.sectionHeaderStyle,
        progress,
      ),
      sectionHeaderBackgroundColor: Color.lerp(
        sectionHeaderBackgroundColor,
        other.sectionHeaderBackgroundColor,
        progress,
      ),
      dividerColor: Color.lerp(dividerColor, other.dividerColor, progress),
      emptyTextStyle: TextStyle.lerp(
        emptyTextStyle,
        other.emptyTextStyle,
        progress,
      ),
      flagWidth: lerpDouble(flagWidth, other.flagWidth, progress),
      flagHeight: lerpDouble(flagHeight, other.flagHeight, progress),
      flagBorderRadius: lerpDouble(
        flagBorderRadius,
        other.flagBorderRadius,
        progress,
      ),
    );
  }
}

/// A [GlobePickerTheme] with every value resolved. Built by
/// [GlobePickerTheme.resolve] and passed to builders.
@immutable
class GlobePickerThemeData {
  /// Creates resolved theme data.
  const GlobePickerThemeData({
    required this.backgroundColor,
    required this.barrierColor,
    required this.elevation,
    required this.borderRadius,
    required this.heightFactor,
    required this.dialogMaxWidth,
    required this.dialogMaxHeightFactor,
    required this.handleColor,
    required this.headerPadding,
    required this.titleStyle,
    required this.closeIconColor,
    required this.searchPadding,
    required this.searchDecoration,
    required this.searchTextStyle,
    required this.itemPadding,
    required this.itemTitleStyle,
    required this.itemSubtitleStyle,
    required this.itemTrailingStyle,
    required this.selectedTileColor,
    required this.selectedIconColor,
    required this.sectionHeaderStyle,
    required this.sectionHeaderBackgroundColor,
    required this.dividerColor,
    required this.emptyTextStyle,
    required this.flagWidth,
    required this.flagHeight,
    required this.flagBorderRadius,
  });

  /// See [GlobePickerTheme.backgroundColor].
  final Color backgroundColor;

  /// See [GlobePickerTheme.barrierColor].
  final Color barrierColor;

  /// See [GlobePickerTheme.elevation].
  final double elevation;

  /// See [GlobePickerTheme.borderRadius].
  final double borderRadius;

  /// See [GlobePickerTheme.heightFactor].
  final double heightFactor;

  /// See [GlobePickerTheme.dialogMaxWidth].
  final double dialogMaxWidth;

  /// See [GlobePickerTheme.dialogMaxHeightFactor].
  final double dialogMaxHeightFactor;

  /// See [GlobePickerTheme.handleColor].
  final Color handleColor;

  /// See [GlobePickerTheme.headerPadding].
  final EdgeInsetsGeometry headerPadding;

  /// See [GlobePickerTheme.titleStyle].
  final TextStyle titleStyle;

  /// See [GlobePickerTheme.closeIconColor].
  final Color closeIconColor;

  /// See [GlobePickerTheme.searchPadding].
  final EdgeInsetsGeometry searchPadding;

  /// See [GlobePickerTheme.searchDecoration].
  final InputDecoration? searchDecoration;

  /// See [GlobePickerTheme.searchTextStyle].
  final TextStyle searchTextStyle;

  /// See [GlobePickerTheme.itemPadding].
  final EdgeInsetsGeometry itemPadding;

  /// See [GlobePickerTheme.itemTitleStyle].
  final TextStyle itemTitleStyle;

  /// See [GlobePickerTheme.itemSubtitleStyle].
  final TextStyle itemSubtitleStyle;

  /// See [GlobePickerTheme.itemTrailingStyle].
  final TextStyle itemTrailingStyle;

  /// See [GlobePickerTheme.selectedTileColor].
  final Color selectedTileColor;

  /// See [GlobePickerTheme.selectedIconColor].
  final Color selectedIconColor;

  /// See [GlobePickerTheme.sectionHeaderStyle].
  final TextStyle sectionHeaderStyle;

  /// See [GlobePickerTheme.sectionHeaderBackgroundColor].
  final Color sectionHeaderBackgroundColor;

  /// See [GlobePickerTheme.dividerColor].
  final Color dividerColor;

  /// See [GlobePickerTheme.emptyTextStyle].
  final TextStyle emptyTextStyle;

  /// See [GlobePickerTheme.flagWidth].
  final double flagWidth;

  /// See [GlobePickerTheme.flagHeight].
  final double flagHeight;

  /// See [GlobePickerTheme.flagBorderRadius].
  final double flagBorderRadius;
}
