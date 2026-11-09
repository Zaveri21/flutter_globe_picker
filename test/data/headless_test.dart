// Uses the data and models alone, as a custom UI would.
import 'package:flutter_globe_picker/flutter_globe_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('models, lookups, search and formatting without widgets', () {
    final india = GlobeData.countryByAlpha2('IN')!;
    expect(india.currency?.format(1234.5), '₹1,234.50');
    expect(GlobeData.searchCountries('germ').first.alpha2Code, 'DE');
    expect(GlobeData.parsePhone('+91 98765 43210')?.e164, '+919876543210');
    expect(GlobeFilter.europeanUnion.apply(GlobeData.countries).length, 27);
    final copy = GlobeCountry.fromJson(india.toJson());
    expect(copy, india);
    expect(copy.toJson(), india.toJson());
  });
}
