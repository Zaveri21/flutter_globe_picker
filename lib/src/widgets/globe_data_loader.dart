import 'package:flutter/widgets.dart';

import 'package:flutter_globe_picker/src/globe_data.dart';
import 'package:flutter_globe_picker/src/globe_data_source.dart';

/// Builds [builder] once the data of [source] is loaded, and [placeholder]
/// until then.
///
/// Every picker widget uses it, so you only need it for your own widgets
/// that read `GlobeData` while it may not be loaded yet:
///
/// ```dart
/// GlobeDataLoader(
///   builder: (context) => Text(GlobeData.countryByAlpha2('IN')!.name),
/// )
/// ```
///
/// A `null` [source] uses the data already loaded, or loads the bundled
/// data. Content rebuilds when the data is replaced, and a failed load is
/// tried again on the next rebuild.
class GlobeDataLoader extends StatefulWidget {
  /// Creates a data loader.
  const GlobeDataLoader({
    required this.builder,
    this.source,
    this.placeholder = const SizedBox.shrink(),
    super.key,
  });

  /// Builds the content once the data is loaded.
  final WidgetBuilder builder;

  /// The data to load. `null` accepts any loaded data.
  final GlobeDataSource? source;

  /// Shown while loading.
  final Widget placeholder;

  @override
  State<GlobeDataLoader> createState() => _GlobeDataLoaderState();
}

class _GlobeDataLoaderState extends State<GlobeDataLoader> {
  Object? _error;

  /// Whether this widget's own load finished. A newer load (from another
  /// widget or `GlobeData.load`) may have replaced the data since; the app
  /// has one data set, so the newest one is shown.
  bool _settled = false;

  /// The load started for this source, so a new one is not started on every
  /// rebuild while it is pending.
  GlobeDataSource? _requestedSource;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    GlobeData.changes.addListener(_handleDataChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) _load();
  }

  @override
  void didUpdateWidget(GlobeDataLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new source, or a retry after an error.
    if (oldWidget.source != widget.source || _error != null) _load();
  }

  @override
  void dispose() {
    GlobeData.changes.removeListener(_handleDataChange);
    super.dispose();
  }

  void _handleDataChange() {
    if (mounted) setState(() {});
  }

  void _load() {
    final source = widget.source;
    _requested = true;
    _requestedSource = source;
    _settled = false;
    _error = null;
    if (GlobeData.isLoadedFrom(source)) {
      _settled = true;
      return;
    }
    GlobeData.ensureLoaded(source, DefaultAssetBundle.of(context)).then(
      (_) {
        if (mounted && source == _requestedSource) {
          setState(() => _settled = true);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'flutter_globe_picker',
            context: ErrorDescription('while loading the data'),
          ),
        );
        if (mounted && source == _requestedSource) {
          setState(() => _error = error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (GlobeData.isLoadedFrom(widget.source) ||
        (_settled && GlobeData.isLoaded)) {
      return widget.builder(context);
    }
    final error = _error;
    if (error != null) return ErrorWidget(error);
    return widget.placeholder;
  }
}
