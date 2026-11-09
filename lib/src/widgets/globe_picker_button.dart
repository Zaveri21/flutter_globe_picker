import 'package:flutter/material.dart';

import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_options.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_type.dart';
import 'package:flutter_globe_picker/src/widgets/globe_flag.dart';
import 'package:flutter_globe_picker/src/widgets/globe_list_tile.dart';

/// A compact button showing the selected item (flag and code) that opens a
/// picker. Good for app bars, toolbars and phone number prefixes.
///
/// ```dart
/// GlobePickerButton(
///   type: GlobePickerType.currency,
///   value: currency,
///   onChanged: (value) => setState(() => currency = value),
/// )
/// ```
class GlobePickerButton<T extends GlobeItem> extends StatelessWidget {
  /// Creates a picker button.
  const GlobePickerButton({
    required this.type,
    required this.value,
    required this.onChanged,
    this.pickerOptions = const GlobePickerOptions(),
    this.pickerItems,
    this.pickerBuilders,
    this.pickerMode = GlobePickerMode.bottomSheet,
    this.showFlag = true,
    this.showLabel = true,
    this.showArrow = true,
    this.flagType = GlobeFlagType.auto,
    this.labelBuilder,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.enabled = true,
    this.semanticLabel,
    super.key,
  });

  /// What the picker lists.
  final GlobePickerType<T> type;

  /// The selected item, or `null`.
  final T? value;

  /// Called with the newly selected item.
  final ValueChanged<T> onChanged;

  /// Options of the opened picker.
  final GlobePickerOptions pickerOptions;

  /// Items listed by the opened picker. `null` lists every item.
  final List<T>? pickerItems;

  /// Custom builders of the opened picker.
  final GlobePickerBuilders<T>? pickerBuilders;

  /// How the picker opens.
  final GlobePickerMode pickerMode;

  /// Shows the flag.
  final bool showFlag;

  /// Shows the label (code by default).
  final bool showLabel;

  /// Shows a drop-down arrow.
  final bool showArrow;

  /// Emoji or SVG flag.
  final GlobeFlagType flagType;

  /// Builds the label text. Defaults to the alpha-2 code, currency code,
  /// dial code or date pattern.
  final String Function(T item)? labelBuilder;

  /// Style of the label.
  final TextStyle? textStyle;

  /// Padding inside the button.
  final EdgeInsetsGeometry padding;

  /// Whether the button can be tapped.
  final bool enabled;

  /// Accessibility label of the button.
  final String? semanticLabel;

  Future<void> _openPicker(BuildContext context) async {
    final selection = await GlobePicker.show<T>(
      context,
      type: type,
      mode: pickerMode,
      selected: value?.id,
      options: pickerOptions,
      items: pickerItems,
      builders: pickerBuilders,
    );
    // The button may be gone by the time the picker closes.
    if (selection != null && context.mounted) onChanged(selection);
  }

  @override
  Widget build(BuildContext context) {
    final item = value;
    final label = item == null
        ? null
        : labelBuilder?.call(item) ?? _defaultLabel(item);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? () => _openPicker(context) : null,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFlag && item != null && item.flagCode != null) ...[
                GlobeFlag.fromItem(
                  item,
                  type: flagType,
                  width: 24,
                  // The button's own label already names the item.
                  excludeFromSemantics: semanticLabel != null,
                ),
                if (showLabel && label != null) const SizedBox(width: 8),
              ],
              if (showLabel && label != null) Text(label, style: textStyle),
              if (showArrow)
                Icon(
                  Icons.arrow_drop_down,
                  color: enabled ? null : Theme.of(context).disabledColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _defaultLabel(GlobeItem item) => switch (item) {
    GlobeCountry(:final alpha2Code) => alpha2Code,
    GlobeCurrency(:final code) => code,
    GlobeDialCode(:final code) => GlobeListTile.formatDialCode(code),
    GlobeDateFormat(:final pattern) => pattern,
  };
}
