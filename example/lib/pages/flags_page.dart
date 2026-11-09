import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

/// GlobeFlag in every type, shape and size, plus every bundled flag.
class FlagsPage extends StatefulWidget {
  const FlagsPage({super.key});

  @override
  State<FlagsPage> createState() => _FlagsPageState();
}

class _FlagsPageState extends State<FlagsPage> {
  GlobeFlagType _flagType = GlobeFlagType.svg;
  GlobeFlagShape _flagShape = GlobeFlagShape.rectangle;
  double _flagWidth = 48;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final euro = GlobeData.currencyByCode('EUR')!;
    final plusOne = GlobeData.dialCodeByCode('+1')!;
    return Scaffold(
      appBar: AppBar(title: const Text('Flags')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                SegmentedButton<GlobeFlagType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: GlobeFlagType.auto,
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: GlobeFlagType.emoji,
                      label: Text('Emoji'),
                    ),
                    ButtonSegment(value: GlobeFlagType.svg, label: Text('SVG')),
                  ],
                  selected: {_flagType},
                  onSelectionChanged: (types) =>
                      setState(() => _flagType = types.first),
                ),
                const SizedBox(height: 8),
                SegmentedButton<GlobeFlagShape>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: GlobeFlagShape.rectangle,
                      label: Text('Rectangle'),
                    ),
                    ButtonSegment(
                      value: GlobeFlagShape.square,
                      label: Text('Square'),
                    ),
                    ButtonSegment(
                      value: GlobeFlagShape.circle,
                      label: Text('Circle'),
                    ),
                  ],
                  selected: {_flagShape},
                  onSelectionChanged: (shapes) =>
                      setState(() => _flagShape = shapes.first),
                ),
                Row(
                  children: [
                    Text('Width ${_flagWidth.round()}'),
                    Expanded(
                      child: Slider(
                        min: 16,
                        max: 96,
                        value: _flagWidth,
                        onChanged: (value) =>
                            setState(() => _flagWidth = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('From any item', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _LabeledFlag(
                      label: 'Euro → EU flag',
                      flag: GlobeFlag.fromItem(
                        euro,
                        type: _flagType,
                        shape: _flagShape,
                        width: _flagWidth,
                      ),
                    ),
                    _LabeledFlag(
                      label: '+1 → United States',
                      flag: GlobeFlag.fromItem(
                        plusOne,
                        type: _flagType,
                        shape: _flagShape,
                        width: _flagWidth,
                      ),
                    ),
                    _LabeledFlag(
                      label: 'Unknown code',
                      flag: GlobeFlag(
                        code: 'zz',
                        type: _flagType,
                        shape: _flagShape,
                        width: _flagWidth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'All ${GlobeData.countries.length} flags',
                  style: textTheme.titleMedium,
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: _flagWidth + 48,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: GlobeData.countries.length,
              itemBuilder: (context, index) {
                final country = GlobeData.countries[index];
                return Tooltip(
                  message: country.name,
                  child: _LabeledFlag(
                    label: country.alpha2Code,
                    flag: GlobeFlag.fromItem(
                      country,
                      type: _flagType,
                      shape: _flagShape,
                      width: _flagWidth,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledFlag extends StatelessWidget {
  const _LabeledFlag({required this.label, required this.flag});

  final String label;
  final Widget flag;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        flag,
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
