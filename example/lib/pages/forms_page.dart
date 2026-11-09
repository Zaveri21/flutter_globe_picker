import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

/// GlobePhoneField, GlobePickerField and GlobePickerButton inside a Form.
class FormsPage extends StatefulWidget {
  const FormsPage({super.key});

  @override
  State<FormsPage> createState() => _FormsPageState();
}

class _FormsPageState extends State<FormsPage> {
  final _formKey = GlobalKey<FormState>();
  GlobePhoneNumber? _phone;
  GlobePhoneNumber? _savedPhone;
  GlobeCountry? _savedCountry;
  GlobeCurrency? _savedCurrency;
  GlobeDateFormat? _savedDateFormat;
  GlobeCurrency? _toolbarCurrency = GlobeData.currencyByCode('USD');
  GlobeDialCode? _toolbarDialCode = GlobeData.dialCodeByCode('+91');
  GlobeCountry? _toolbarCountry = GlobeData.countryByAlpha2('JP');
  String _formStatus = '';

  void _submit() {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      setState(() => _formStatus = 'Please fix the errors above');
      return;
    }
    form.save();
    setState(
      () => _formStatus =
          'Saved: ${_savedPhone?.e164} · ${_savedCountry?.name} · '
          '${_savedCurrency?.code} · ${_savedDateFormat?.pattern}',
    );
  }

  @override
  Widget build(BuildContext context) {
    const outlined = OutlineInputBorder();
    return Scaffold(
      appBar: AppBar(title: const Text('Form widgets')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'GlobePhoneField',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GlobePhoneField(
              isRequired: true,
              decoration: const InputDecoration(border: outlined),
              textInputAction: TextInputAction.next,
              onChanged: (phone) => setState(() => _phone = phone),
              onSaved: (phone) => _savedPhone = phone,
            ),
            const SizedBox(height: 4),
            Text(
              _phone == null || _phone!.isEmpty
                  ? 'Type a number or paste one like +44 7400 123456'
                  : '${_phone!.country.flagEmoji} ${_phone!.e164} · '
                        '${_phone!.isValid ? 'valid' : 'not valid yet'}',
            ),
            const SizedBox(height: 16),
            GlobePhoneField(
              initialValue: '+1 416 555 1234',
              pickerMode: GlobePickerMode.dialog,
              flagType: GlobeFlagType.svg,
              pickerOptions: const GlobePickerOptions(
                filter: GlobeFilter(countries: ['CA', 'US', 'MX', 'GB']),
              ),
              decoration: const InputDecoration(
                labelText: 'North America and UK only (dialog picker)',
                border: outlined,
              ),
            ),
            const SizedBox(height: 16),
            GlobePhoneField(
              initialCountryCode: 'DE',
              validateNumber: false,
              showExampleHint: false,
              validator: (phone) =>
                  phone != null && phone.nationalNumber.startsWith('0')
                  ? 'Leave out the leading 0'
                  : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Custom validator (no leading 0)',
                border: outlined,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'GlobePickerField',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GlobePickerField(
              type: GlobePickerType.country,
              showClearButton: true,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: outlined,
              ),
              validator: (country) =>
                  country == null ? 'Select a country' : null,
              onSaved: (country) => _savedCountry = country,
            ),
            const SizedBox(height: 16),
            GlobePickerField(
              type: GlobePickerType.currency,
              pickerMode: GlobePickerMode.dialog,
              fields: const [
                GlobeField.flag,
                GlobeField.currencyCode,
                GlobeField.currencyName,
              ],
              decoration: const InputDecoration(
                labelText: 'Currency (dialog)',
                border: outlined,
              ),
              validator: (currency) =>
                  currency == null ? 'Select a currency' : null,
              onSaved: (currency) => _savedCurrency = currency,
            ),
            const SizedBox(height: 16),
            GlobePickerField(
              type: GlobePickerType.dateFormat,
              initialValue: GlobeData.dateFormatByPattern('dd/MM/yyyy'),
              decoration: const InputDecoration(
                labelText: 'Date format (with initial value)',
                border: outlined,
              ),
              selectedItemBuilder: (context, dateFormat) => Text(
                '${dateFormat.pattern}  →  ${dateFormat.format(DateTime.now())}',
              ),
              onSaved: (dateFormat) => _savedDateFormat = dateFormat,
            ),
            const SizedBox(height: 16),
            GlobePickerField(
              type: GlobePickerType.dialCode,
              enabled: false,
              initialValue: GlobeData.dialCodeByCode('+44'),
              decoration: const InputDecoration(
                labelText: 'Disabled field',
                border: outlined,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'GlobePickerButton',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GlobePickerButton(
                  type: GlobePickerType.currency,
                  value: _toolbarCurrency,
                  onChanged: (currency) =>
                      setState(() => _toolbarCurrency = currency),
                ),
                GlobePickerButton(
                  type: GlobePickerType.dialCode,
                  value: _toolbarDialCode,
                  onChanged: (dialCode) =>
                      setState(() => _toolbarDialCode = dialCode),
                ),
                GlobePickerButton(
                  type: GlobePickerType.country,
                  value: _toolbarCountry,
                  showLabel: false,
                  flagType: GlobeFlagType.svg,
                  onChanged: (country) =>
                      setState(() => _toolbarCountry = country),
                ),
                GlobePickerButton(
                  type: GlobePickerType.currency,
                  value: _toolbarCurrency,
                  showFlag: false,
                  labelBuilder: (currency) => currency.format(99.99),
                  onChanged: (currency) =>
                      setState(() => _toolbarCurrency = currency),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Validate and save'),
            ),
            const SizedBox(height: 8),
            Text(_formStatus),
          ],
        ),
      ),
    );
  }
}
