import 'dart:ui' show Locale;

import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/search/globe_field.dart';

/// Pre-computed, normalized search text for a list of items.
///
/// Build it once per list and search configuration, then call [search] on
/// every keystroke.
class GlobeSearchIndex<T extends GlobeItem> {
  /// Indexes [items] on [fields]. Names are indexed in the language of
  /// [locale] and in English, together with known aliases such as
  /// "Ivory Coast".
  GlobeSearchIndex(
    List<T> items, {
    required List<GlobeField> fields,
    Locale? locale,
  }) : _entries = [
         for (var index = 0; index < items.length; index++)
           _IndexEntry(
             items[index],
             index,
             _searchableValues(items[index], fields, locale),
           ),
       ];

  final List<_IndexEntry<T>> _entries;

  /// Items matching [query], best matches first. An empty query returns
  /// every item in its original order.
  ///
  /// Matching ignores case, accents and punctuation, so `cote d iv` finds
  /// "Côte d'Ivoire" and `91` finds `+91`.
  List<T> search(String query) {
    final normalizedQuery = normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return [for (final entry in _entries) entry.item];
    }
    final wordQuery = ' $normalizedQuery';
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    final matches = <(_IndexEntry<T>, int)>[];
    for (final entry in _entries) {
      final score = entry.score(normalizedQuery, wordQuery, compactQuery);
      if (score != null) matches.add((entry, score));
    }
    // For a number such as `+44`, the main country of the code comes before
    // the territories sharing it (UK before Guernsey, Isle of Man, Jersey).
    final isNumberQuery = _digitsOnly.hasMatch(normalizedQuery);
    int mainCountryRank(_IndexEntry<T> entry) =>
        isNumberQuery &&
            (entry.item.representativeCountry?.isMainCountryForDialCode ??
                false)
        ? 0
        : 1;
    matches.sort((first, second) {
      final byScore = first.$2.compareTo(second.$2);
      if (byScore != 0) return byScore;
      final byMainCountry = mainCountryRank(first.$1)
          .compareTo(mainCountryRank(second.$1));
      return byMainCountry != 0
          ? byMainCountry
          : first.$1.position.compareTo(second.$1.position);
    });
    return [for (final match in matches) match.$1.item];
  }

  static final _digitsOnly = RegExp(r'^\d+$');

  static List<String> _searchableValues(
    GlobeItem item,
    List<GlobeField> fields,
    Locale? locale,
  ) {
    final values = <String>{};
    for (final field in fields) {
      values.addAll(globeFieldValues(item, field, locale: locale));
      // English names and aliases match in every language.
      if (locale != null &&
          (field == GlobeField.countryName ||
              field == GlobeField.currencyName)) {
        values.addAll(globeFieldValues(item, field));
      }
      if (field == GlobeField.countryName) {
        for (final country in item.countries) {
          values.addAll(country.aliases);
        }
      }
    }
    return [
      for (final value in values)
        if (normalizeSearchText(value) case final normalized
            when normalized.isNotEmpty)
          normalized,
    ];
  }
}

class _IndexEntry<T extends GlobeItem> {
  _IndexEntry(this.item, this.position, this.values)
    : compactValues = [for (final value in values) value.replaceAll(' ', '')];

  final T item;
  final int position;
  final List<String> values;

  /// [values] without spaces, so `cote divoire` and `cote d ivoire` match.
  final List<String> compactValues;

  /// Lower is better: 0 exact, 1 prefix, 2 word prefix, 3 contains,
  /// 4 contains when spaces are ignored.
  /// [wordQuery] is [query] after a space and [compactQuery] is [query]
  /// without spaces; both are computed once per search.
  int? score(String query, String wordQuery, String compactQuery) {
    int? best;
    for (final value in values) {
      final int? valueScore;
      if (value == query) {
        valueScore = 0;
      } else if (value.startsWith(query)) {
        valueScore = 1;
      } else if (value.contains(wordQuery)) {
        valueScore = 2;
      } else if (value.contains(query)) {
        valueScore = 3;
      } else {
        valueScore = null;
      }
      if (valueScore != null && (best == null || valueScore < best)) {
        best = valueScore;
        if (best == 0) break;
      }
    }
    if (best != null) return best;
    return compactValues.any((value) => value.contains(compactQuery))
        ? 4
        : null;
  }
}

/// Lowercases [text], removes accents and punctuation, and collapses
/// whitespace, so different spellings compare equal.
String normalizeSearchText(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    // Combining accents, as in decomposed (NFD) text: `o` + `\u0302`.
    if (rune >= 0x300 && rune <= 0x36f) continue;
    final replacement = _accentReplacements[rune];
    if (replacement != null) {
      buffer.write(replacement);
    } else if (_ignoredCharacters.contains(rune)) {
      continue;
    } else if (_spaceCharacters.contains(rune)) {
      buffer.writeCharCode(0x20);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString().replaceAll(_whitespace, ' ').trim();
}

final _whitespace = RegExp(r'\s+');

final Set<int> _ignoredCharacters = '+.,()[]"“”\u200e\u200f\u061c'.runes
    .toSet();

final Set<int> _spaceCharacters = "'‘’-_/&‐–—\u00a0\u202f".runes.toSet();

final Map<int, String> _accentReplacements = () {
  const groups = {
    'a': 'àáâãäåāăąǎǟǡǻȁȃȧạảấầẩẫậắằẳẵặ',
    'c': 'çćĉċč',
    'd': 'ďđ',
    'e': 'èéêëēĕėęěȅȇȩẹẻẽếềểễệ',
    'g': 'ĝğġģǧǵ',
    'h': 'ĥħ',
    'i': 'ìíîïĩīĭįıǐȉȋịỉ',
    'j': 'ĵ',
    'k': 'ķǩ',
    'l': 'ĺļľŀł',
    'n': 'ñńņňŉǹ',
    'o': 'òóôõöøōŏőơǒǫǭǿȍȏȫȭȯȱọỏốồổỗộớờởỡợ',
    'r': 'ŕŗřȑȓ',
    's': 'śŝşšșſ',
    't': 'ţťŧț',
    'u': 'ùúûüũūŭůűųưǔǖǘǚǜȕȗụủứừửữự',
    'w': 'ŵẁẃẅ',
    'y': 'ýÿŷȳỳỵỷỹ',
    'z': 'źżžƶ',
  };
  return {
    for (final group in groups.entries)
      for (final rune in group.value.runes) rune: group.key,
    'ß'.codeUnitAt(0): 'ss',
    'æ'.codeUnitAt(0): 'ae',
    'œ'.codeUnitAt(0): 'oe',
    'þ'.codeUnitAt(0): 'th',
    'ð'.codeUnitAt(0): 'd',
  };
}();
