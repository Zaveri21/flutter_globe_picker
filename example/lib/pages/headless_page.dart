import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/flutter_globe_picker.dart';

/// GlobePickerBuilder: the picker logic with a completely custom UI.
class HeadlessPage extends StatefulWidget {
  const HeadlessPage({super.key});

  @override
  State<HeadlessPage> createState() => _HeadlessPageState();
}

class _HeadlessPageState extends State<HeadlessPage> {
  GlobeCountry? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Headless builder')),
      body: GlobePickerBuilder(
        type: GlobePickerType.country,
        options: const GlobePickerOptions(groupBy: GlobeGroupBy.region),
        onSelected: (country) => setState(() => _selectedCountry = country),
        builder: (context, snapshot) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchBar(
                      hintText: 'Search ${snapshot.items.length} countries',
                      leading: const Icon(Icons.search),
                      onChanged: snapshot.search,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedCountry == null
                          ? 'Tap a flag'
                          : '${_selectedCountry!.name}, '
                                '${_selectedCountry!.capital ?? 'no capital'} · '
                                '${_selectedCountry!.subregion}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (snapshot.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No countries match')),
              ),
            for (final section in snapshot.sections) ...[
              if (section.title != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '${section.title} (${section.items.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 96,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: section.items.length,
                  itemBuilder: (context, index) {
                    final country = section.items[index];
                    final isSelected = snapshot.isSelected(country);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => snapshot.onItemTap(country),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlobeFlag.fromItem(
                              country,
                              type: GlobeFlagType.svg,
                              width: 44,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              country.localizedName(snapshot.locale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
