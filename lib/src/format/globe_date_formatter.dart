/// Month, weekday and day period names used when formatting dates.
///
/// English names are used by default. Pass your own instance to format dates
/// in another language:
///
/// ```dart
/// const germanSymbols = GlobeDateSymbols(
///   monthNames: ['Januar', 'Februar', /* ... */],
///   // ...
/// );
/// GlobeData.formatDate(date, pattern: 'd. MMMM yyyy', symbols: germanSymbols);
/// ```
class GlobeDateSymbols {
  /// Creates date symbols. Month lists need 12 entries, weekday lists 7
  /// entries starting with Monday.
  const GlobeDateSymbols({
    required this.monthNames,
    required this.shortMonthNames,
    required this.weekdayNames,
    required this.shortWeekdayNames,
    this.amLabel = 'AM',
    this.pmLabel = 'PM',
  });

  /// English symbols.
  static const english = GlobeDateSymbols(
    monthNames: [
      'January', 'February', 'March', 'April', 'May', 'June', //
      'July', 'August', 'September', 'October', 'November', 'December',
    ],
    shortMonthNames: [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ],
    weekdayNames: [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', //
      'Saturday', 'Sunday',
    ],
    shortWeekdayNames: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  );

  /// Full month names, January first.
  final List<String> monthNames;

  /// Abbreviated month names, January first.
  final List<String> shortMonthNames;

  /// Full weekday names, Monday first.
  final List<String> weekdayNames;

  /// Abbreviated weekday names, Monday first.
  final List<String> shortWeekdayNames;

  /// Label for times before noon in 12-hour patterns.
  final String amLabel;

  /// Label for times after noon in 12-hour patterns.
  final String pmLabel;
}

/// Formats [dateTime] with an ICU style [pattern].
///
/// Supported fields: `G` (era), `y yy yyyy`, `Q QQ QQQ` (quarter),
/// `M MM MMM MMMM MMMMM` (and `L`), `d dd`, `D` (day of year),
/// `E EEE EEEE EEEEE`, `H HH` (0-23), `k kk` (1-24), `h hh` (1-12),
/// `K KK` (0-11), `m mm`, `s ss`, `S...` (fraction of a second), `a` and
/// `z` (time zone name). Five letters (`MMMMM`, `EEEEE`) give the narrow
/// form, the first letter of the name. Other letters are written as is, so
/// quote literal text: `'at'`. Text inside single quotes is copied as is,
/// and `''` writes one quote.
String formatDatePattern(
  DateTime dateTime,
  String pattern, {
  GlobeDateSymbols symbols = GlobeDateSymbols.english,
}) {
  final output = StringBuffer();
  var index = 0;
  while (index < pattern.length) {
    final character = pattern[index];

    if (character == "'") {
      index = _writeQuotedText(pattern, index, output);
      continue;
    }

    if (!_isPatternLetter(character)) {
      output.write(character);
      index++;
      continue;
    }

    var runLength = 1;
    while (index + runLength < pattern.length &&
        pattern[index + runLength] == character) {
      runLength++;
    }
    output.write(_formatField(dateTime, character, runLength, symbols));
    index += runLength;
  }
  return output.toString();
}

/// Writes the quoted text starting at the quote at [start] and returns the
/// index after it. `''` writes a single quote, inside or outside quotes.
int _writeQuotedText(String pattern, int start, StringBuffer output) {
  if (start + 1 < pattern.length && pattern[start + 1] == "'") {
    output.write("'");
    return start + 2;
  }
  var index = start + 1;
  while (index < pattern.length) {
    if (pattern[index] == "'") {
      if (index + 1 < pattern.length && pattern[index + 1] == "'") {
        output.write("'");
        index += 2;
        continue;
      }
      return index + 1;
    }
    output.write(pattern[index]);
    index++;
  }
  return index;
}

bool _isPatternLetter(String character) {
  final code = character.codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5a) || (code >= 0x61 && code <= 0x7a);
}

String _formatField(
  DateTime dateTime,
  String field,
  int width,
  GlobeDateSymbols symbols,
) {
  // A negative year keeps its sign in front of the padding: -0005.
  String padded(int value, int minimumWidth) => value < 0
      ? '-${(-value).toString().padLeft(minimumWidth, '0')}'
      : value.toString().padLeft(minimumWidth, '0');
  String narrow(String name) => name.isEmpty ? name : name.substring(0, 1);

  switch (field) {
    case 'G':
      return dateTime.year > 0 ? 'AD' : 'BC';
    case 'y':
      if (width == 2) return padded(dateTime.year.abs() % 100, 2);
      return padded(dateTime.year, width);
    case 'Q':
      final quarter = (dateTime.month - 1) ~/ 3 + 1;
      return width >= 3 ? 'Q$quarter' : padded(quarter, width);
    case 'M':
    case 'L':
      final month = dateTime.month - 1;
      if (width >= 5) return narrow(symbols.monthNames[month]);
      if (width == 4) return symbols.monthNames[month];
      if (width == 3) return symbols.shortMonthNames[month];
      return padded(dateTime.month, width);
    case 'd':
      return padded(dateTime.day, width);
    case 'D':
      final startOfYear = DateTime.utc(dateTime.year);
      final day = DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
      return padded(day.difference(startOfYear).inDays + 1, width);
    case 'E':
      final weekday = dateTime.weekday - 1;
      if (width >= 5) return narrow(symbols.weekdayNames[weekday]);
      return width == 4
          ? symbols.weekdayNames[weekday]
          : symbols.shortWeekdayNames[weekday];
    case 'H':
      return padded(dateTime.hour, width);
    case 'k':
      return padded(dateTime.hour == 0 ? 24 : dateTime.hour, width);
    case 'h':
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      return padded(hour, width);
    case 'K':
      return padded(dateTime.hour % 12, width);
    case 'z':
      return dateTime.timeZoneName;
    case 'm':
      return padded(dateTime.minute, width);
    case 's':
      return padded(dateTime.second, width);
    case 'S':
      final fraction = padded(
        dateTime.millisecond * 1000 + dateTime.microsecond,
        6,
      );
      return width <= 6
          ? fraction.substring(0, width)
          : fraction.padRight(width, '0');
    case 'a':
      return dateTime.hour < 12 ? symbols.amLabel : symbols.pmLabel;
    default:
      return field * width;
  }
}
