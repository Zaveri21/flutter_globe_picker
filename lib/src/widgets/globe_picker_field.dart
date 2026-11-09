import 'package:flutter/material.dart';

import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_options.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_type.dart';
import 'package:flutter_globe_picker/src/picker/globe_strings.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';
import 'package:flutter_globe_picker/src/widgets/globe_flag.dart';
import 'package:flutter_globe_picker/src/widgets/globe_list_tile.dart';

/// A form field that opens a picker when tapped. Works with [Form],
/// validators and `onSaved`.
///
/// ```dart
/// GlobePickerField(
///   type: GlobePickerType.currency,
///   decoration: const InputDecoration(labelText: 'Currency'),
///   validator: (currency) => currency == null ? 'Select a currency' : null,
///   onChanged: (currency) => print(currency?.code),
/// )
/// ```
class GlobePickerField<T extends GlobeItem> extends FormField<T> {
  /// Creates a picker form field.
  GlobePickerField({
    required GlobePickerType<T> type,
    super.initialValue,
    ValueChanged<T?>? onChanged,
    super.validator,
    super.onSaved,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    InputDecoration decoration = const InputDecoration(),
    GlobePickerOptions pickerOptions = const GlobePickerOptions(),
    List<T>? pickerItems,
    GlobePickerBuilders<T>? pickerBuilders,
    GlobePickerMode pickerMode = GlobePickerMode.bottomSheet,
    List<GlobeField>? fields,
    bool showClearButton = false,
    String clearTooltip = 'Clear',
    Widget Function(BuildContext context, T item)? selectedItemBuilder,
    super.key,
  }) : super(
         builder: (state) {
           final context = state.context;
           final value = state.value;
           final locale = pickerOptions.display.useLocalizedNames
               ? Localizations.maybeLocaleOf(context)
               : null;
           final shownFields =
               fields ?? pickerOptions.display.fields ?? type.defaultFields;

           Future<void> openPicker() async {
             final selection = await GlobePicker.show<T>(
               context,
               type: type,
               mode: pickerMode,
               selected: value?.id,
               options: pickerOptions,
               items: pickerItems,
               builders: pickerBuilders,
             );
             // The field may be gone by the time the picker closes.
             if (!state.mounted) return;
             if (selection != null && selection != state.value) {
               state.didChange(selection);
               onChanged?.call(selection);
             }
           }

           void clear() {
             state.didChange(null);
             onChanged?.call(null);
           }

           final effectiveDecoration = decoration
               .applyDefaults(Theme.of(context).inputDecorationTheme)
               .copyWith(
                 errorText: state.errorText,
                 enabled: state.widget.enabled,
                 suffixIcon:
                     decoration.suffixIcon ??
                     (showClearButton && value != null && state.widget.enabled
                         ? IconButton(
                             tooltip: clearTooltip,
                             icon: const Icon(Icons.clear),
                             onPressed: clear,
                           )
                         : const Icon(Icons.arrow_drop_down)),
               );

           return InkWell(
             onTap: state.widget.enabled ? openPicker : null,
             child: InputDecorator(
               decoration: effectiveDecoration,
               isEmpty: value == null,
               child: value == null
                   ? null
                   : selectedItemBuilder?.call(context, value) ??
                         _SelectedItemLabel<T>(
                           item: value,
                           fields: shownFields,
                           locale: locale,
                           flagType: pickerOptions.display.flagType,
                           strings:
                               pickerOptions.strings ?? GlobeStrings.english,
                         ),
             ),
           );
         },
       );
}

class _SelectedItemLabel<T extends GlobeItem> extends StatelessWidget {
  const _SelectedItemLabel({
    required this.item,
    required this.fields,
    required this.locale,
    required this.flagType,
    required this.strings,
  });

  final T item;
  final List<GlobeField> fields;
  final Locale? locale;
  final GlobeFlagType flagType;
  final GlobeStrings strings;

  @override
  Widget build(BuildContext context) {
    final texts = [
      for (final field in fields)
        if (GlobeListTile.displayText(
              item,
              field,
              locale: locale,
              strings: strings,
            )
            case final text? when text.isNotEmpty)
          text,
    ];
    final showFlag = fields.contains(GlobeField.flag) && item.flagCode != null;
    return Row(
      children: [
        if (showFlag) ...[
          GlobeFlag.fromItem(
            item,
            type: flagType,
            width: 24,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            texts.isEmpty ? item.localizedName(locale) : texts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
