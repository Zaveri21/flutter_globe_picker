import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_globe_picker/src/globe_data.dart';
import 'package:flutter_globe_picker/src/models/globe_models.dart';
import 'package:flutter_globe_picker/src/picker/globe_picker_options.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shows a flag as an emoji or a bundled SVG.
///
/// ```dart
/// GlobeFlag(code: 'IN');
/// GlobeFlag.fromItem(country, shape: GlobeFlagShape.circle, width: 40);
/// GlobeFlag.fromItem(GlobeData.currencyByCode('EUR')!); // EU flag
/// ```
class GlobeFlag extends StatelessWidget {
  /// Creates a flag for an ISO alpha-2 [code] (`IN`, `us`), or `eu` for the
  /// European Union. Unknown codes show a neutral placeholder.
  const GlobeFlag({
    required this.code,
    this.type = GlobeFlagType.auto,
    this.shape = GlobeFlagShape.rectangle,
    this.width = 32,
    this.height,
    this.borderRadius = 4,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    super.key,
  });

  /// Creates the flag of any picker item: a country, the issuing country of
  /// a currency (EU flag for the euro) or the main country of a dial code.
  GlobeFlag.fromItem(
    GlobeItem item, {
    GlobeFlagType type = GlobeFlagType.auto,
    GlobeFlagShape shape = GlobeFlagShape.rectangle,
    double width = 32,
    double? height,
    double borderRadius = 4,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    Key? key,
  }) : this(
         code: item.flagCode ?? _unknownFlagCode,
         type: type,
         shape: shape,
         width: width,
         height: height,
         borderRadius: borderRadius,
         semanticLabel: semanticLabel,
         excludeFromSemantics: excludeFromSemantics,
         key: key,
       );

  static const _unknownFlagCode = 'xx';
  static const _bundledExtraCodes = {'eu', 'xx'};

  /// ISO alpha-2 code, or `eu` / `xx`.
  final String code;

  /// Emoji or SVG.
  final GlobeFlagType type;

  /// Rectangle, square or circle.
  final GlobeFlagShape shape;

  /// Width of the flag.
  final double width;

  /// Height of the flag. Defaults to 3/4 of [width] for rectangles and to
  /// [width] for squares and circles.
  final double? height;

  /// Corner radius of rectangles and squares.
  final double borderRadius;

  /// Accessibility label. Defaults to `Flag of` followed by the country name.
  final String? semanticLabel;

  /// Hides the flag from screen readers, for example when the country name
  /// is already shown next to it.
  final bool excludeFromSemantics;

  /// Whether [type] resolves to SVG on the current platform.
  static bool usesSvg(GlobeFlagType type) => switch (type) {
    GlobeFlagType.svg => true,
    GlobeFlagType.emoji => false,
    GlobeFlagType.auto => switch (defaultTargetPlatform) {
      TargetPlatform.windows || TargetPlatform.linux => true,
      _ => false,
    },
  };

  @override
  Widget build(BuildContext context) {
    final normalizedCode = _normalizedCode;
    final resolvedHeight =
        height ?? (shape == GlobeFlagShape.rectangle ? width * 3 / 4 : width);
    final flag = usesSvg(type)
        ? _buildSvg(normalizedCode, resolvedHeight)
        : _buildEmoji(normalizedCode, resolvedHeight);

    if (excludeFromSemantics) return ExcludeSemantics(child: flag);
    return Semantics(
      label: semanticLabel ?? _defaultSemanticLabel(normalizedCode),
      image: true,
      child: ExcludeSemantics(child: flag),
    );
  }

  static final _twoLetters = RegExp(r'^[a-z]{2}$');

  String get _normalizedCode {
    final lower = code.trim().toLowerCase();
    if (_bundledExtraCodes.contains(lower)) return lower;
    // Flags do not need the data: before it is loaded, trust the code shape.
    if (!GlobeData.isLoaded) {
      return _twoLetters.hasMatch(lower) ? lower : _unknownFlagCode;
    }
    return GlobeData.countryByAlpha2(lower) == null ? _unknownFlagCode : lower;
  }

  Widget _buildSvg(String normalizedCode, double resolvedHeight) {
    final aspect = shape == GlobeFlagShape.rectangle
        ? GlobeFlagAspect.rectangle
        : GlobeFlagAspect.square;
    final picture = SvgPicture.asset(
      'assets/flags/${aspect.folder}/$normalizedCode.svg',
      package: 'flutter_globe_picker',
      width: width,
      height: resolvedHeight,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    );
    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: switch (shape) {
        GlobeFlagShape.circle => ClipOval(child: picture),
        _ => ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: picture,
        ),
      },
    );
  }

  Widget _buildEmoji(String normalizedCode, double resolvedHeight) {
    final emoji = normalizedCode == _unknownFlagCode
        ? '\u{1F3F3}\u{FE0F}'
        : flagEmojiFor(normalizedCode);
    final fontSize = shape == GlobeFlagShape.rectangle
        ? resolvedHeight * 0.95
        : resolvedHeight * 0.8;
    final text = Text(
      emoji,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
      style: TextStyle(fontSize: fontSize, height: 1),
    );
    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: Center(
        child: shape == GlobeFlagShape.circle
            ? ClipOval(
                child: FittedBox(fit: BoxFit.cover, child: text),
              )
            : FittedBox(fit: BoxFit.contain, child: text),
      ),
    );
  }

  static String _defaultSemanticLabel(String normalizedCode) {
    if (normalizedCode == 'eu') return 'Flag of the European Union';
    if (!GlobeData.isLoaded) return 'Flag';
    final country = GlobeData.countryByAlpha2(normalizedCode);
    return country == null ? 'Flag' : 'Flag of ${country.name}';
  }
}
