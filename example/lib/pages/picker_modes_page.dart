import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

import '../shared/demo_widgets.dart';

/// Every picker type in every mode, multi-select and the generic API.
class PickerModesPage extends StatefulWidget {
  const PickerModesPage({super.key});

  @override
  State<PickerModesPage> createState() => _PickerModesPageState();
}

class _PickerModesPageState extends State<PickerModesPage>
    with ResultState<PickerModesPage> {
  GlobePickerMode _mode = GlobePickerMode.bottomSheet;

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Picker modes',
      result: lastResult,
      children: [
        const DemoSection(
          'How the picker opens',
          description: 'Choose a mode, then open any picker below.',
        ),
        SegmentedButton<GlobePickerMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: GlobePickerMode.bottomSheet,
              label: Text('Sheet'),
            ),
            ButtonSegment(value: GlobePickerMode.dialog, label: Text('Dialog')),
            ButtonSegment(value: GlobePickerMode.fullPage, label: Text('Page')),
            ButtonSegment(
              value: GlobePickerMode.cupertinoSheet,
              label: Text('iOS'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (modes) => setState(() => _mode = modes.first),
        ),
        const DemoSection('Single selection'),
        DemoButton(
          label: 'Country',
          code: 'GlobePicker.country(context, mode: ...)',
          onPressed: () =>
              showResult(GlobePicker.country(context, mode: _mode)),
        ),
        DemoButton(
          label: 'Currency',
          code: 'GlobePicker.currency(context, mode: ...)',
          onPressed: () =>
              showResult(GlobePicker.currency(context, mode: _mode)),
        ),
        DemoButton(
          label: 'Dial code',
          code: 'GlobePicker.dialCode(context, mode: ...)',
          onPressed: () =>
              showResult(GlobePicker.dialCode(context, mode: _mode)),
        ),
        DemoButton(
          label: 'Date format',
          code: 'GlobePicker.dateFormat(context, mode: ...)',
          onPressed: () =>
              showResult(GlobePicker.dateFormat(context, mode: _mode)),
        ),
        const DemoSection(
          'Multi-select',
          description: 'Returns a list after Done, or null when closed.',
        ),
        DemoButton(
          label: 'Countries (India preselected)',
          code: "GlobePicker.countries(context, selected: ['IN'])",
          onPressed: () => showResult(
            GlobePicker.countries(context, mode: _mode, selected: const ['IN']),
          ),
        ),
        DemoButton(
          label: 'Currencies',
          code: 'GlobePicker.currencies(context)',
          onPressed: () =>
              showResult(GlobePicker.currencies(context, mode: _mode)),
        ),
        DemoButton(
          label: 'Dial codes (generic)',
          code: 'GlobePicker.showMultiple(context, type: GlobePickerType.dialCode)',
          onPressed: () => showResult(
            GlobePicker.showMultiple(
              context,
              type: GlobePickerType.dialCode,
              mode: _mode,
            ),
          ),
        ),
        const DemoSection(
          'Generic API',
          description:
              'GlobePicker.show works with any type. The result type follows '
              'the picker type.',
        ),
        DemoButton(
          label: 'Currency with preselected EUR and a custom title',
          code:
              'GlobePicker.show(context, type: GlobePickerType.currency, '
              "selected: 'EUR', title: 'Payout currency')",
          onPressed: () => showResult(
            GlobePicker.show(
              context,
              type: GlobePickerType.currency,
              mode: _mode,
              selected: 'EUR',
              title: 'Payout currency',
            ),
          ),
        ),
        DemoButton(
          label: 'Not dismissible (must pick or close)',
          code: 'GlobePicker.show(..., isDismissible: false)',
          onPressed: () => showResult(
            GlobePicker.show(
              context,
              type: GlobePickerType.country,
              mode: _mode,
              isDismissible: false,
            ),
          ),
        ),
      ],
    );
  }
}
