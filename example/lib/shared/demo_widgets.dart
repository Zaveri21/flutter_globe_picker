import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

/// Describes any picker result in one line.
String describeResult(Object? result) => switch (result) {
  null => 'Closed without a selection',
  final GlobeCountry country =>
    '${country.flagEmoji} ${country.name} · ${country.alpha2Code} · '
        '${country.dialCode} · ${country.currency?.code ?? 'no currency'} · '
        '${country.dateFormat.pattern}',
  final GlobeCurrency currency =>
    '${currency.code} ${currency.symbol} · ${currency.name} · '
        'used by ${currency.countries.length} countries · '
        '${currency.format(1234.5)}',
  final GlobeDialCode dialCode =>
    '${dialCode.code} · '
        '${dialCode.countries.map((country) => country.name).join(', ')}',
  final GlobeDateFormat dateFormat =>
    '${dateFormat.pattern} · ${dateFormat.format(DateTime.now())} · '
        '${dateFormat.countries.length} countries',
  final List<GlobeItem> items =>
    items.isEmpty
        ? 'Nothing selected'
        : '${items.length} selected: ${items.map((item) => item.id).join(', ')}',
  _ => result.toString(),
};

/// A page made of titled sections, with the last result pinned at the top.
class DemoPage extends StatelessWidget {
  const DemoPage({
    required this.title,
    required this.children,
    this.result,
    super.key,
  });

  final String title;
  final String? result;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          if (result != null)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(result!, style: textTheme.bodyLarge)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section heading with an optional explanation.
class DemoSection extends StatelessWidget {
  const DemoSection(this.title, {this.description, super.key});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description!, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// A button that runs a demo.
class DemoButton extends StatelessWidget {
  const DemoButton({
    required this.label,
    required this.onPressed,
    this.code,
    super.key,
  });

  final String label;

  /// A short snippet of the code behind the demo, shown under the label.
  final String? code;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            if (code != null)
              Text(
                code!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mixin for demo pages that show the last picker result.
mixin ResultState<T extends StatefulWidget> on State<T> {
  String? lastResult;

  /// Awaits [pickerFuture] and shows its result.
  Future<void> showResult(Future<Object?> pickerFuture) async {
    final result = await pickerFuture;
    if (mounted) setState(() => lastResult = describeResult(result));
  }
}
