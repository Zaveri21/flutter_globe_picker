import 'package:flutter/material.dart';

import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_options.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_theme.dart';
import 'package:flutter_globe_picker/src/picker/globe_strings.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';
import 'package:flutter_globe_picker/src/widgets/globe_flag.dart';

/// The default picker row: flag, title, subtitle, trailing text and a
/// selected check mark. Use it in your own layouts built with
/// `GlobePickerBuilder`.
class GlobeListTile<T extends GlobeItem> extends StatelessWidget {
  /// Creates a row for [item].
  const GlobeListTile({
    required this.item,
    required this.fields,
    required this.onTap,
    this.trailingFields = const [],
    this.isSelected = false,
    this.locale,
    this.theme,
    this.strings = GlobeStrings.english,
    this.flagType = GlobeFlagType.auto,
    this.flagShape = GlobeFlagShape.rectangle,
    this.showSelectedIndicator = true,
    this.flag,
    this.selectedIndicator,
    super.key,
  });

  /// The item shown.
  final T item;

  /// Content: first text field is the title, the others the subtitle.
  final List<GlobeField> fields;

  /// Text at the end of the row.
  final List<GlobeField> trailingFields;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Whether the row is selected.
  final bool isSelected;

  /// Locale of the names shown. `null` shows English names.
  final Locale? locale;

  /// Resolved theme. `null` resolves it from the context.
  final GlobePickerThemeData? theme;

  /// Texts used for summaries such as `+3`.
  final GlobeStrings strings;

  /// Emoji or SVG flags.
  final GlobeFlagType flagType;

  /// Flag shape.
  final GlobeFlagShape flagShape;

  /// Shows a check mark when selected.
  final bool showSelectedIndicator;

  /// Replaces the default flag widget.
  final Widget? flag;

  /// Replaces the default check mark.
  final Widget? selectedIndicator;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme ?? GlobePickerTheme.resolve(context);
    final textFields = fields.where((field) => field != GlobeField.flag);
    final texts = [
      for (final field in textFields)
        if (displayText(item, field, locale: locale, strings: strings)
            case final text? when text.isNotEmpty)
          text,
    ];
    final trailingTexts = [
      for (final field in trailingFields)
        if (displayText(item, field, locale: locale, strings: strings)
            case final text? when text.isNotEmpty)
          text,
    ];
    final showFlag = fields.contains(GlobeField.flag) && item.flagCode != null;

    Widget? trailing;
    final indicator = showSelectedIndicator && isSelected
        ? (selectedIndicator ??
              Icon(Icons.check, color: resolvedTheme.selectedIconColor))
        : null;
    if (trailingTexts.isNotEmpty || indicator != null) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingTexts.isNotEmpty)
            Text(
              trailingTexts.join('  '),
              style: resolvedTheme.itemTrailingStyle,
            ),
          if (trailingTexts.isNotEmpty && indicator != null)
            const SizedBox(width: 12),
          ?indicator,
        ],
      );
    }

    return ListTile(
      contentPadding: resolvedTheme.itemPadding,
      selected: isSelected,
      selectedTileColor: resolvedTheme.selectedTileColor,
      onTap: onTap,
      leading: showFlag
          ? (flag ??
                GlobeFlag.fromItem(
                  item,
                  type: flagType,
                  shape: flagShape,
                  width: flagShape == GlobeFlagShape.rectangle
                      ? resolvedTheme.flagWidth
                      : resolvedTheme.flagHeight,
                  height: resolvedTheme.flagHeight,
                  borderRadius: resolvedTheme.flagBorderRadius,
                  excludeFromSemantics: true,
                ))
          : null,
      title: Text(
        texts.isEmpty ? item.localizedName(locale) : texts.first,
        style: resolvedTheme.itemTitleStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: texts.length > 1
          ? Text(
              texts.skip(1).join(' · '),
              style: resolvedTheme.itemSubtitleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
    );
  }

  /// The text a row shows for [field] of [item].
  ///
  /// Country names of items linked to many countries are summarized, for
  /// example `United Kingdom, Guernsey +2`. A currency with an issuing
  /// country shows only that country.
  static String? displayText(
    GlobeItem item,
    GlobeField field, {
    Locale? locale,
    GlobeStrings strings = GlobeStrings.english,
  }) {
    if (field == GlobeField.flag) return null;
    if (field == GlobeField.countryName) {
      if (item is GlobeCurrency && item.primaryCountry != null) {
        return item.primaryCountry!.localizedName(locale);
      }
      // A date format can have 150 countries: name only the first two. A
      // shared dial code names its main country first (+44: United Kingdom).
      final countries = item is GlobeDialCode
          ? [
              item.country,
              ...item.countries.where((country) => country != item.country),
            ]
          : item.countries;
      if (countries.length > 2) {
        final firstNames = countries
            .take(2)
            .map((country) => country.localizedName(locale));
        return '${firstNames.join(', ')}'
            ' ${strings.moreCount(countries.length - 2)}';
      }
    }
    if (field == GlobeField.dialCode) {
      final code = switch (item) {
        GlobeCountry(:final dialCode) => dialCode,
        GlobeDialCode(:final code) => code,
        _ => item.representativeCountry?.dialCode,
      };
      return code == null ? null : formatDialCode(code);
    }
    final values = globeFieldValues(item, field, locale: locale);
    if (values.isEmpty) return null;
    if (values.length <= 2) return values.join(', ');
    return '${values.take(2).join(', ')} ${strings.moreCount(values.length - 2)}';
  }

  /// Adds a space after `+1` in North American codes: `+1876` → `+1 876`.
  static String formatDialCode(String code) =>
      code.startsWith('+1') && code.length > 2
      ? '+1 ${code.substring(2)}'
      : code;
}
