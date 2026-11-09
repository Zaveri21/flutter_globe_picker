import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_globe_picker/src/globe_data.dart';
import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/models/globe_phone_number.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_options.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_type.dart';
import 'package:flutter_globe_picker/src/picker/globe_strings.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';
import 'package:flutter_globe_picker/src/widgets/globe_data_loader.dart';
import 'package:flutter_globe_picker/src/widgets/globe_picker_button.dart';

/// A phone number field with a country button, validation and E.164
/// output.
///
/// The country starts from [initialValue] (when it is international), then
/// [initialCountryCode], then the device locale, then the United States.
/// Pasting a number that starts with `+` or `00` switches the country
/// automatically.
///
/// ```dart
/// GlobePhoneField(
///   initialCountryCode: 'IN',
///   onChanged: (phone) => print(phone.e164), // +919876543210
/// )
/// ```
class GlobePhoneField extends StatefulWidget {
  /// Creates a phone number field.
  const GlobePhoneField({
    this.initialCountryCode,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCountryChanged,
    this.onSaved,
    this.onSubmitted,
    this.validator,
    this.validateNumber = true,
    this.isRequired = false,
    this.autovalidateMode,
    this.decoration = const InputDecoration(),
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.showExampleHint = true,
    this.showFlag = true,
    this.flagType = GlobeFlagType.auto,
    this.pickerOptions = const GlobePickerOptions(),
    this.pickerBuilders,
    this.pickerMode = GlobePickerMode.bottomSheet,
    this.strings = GlobeStrings.english,
    super.key,
  });

  /// Alpha-2 code of the starting country, for example `IN`.
  final String? initialCountryCode;

  /// Starting number, international (`+91 98765 43210`) or national.
  /// Ignored when [controller] already has text.
  final String? initialValue;

  /// Controls the national number text.
  final TextEditingController? controller;

  /// Focus node of the text field.
  final FocusNode? focusNode;

  /// Called with the current number on every change.
  final ValueChanged<GlobePhoneNumber>? onChanged;

  /// Called when the country changes.
  final ValueChanged<GlobeCountry>? onCountryChanged;

  /// Called with the current number when the enclosing [Form] is saved.
  final FormFieldSetter<GlobePhoneNumber>? onSaved;

  /// Called when the user submits the field from the keyboard.
  final ValueChanged<GlobePhoneNumber>? onSubmitted;

  /// Extra validation, run after the built-in checks.
  final FormFieldValidator<GlobePhoneNumber>? validator;

  /// Checks the number against the country's numbering plan.
  final bool validateNumber;

  /// Shows an error when the field is empty.
  final bool isRequired;

  /// When to validate.
  final AutovalidateMode? autovalidateMode;

  /// Decoration of the text field. The country button is added as prefix.
  final InputDecoration decoration;

  /// Whether the field can be edited.
  final bool enabled;

  /// Opens the keyboard immediately.
  final bool autofocus;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Shows the country's example number as hint.
  final bool showExampleHint;

  /// Shows the flag in the country button.
  final bool showFlag;

  /// Emoji or SVG flag.
  final GlobeFlagType flagType;

  /// Options of the country picker. Dial codes are shown at the end of each
  /// row unless `display.trailingFields` is set.
  final GlobePickerOptions pickerOptions;

  /// Custom builders of the country picker.
  final GlobePickerBuilders<GlobeCountry>? pickerBuilders;

  /// How the country picker opens.
  final GlobePickerMode pickerMode;

  /// Texts of the field.
  final GlobeStrings strings;

  @override
  State<GlobePhoneField> createState() => _GlobePhoneFieldState();
}

class _GlobePhoneFieldState extends State<GlobePhoneField> {
  static final _internationalPrefix = RegExp(r'^\s*(\+|00)');
  static final _nonDigit = RegExp(r'\D');
  static final _phoneCharacters = RegExp(r'[0-9+\-\s().]');

  /// A `+` is only allowed as the first character.
  static final _plusOnlyAtStart = RegExp(r'^\s*\+?[^+]*$');
  static const _fallbackCountryCode = 'US';

  TextEditingController? _ownedController;
  GlobeCountry? _country;

  /// The starting country and text, restored by `Form.reset`.
  GlobeCountry? _initialCountry;
  String _initialText = '';

  /// The text last handled, to ignore selection-only controller changes.
  String _lastText = '';

  /// Whether this state is writing the text itself.
  bool _writingText = false;

  TextEditingController get _textController =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  GlobeCountry get _currentCountry => _country!;

  GlobePhoneNumber get _currentNumber {
    final text = _textController.text;
    // While an international number is still being typed, the text keeps
    // its `+` and calling code; read the number from it.
    if (_internationalPrefix.hasMatch(text)) {
      final parsed = GlobeData.parsePhone(text);
      if (parsed != null) return parsed;
    }
    return GlobePhoneNumber(country: _currentCountry, nationalNumber: text);
  }

  @override
  void initState() {
    super.initState();
    _lastText = _textController.text;
    _textController.addListener(_handleControllerChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_country == null &&
        GlobeData.isLoadedFrom(widget.pickerOptions.dataSource)) {
      _initializeCountryAndText();
    }
  }

  @override
  void didUpdateWidget(GlobePhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    (oldWidget.controller ?? _ownedController)?.removeListener(
      _handleControllerChange,
    );
    if (widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
    }
    _lastText = _textController.text;
    _textController.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleControllerChange);
    _ownedController?.dispose();
    super.dispose();
  }

  /// Picks the starting country and text. Needs the data.
  void _initializeCountryAndText() {
    final initialValue = widget.initialValue?.trim() ?? '';
    final startingCountry =
        (widget.initialCountryCode == null
            ? null
            : GlobeData.countryByAlpha2(widget.initialCountryCode!)) ??
        (Localizations.maybeLocaleOf(context) == null
            ? null
            : GlobeData.countryFromLocale(Localizations.localeOf(context))) ??
        GlobeData.countryByAlpha2(_fallbackCountryCode)!;
    _country = startingCountry;

    var text = _textController.text;
    if (text.isEmpty && initialValue.isNotEmpty) {
      final parsed = GlobeData.parsePhone(
        initialValue,
        defaultCountry: startingCountry,
      );
      if (parsed != null) _country = parsed.country;
      text = parsed?.nationalNumber ?? initialValue;
      // An outside controller may have listeners that must not be notified
      // while widgets build, so it gets the text after this frame.
      if (widget.controller == null) {
        _writeText(text);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _textController.text.isEmpty) _writeText(text);
        });
      }
    }
    _initialCountry = _country;
    _initialText = text;
  }

  void _writeText(String text) {
    _writingText = true;
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _lastText = text;
    _writingText = false;
  }

  /// Handles typing, pasting, autofill and text set from outside alike.
  void _handleControllerChange() {
    if (_writingText) return;
    final text = _textController.text;
    if (text == _lastText) return;
    _lastText = text;
    if (_country == null || !GlobeData.isLoaded) return;
    _handleTextChanged(text);
  }

  void _handleTextChanged(String text) {
    if (_internationalPrefix.hasMatch(text)) {
      final parsed = GlobeData.parsePhone(text);
      if (parsed != null) {
        _setCountry(parsed.country);
        // Countries sharing a calling code are told apart by the digits
        // after it, so `+12` must not settle on the United States before
        // `+1242` (Bahamas) is typed. Keep the international text until the
        // country is certain.
        if (_isCountryCertain(parsed)) _writeText(parsed.nationalNumber);
      }
    }
    widget.onChanged?.call(_currentNumber);
  }

  /// The user picked [country] with the button: it wins over a calling
  /// code still being typed.
  void _handleCountryPicked(GlobeCountry country) {
    if (!mounted) return;
    final text = _textController.text;
    if (_internationalPrefix.hasMatch(text)) {
      _writeText(
        GlobeData.parsePhone(text)?.nationalNumber ??
            text.replaceAll(_nonDigit, ''),
      );
    }
    _setCountry(country);
    widget.onChanged?.call(_currentNumber);
  }

  /// `Form.reset` cleared the text; bring back the starting number.
  void _handleFormReset() {
    // Runs after the text field's own reset.
    scheduleMicrotask(() {
      if (!mounted) return;
      _writeText(_initialText);
      final country = _initialCountry;
      if (country != null) _setCountry(country);
    });
  }

  static bool _isCountryCertain(GlobePhoneNumber number) {
    final country = number.country;
    final sharesCallingCode = GlobeData.countries.any(
      (other) => other != country && other.callingCode == country.callingCode,
    );
    if (!sharesCallingCode || number.isValid) return true;
    final lengths = country.phoneLengths;
    final digits = number.nationalNumber.replaceAll(_nonDigit, '');
    return lengths.isNotEmpty && digits.length >= lengths.last;
  }

  void _setCountry(GlobeCountry country) {
    if (!mounted || country == _country) return;
    setState(() => _country = country);
    widget.onCountryChanged?.call(country);
  }

  String? _validate(String? _) {
    final number = _currentNumber;
    if (number.isEmpty) {
      if (widget.isRequired) return widget.strings.requiredField;
      return widget.validator?.call(number);
    }
    if (widget.validateNumber && !number.isValid) {
      return widget.strings.invalidPhoneNumber;
    }
    return widget.validator?.call(number);
  }

  @override
  Widget build(BuildContext context) => GlobeDataLoader(
    source: widget.pickerOptions.dataSource,
    builder: _buildLoaded,
  );

  Widget _buildLoaded(BuildContext context) {
    // The data was still loading in didChangeDependencies.
    if (_country == null) _initializeCountryAndText();
    final country = _currentCountry;
    final display = widget.pickerOptions.display;
    final pickerOptions = display.trailingFields == null
        ? widget.pickerOptions.copyWith(
            display: display.copyWith(trailingFields: [GlobeField.dialCode]),
          )
        : widget.pickerOptions;
    final locale = display.useLocalizedNames
        ? Localizations.maybeLocaleOf(context)
        : null;

    final countryButton = Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
      child: GlobePickerButton<GlobeCountry>(
        type: GlobePickerType.country,
        value: country,
        enabled: widget.enabled,
        showFlag: widget.showFlag,
        flagType: widget.flagType,
        pickerOptions: pickerOptions,
        pickerBuilders: widget.pickerBuilders,
        pickerMode: widget.pickerMode,
        semanticLabel:
            '${widget.strings.selectCountry}, ${country.localizedName(locale)}',
        labelBuilder: (selected) => selected.callingCode,
        onChanged: _handleCountryPicked,
      ),
    );

    // An invisible form field that tells this field when its `Form` is
    // reset, so the country comes back as well as the text.
    final textField = TextFormField(
      controller: _textController,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      autovalidateMode: widget.autovalidateMode,
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [
        FilteringTextInputFormatter.allow(_phoneCharacters),
        TextInputFormatter.withFunction(
          (oldValue, newValue) =>
              _plusOnlyAtStart.hasMatch(newValue.text) ? newValue : oldValue,
        ),
      ],
      decoration: widget.decoration.copyWith(
        labelText:
            widget.decoration.labelText ?? widget.strings.phoneNumberLabel,
        hintText:
            widget.decoration.hintText ??
            (widget.showExampleHint ? country.phoneExample : null),
        prefixIcon: countryButton,
        prefixIconConstraints: const BoxConstraints(minHeight: 48),
      ),
      validator: _validate,
      onSaved: (_) => widget.onSaved?.call(_currentNumber),
      onFieldSubmitted: (_) => widget.onSubmitted?.call(_currentNumber),
    );
    return FormField<Object?>(
      onReset: _handleFormReset,
      builder: (_) => textField,
    );
  }
}
