/// Geographic regions based on the UN M.49 standard.
enum GlobeRegion {
  /// Africa.
  africa('Africa'),

  /// North, Central and South America and the Caribbean.
  americas('Americas'),

  /// Antarctica.
  antarctica('Antarctica'),

  /// Asia.
  asia('Asia'),

  /// Europe.
  europe('Europe'),

  /// Oceania.
  oceania('Oceania');

  const GlobeRegion(this.label);

  /// English display name, for example `Europe`.
  final String label;

  /// Returns the region with the given [name] (such as `europe`), or `null`.
  static GlobeRegion? tryParse(String name) {
    final normalized = name.trim().toLowerCase();
    for (final region in values) {
      if (region.name == normalized) return region;
    }
    return null;
  }

  @override
  String toString() => label;
}
