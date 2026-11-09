import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

/// GlobePickerView embedded in a screen and driven by a controller.
class InlinePage extends StatefulWidget {
  const InlinePage({super.key});

  @override
  State<InlinePage> createState() => _InlinePageState();
}

class _InlinePageState extends State<InlinePage> {
  final _controller = GlobePickerController<GlobeCountry>();
  bool _multiSelect = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChange)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChange() => setState(() {});

  void _selectCountry(String alpha2Code) {
    final country = GlobeData.countryByAlpha2(alpha2Code)!;
    if (_multiSelect) {
      _controller.toggle(country);
    } else {
      _controller.select(country);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = _controller.selection;
    return Scaffold(
      appBar: AppBar(title: const Text('Inline view and controller')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Multi-select'),
                  selected: _multiSelect,
                  onSelected: (value) {
                    _controller.clearSelection();
                    setState(() => _multiSelect = value);
                  },
                ),
                ActionChip(
                  label: const Text("search('united')"),
                  onPressed: () => _controller.search('united'),
                ),
                ActionChip(
                  label: const Text('clearQuery()'),
                  onPressed: _controller.clearQuery,
                ),
                ActionChip(
                  label: const Text('select India'),
                  onPressed: () => _selectCountry('IN'),
                ),
                ActionChip(
                  label: const Text('select Japan'),
                  onPressed: () => _selectCountry('JP'),
                ),
                ActionChip(
                  label: const Text('clearSelection()'),
                  onPressed: _controller.clearSelection,
                ),
              ],
            ),
          ),
          ListTile(
            dense: true,
            title: Text('query: "${_controller.query}"'),
            subtitle: Text(
              selection.isEmpty
                  ? 'Nothing selected'
                  : 'selection: ${selection.map((country) => country.name).join(', ')}',
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GlobePickerView<GlobeCountry>(
              key: ValueKey(_multiSelect),
              type: GlobePickerType.country,
              controller: _controller,
              multiSelect: _multiSelect,
              options: const GlobePickerOptions(
                title: 'Countries',
                favorites: ['IN', 'US'],
                display: GlobeDisplay(trailingFields: [GlobeField.dialCode]),
              ),
              onSelected: (country) => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Tapped ${country.name}')),
                ),
              onConfirm: (countries) => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Confirmed ${countries.length}')),
                ),
            ),
          ),
        ],
      ),
    );
  }
}
