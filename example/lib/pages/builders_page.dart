import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

import '../shared/demo_widgets.dart';

/// Every builder of GlobePickerBuilders, one at a time and all together.
class BuildersPage extends StatefulWidget {
  const BuildersPage({super.key});

  @override
  State<BuildersPage> createState() => _BuildersPageState();
}

class _BuildersPageState extends State<BuildersPage>
    with ResultState<BuildersPage> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DemoPage(
      title: 'Custom builders',
      result: lastResult,
      children: [
        const DemoSection(
          'One part at a time',
          description: 'Parts without a builder keep the default look.',
        ),
        DemoButton(
          label: 'itemBuilder: card rows with formatted money',
          code: 'builders: GlobePickerBuilders(itemBuilder: ...)',
          onPressed: () => showResult(
            GlobePicker.currency(
              context,
              builders: GlobePickerBuilders(
                itemBuilder: (context, currency, isSelected, onTap) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  color: isSelected ? colors.primaryContainer : null,
                  child: ListTile(
                    onTap: onTap,
                    leading: GlobeFlag.fromItem(
                      currency,
                      shape: GlobeFlagShape.circle,
                      width: 40,
                    ),
                    title: Text('${currency.name} (${currency.symbol})'),
                    subtitle: Text(
                      '${currency.format(1234.5)} · '
                      '${currency.countries.length} countries',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'headerBuilder: title with a live count',
          code: 'headerBuilder: (context, snapshot) => ...',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              builders: GlobePickerBuilders(
                headerBuilder: (context, snapshot) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${snapshot.items.length} countries',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: snapshot.close,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'searchBarBuilder: your own text field',
          code: 'searchBarBuilder: (context, textController, onChanged) => ...',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              builders: GlobePickerBuilders(
                searchBarBuilder: (context, textController, onChanged) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: textController,
                        onChanged: onChanged,
                        decoration: const InputDecoration(
                          labelText: 'Where are you from?',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'sectionHeaderBuilder and separatorBuilder',
          code: 'sectionHeaderBuilder: ..., separatorBuilder: ...',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              groupBy: GlobeGroupBy.alphabet,
              display: const GlobeDisplay(showDividers: true),
              builders: GlobePickerBuilders(
                sectionHeaderBuilder: (context, title) => Container(
                  color: colors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                separatorBuilder: (context) =>
                    const Divider(height: 1, indent: 72),
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'emptyBuilder: type something that does not exist',
          code: 'emptyBuilder: (context, query) => ...',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              builders: GlobePickerBuilders(
                emptyBuilder: (context, query) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public_off, size: 64),
                      const SizedBox(height: 12),
                      Text('No country called "$query"'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'flagBuilder and selectedIndicatorBuilder',
          code: 'flagBuilder: ..., selectedIndicatorBuilder: ...',
          onPressed: () => showResult(
            GlobePicker.country(
              context,
              selected: 'JP',
              builders: GlobePickerBuilders(
                flagBuilder: (context, country) =>
                    CircleAvatar(child: Text(country.alpha2Code)),
                selectedIndicatorBuilder: (context, isSelected) =>
                    Icon(Icons.favorite, color: colors.error),
              ),
            ),
          ),
        ),
        DemoButton(
          label: 'footerBuilder and containerBuilder (multi-select)',
          code: 'footerBuilder: ..., containerBuilder: ...',
          onPressed: () => showResult(
            GlobePicker.countries(
              context,
              builders: GlobePickerBuilders(
                footerBuilder: (context, snapshot) => SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${snapshot.selection.length} selected'),
                        ),
                        TextButton(
                          onPressed: snapshot.controller.clearSelection,
                          child: const Text('Clear'),
                        ),
                        FilledButton(
                          onPressed: snapshot.selection.isEmpty
                              ? null
                              : snapshot.confirm,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                ),
                containerBuilder: (context, child) => DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.primary, width: 4),
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
