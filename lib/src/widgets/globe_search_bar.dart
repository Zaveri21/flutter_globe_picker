import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The search field used by the pickers. Use it in your own picker layouts
/// built with `GlobePickerBuilder`.
class GlobeSearchBar extends StatelessWidget {
  /// Creates a Material search field.
  const GlobeSearchBar({
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search',
    this.clearTooltip = 'Clear search',
    this.autofocus = false,
    this.decoration,
    this.style,
    this.useCupertinoStyle = false,
    super.key,
  });

  /// Holds the search text.
  final TextEditingController controller;

  /// Called with the new text on every change.
  final ValueChanged<String> onChanged;

  /// Hint shown when empty.
  final String hintText;

  /// Tooltip of the clear button.
  final String clearTooltip;

  /// Opens the keyboard immediately.
  final bool autofocus;

  /// Extra decoration merged over the default Material decoration.
  final InputDecoration? decoration;

  /// Text style.
  final TextStyle? style;

  /// Uses [CupertinoSearchTextField] instead of a Material field.
  final bool useCupertinoStyle;

  @override
  Widget build(BuildContext context) {
    if (useCupertinoStyle) {
      return CupertinoSearchTextField(
        controller: controller,
        onChanged: onChanged,
        placeholder: hintText,
        autofocus: autofocus,
        style: style,
        // The default CupertinoIcons need the cupertino_icons font, which
        // apps may not bundle. Material icons render everywhere.
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.cancel),
        onSuffixTap: () {
          controller.clear();
          onChanged('');
        },
      );
    }

    final colors = Theme.of(context).colorScheme;
    final defaultDecoration = InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      suffixIcon: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => value.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: clearTooltip,
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      style: style,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      decoration: _merge(defaultDecoration, decoration),
    );
  }

  static InputDecoration _merge(InputDecoration base, InputDecoration? custom) {
    if (custom == null) return base;
    return base.copyWith(
      hintText: custom.hintText,
      hintStyle: custom.hintStyle,
      labelText: custom.labelText,
      prefixIcon: custom.prefixIcon,
      suffixIcon: custom.suffixIcon,
      filled: custom.filled,
      fillColor: custom.fillColor,
      isDense: custom.isDense,
      contentPadding: custom.contentPadding,
      border: custom.border,
      enabledBorder: custom.enabledBorder,
      focusedBorder: custom.focusedBorder,
    );
  }
}
