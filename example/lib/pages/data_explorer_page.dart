import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

/// GlobeData without any picker: linked models, lookups, phone parsing and
/// formatting, with live inputs.
class DataExplorerPage extends StatefulWidget {
  const DataExplorerPage({super.key});

  @override
  State<DataExplorerPage> createState() => _DataExplorerPageState();
}

class _DataExplorerPageState extends State<DataExplorerPage> {
  GlobeCountry _country = GlobeData.countryByAlpha2('IN')!;
  String _phoneInput = '+44 7400 123456';
  String _datePattern = 'EEE, d MMM yyyy HH:mm';
  double _amount = 1234567.89;
  String _searchQuery = 'ivory';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = _country.currency;
    final phone = GlobeData.parsePhone(_phoneInput, defaultCountry: _country);
    final now = DateTime.now();
    String formattedDate;
    try {
      formattedDate = GlobeData.formatDate(now, pattern: _datePattern);
    } on Object catch (error) {
      formattedDate = 'Invalid pattern: $error';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Data explorer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Linked country model', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          GlobePickerButton(
            type: GlobePickerType.country,
            value: _country,
            labelBuilder: (country) => country.name,
            onChanged: (country) => setState(() => _country = country),
          ),
          _Fact(
            'Codes',
            '${_country.alpha2Code} · ${_country.alpha3Code} · ${_country.numCode ?? 'none'}',
          ),
          _Fact('Flag emoji', _country.flagEmoji),
          _Fact('Capital', _country.capital ?? 'none'),
          _Fact('Region', '${_country.region.label} · ${_country.subregion}'),
          _Fact(
            'Dial codes',
            '${_country.dialCodes.join(', ')} (calling code ${_country.callingCode})',
          ),
          _Fact(
            'Shares its dial code with',
            _country.dialCodeInfo.countries
                .where((other) => other != _country)
                .map((other) => other.name)
                .join(', '),
          ),
          _Fact(
            'Currencies',
            _country.currencies
                .map(
                  (linked) =>
                      '${linked.code} ${linked.symbol} (${linked.name})',
                )
                .join(', '),
          ),
          if (currency != null)
            _Fact(
              '${currency.code} is also used in',
              '${currency.countries.length} countries',
            ),
          _Fact(
            'Date format',
            '${_country.dateFormat.pattern} → ${_country.dateFormat.format(now)} '
                '(${_country.dateFormat.countries.length} countries)',
          ),
          _Fact('Languages', _country.languages.join(', ')),
          _Fact('Time zones', _country.timezones.join(', ')),
          _Fact('Domain', _country.tld ?? 'none'),
          _Fact(
            'Phone',
            'lengths ${_country.phoneLengths.join('/')} · example '
                '${_country.phoneExample ?? 'none'} · trunk prefix '
                '${_country.nationalPrefix ?? 'none'}',
          ),
          _Fact(
            'Memberships',
            [
              if (_country.isUNMember) 'UN',
              if (_country.isEUMember) 'EU',
              if (_country.isEurozone) 'Eurozone',
            ].join(', '),
          ),
          const Divider(height: 32),
          Text('Money formatting', style: textTheme.titleMedium),
          Slider(
            min: 0,
            max: 10000000,
            value: _amount,
            onChanged: (value) => setState(() => _amount = value),
          ),
          if (currency != null) ...[
            _Fact('In ${_country.name}', currency.format(_amount)),
            _Fact(
              'Native symbol',
              currency.format(_amount, useNativeSymbol: true),
            ),
          ],
          _Fact(
            'EUR in Germany / France / Ireland',
            [
              GlobeData.formatCurrency(
                _amount,
                currencyCode: 'EUR',
                countryCode: 'DE',
              ),
              GlobeData.formatCurrency(
                _amount,
                currencyCode: 'EUR',
                countryCode: 'FR',
              ),
              GlobeData.formatCurrency(
                _amount,
                currencyCode: 'EUR',
                countryCode: 'IE',
              ),
            ].join('   '),
          ),
          _Fact(
            'Number in ${_country.name}',
            _country.numberFormat.formatNumber(_amount, decimalDigits: 2),
          ),
          const Divider(height: 32),
          Text('Phone parser', style: textTheme.titleMedium),
          TextFormField(
            initialValue: _phoneInput,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              helperText:
                  'International (+ or 00) or national for ${_country.name}',
            ),
            onChanged: (value) => setState(() => _phoneInput = value),
          ),
          _Fact(
            'Result',
            phone == null
                ? 'No country found'
                : '${phone.country.flagEmoji} ${phone.country.name} · '
                      '${phone.e164} · ${phone.isValid ? 'valid' : 'invalid'}',
          ),
          const Divider(height: 32),
          Text('Date formatting', style: textTheme.titleMedium),
          TextFormField(
            initialValue: _datePattern,
            decoration: const InputDecoration(
              helperText: 'y M d E H h m s a and quoted text',
            ),
            onChanged: (value) => setState(() => _datePattern = value),
          ),
          _Fact('Result', formattedDate),
          _Fact(
            'Today in US / DE / JP',
            [
              GlobeData.formatDate(now, countryCode: 'US'),
              GlobeData.formatDate(now, countryCode: 'DE'),
              GlobeData.formatDate(now, countryCode: 'JP'),
            ].join('   '),
          ),
          _Fact(
            '12-hour clock in the US',
            GlobeData.formatDateTime(now, countryCode: 'US', use24Hour: false),
          ),
          const Divider(height: 32),
          Text('Search', style: textTheme.titleMedium),
          TextFormField(
            initialValue: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          _Fact(
            'Countries',
            GlobeData.searchCountries(_searchQuery)
                .take(5)
                .map((country) => country.name)
                .join(', '),
          ),
          _Fact(
            'Currencies',
            GlobeData.searchCurrencies(_searchQuery)
                .take(5)
                .map((match) => match.code)
                .join(', '),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      subtitle: SelectableText(value.isEmpty ? '—' : value),
    );
  }
}
