import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../lottie.dart';
import 'composition.dart';
import 'frame_rate.dart';
import 'providers/asset_provider.dart';
import 'providers/file_provider.dart';
import 'providers/load_image.dart';
import 'providers/lottie_provider.dart';
import 'providers/memory_provider.dart';
import 'providers/network_provider.dart';

typedef LottieFrameBuilder = Widget Function(
  BuildContext context,
  Widget child,
  LottieComposition? composition,
);

/// Signature used by [Lottie.errorBuilder] to create a replacement widget to
/// render instead of the image.
typedef LottieErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// A widget that displays a Lottie animation.
///
/// Several constructors are provided for the various ways that a Lottie file
/// can be provided:
///
///  * [new Lottie], for obtaining a composition from a [LottieProvider].
///  * [new Lottie.asset], for obtaining a Lottie file from an [AssetBundle]
///    using a key.
///  * [new Lottie.network], for obtaining a lottie file from a URL.
///  * [new Lottie.file], for obtaining a lottie file from a [File].
///  * [new Lottie.memory], for obtaining a lottie file from a [Uint8List].
///
class Lottie extends StatefulWidget {
  const Lottie({
    Key? key,
    required this.lottie,
    this.frameRate = FrameRate.max,
    this.animate = true,
    this.reverse = false,
    this.repeat = true,
    this.delegates,
    this.options = const LottieOptions(),
    this.onLoaded,
    this.frameBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.addRepaintBoundary = true,
    this.onWarning,
    this.interval = Duration.zero,
    this.delay = Duration.zero,
  })  : _preferRepeatingSimulation = delay == Duration.zero && interval == Duration.zero,
        super(key: key);

  /// Creates a widget that displays an [LottieComposition] obtained from the network.
  Lottie.network(
    String src, {
    Key? key,
    LottieImageProviderFactory? imageProviderFactory,
    Map<String, String>? headers,
    this.frameRate = FrameRate.max,
    this.animate = true,
    this.reverse = false,
    this.repeat = true,
    this.delegates,
    this.options = const LottieOptions(),
    this.onLoaded,
    this.frameBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.addRepaintBoundary = true,
    this.onWarning,
    this.interval = Duration.zero,
    this.delay = Duration.zero,
  })  : lottie = NetworkLottie(src, headers: headers, imageProviderFactory: imageProviderFactory),
        _preferRepeatingSimulation = delay == Duration.zero && interval == Duration.zero,
        super(key: key);

  /// Creates a widget that displays an [LottieComposition] obtained from a [File].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the animation is loaded, which
  /// will result in ugly layout changes.
  ///
  /// On Android, this may require the
  /// `android.permission.READ_EXTERNAL_STORAGE` permission.
  ///
  Lottie.file(
    Object /*io.File|html.File*/ file, {
    Key? key,
    LottieImageProviderFactory? imageProviderFactory,
    this.frameRate = FrameRate.max,
    this.animate = true,
    this.reverse = false,
    this.repeat = true,
    this.delegates,
    this.options = const LottieOptions(),
    this.onLoaded,
    this.frameBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.addRepaintBoundary = true,
    this.onWarning,
    this.interval = Duration.zero,
    this.delay = Duration.zero,
  })  : lottie = FileLottie(file, imageProviderFactory: imageProviderFactory),
        _preferRepeatingSimulation = delay == Duration.zero && interval == Duration.zero,
        super(key: key);

  /// Creates a widget that displays an [LottieComposition] obtained from an [AssetBundle].
  Lottie.asset(
    String name, {
    Key? key,
    LottieImageProviderFactory? imageProviderFactory,
    String? package,
    AssetBundle? bundle,
    this.frameRate = FrameRate.max,
    this.animate = true,
    this.reverse = false,
    this.repeat = true,
    this.delegates,
    this.options = const LottieOptions(),
    this.onLoaded,
    this.frameBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.addRepaintBoundary = true,
    this.onWarning,
    this.interval = Duration.zero,
    this.delay = Duration.zero,
  })  : lottie = AssetLottie(name, bundle: bundle, package: package, imageProviderFactory: imageProviderFactory),
        _preferRepeatingSimulation = delay == Duration.zero && interval == Duration.zero,
        super(key: key);

  /// Creates a widget that displays an [LottieComposition] obtained from a [Uint8List].
  Lottie.memory(
    Uint8List bytes, {
    Key? key,
    LottieImageProviderFactory? imageProviderFactory,
    this.frameRate = FrameRate.max,
    this.animate = true,
    this.reverse = false,
    this.repeat = true,
    this.delegates,
    this.options = const LottieOptions(),
    this.onLoaded,
    this.errorBuilder,
    this.frameBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.addRepaintBoundary = true,
    this.onWarning,
    this.interval = Duration.zero,
    this.delay = Duration.zero,
  })  : lottie = MemoryLottie(bytes, imageProviderFactory: imageProviderFactory),
        _preferRepeatingSimulation = delay == Duration.zero && interval == Duration.zero,
        super(key: key);

  final bool _preferRepeatingSimulation;

  /// Interval between repeating animations.
  final Duration interval;

  /// The delay of the first animation.
  final Duration delay;

  /// The lottie animation to load.
  /// Example of providers: [AssetLottie], [NetworkLottie], [FileLottie], [MemoryLottie]
  final LottieProvider lottie;

  /// A callback called when the LottieComposition has been loaded.
  /// You can use this callback to set the correct duration on the AnimationController
  /// with `composition.duration`
  final void Function(LottieComposition)? onLoaded;

  /// The number of frames per second to render.
  /// Use `FrameRate.composition` to use the original frame rate of the Lottie composition (default)
  /// Use `FrameRate.max` to advance the animation progression at every frame.
  final FrameRate frameRate;

  /// If no controller is specified, this value indicate whether or not the
  /// Lottie animation should be played automatically (default to true).
  /// If there is an animation controller specified, this property has no effect.
  ///
  /// See [repeat] to control whether the animation should repeat.
  final bool animate;

  /// Specify that the automatic animation should repeat in a loop (default to true).
  /// The property has no effect if [animate] is false or [controller] is not null.
  final bool repeat;

  /// Specify that the automatic animation should repeat in a loop in a "reverse"
  /// mode (go from start to end and then continuously from end to start).
  /// It default to false.
  /// The property has no effect if [animate] is false, [repeat] is false or [controller] is not null.
  final bool reverse;

  /// A group of options to further customize the lottie animation.
  /// - A [text] delegate to dynamically change some text displayed in the animation
  /// - A value callback to change the properties of the animation at runtime.
  /// - A text style factory to map between a font family specified in the animation
  ///   and the font family in your assets.
  final LottieDelegates? delegates;

  /// Some options to enable/disable some feature of Lottie
  /// - enableMergePaths: Enable merge path support
  final LottieOptions options;

  /// A builder function responsible for creating the widget that represents
  /// this lottie animation.
  ///
  /// If this is null, this widget will display a lottie animation that is painted as
  /// soon as it is available (and will appear to "pop" in
  /// if it becomes available asynchronously). Callers might use this builder to
  /// add effects to the animation (such as fading the animation in when it becomes
  /// available) or to display a placeholder widget while the animation is loading.
  ///
  /// To have finer-grained control over the way that an animation's loading
  /// progress is communicated to the user, see [loadingBuilder].
  ///
  /// {@template lottie.chainedBuildersExample}
  /// ```dart
  /// Lottie(
  ///   ...
  ///   frameBuilder: (BuildContext context, Widget child) {
  ///     return Padding(
  ///       padding: EdgeInsets.all(8.0),
  ///       child: child,
  ///     );
  ///   }
  /// )
  /// ```
  ///
  /// In this example, the widget hierarchy will contain the following:
  ///
  /// ```dart
  /// Center(
  ///   Padding(
  ///     padding: EdgeInsets.all(8.0),
  ///     child: <lottie>,
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  ///
  /// {@tool snippet --template=stateless_widget_material}
  ///
  /// The following sample demonstrates how to use this builder to implement an
  /// animation that fades in once it's been loaded.
  ///
  /// This sample contains a limited subset of the functionality that the
  /// [FadeInImage] widget provides out of the box.
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return DecoratedBox(
  ///     decoration: BoxDecoration(
  ///       color: Colors.white,
  ///       border: Border.all(),
  ///       borderRadius: BorderRadius.circular(20),
  ///     ),
  ///     child: Lottie.network(
  ///       'https://example.com/animation.json',
  ///       frameBuilder: (BuildContext context, Widget child) {
  ///         if (wasSynchronouslyLoaded) {
  ///           return child;
  ///         }
  ///         return AnimatedOpacity(
  ///           child: child,
  ///           opacity: frame == null ? 0 : 1,
  ///           duration: const Duration(seconds: 1),
  ///           curve: Curves.easeOut,
  ///         );
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  final LottieFrameBuilder? frameBuilder;

  /// If non-null, require the lottie animation to have this width.
  ///
  /// If null, the lottie animation will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the animation does not change size as it loads.
  /// Consider using [fit] to adapt the animation's rendering to fit the given width
  /// and height if the exact animation dimensions are not known in advance.
  final double? width;

  /// If non-null, require the lottie animation to have this height.
  ///
  /// If null, the lottie animation will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the animation does not change size as it loads.
  /// Consider using [fit] to adapt the animation's rendering to fit the given width
  /// and height if the exact animation dimensions are not known in advance.
  final double? height;

  /// How to inscribe the animation into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the animation within its bounds.
  ///
  /// The alignment aligns the given position in the animation to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the animation to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// animation with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the animation with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// To display a subpart of an animation, consider using a [CustomPainter] and
  /// [Canvas.drawImageRect].
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// Indicate to automatically add a `RepaintBoundary` widget around the animation.
  /// This allows to optimize the app performance by isolating the animation in its
  /// own `Layer`.
  ///
  /// This property is `true` by default.
  final bool addRepaintBoundary;

  /// A callback called when there is a warning during the loading or painting
  /// of the animation.
  final LottieWarningCallback? onWarning;

  /// A builder function that is called if an error occurs during loading.
  ///
  /// If this builder is not provided, any exceptions will be reported to
  /// [FlutterError.onError]. If it is provided, the caller should either handle
  /// the exception by providing a replacement widget, or rethrow the exception.
  ///
  /// The following sample uses [errorBuilder] to show a '😢' in place of the
  /// image that fails to load, and prints the error to the console.
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return DecoratedBox(
  ///     decoration: BoxDecoration(
  ///       color: Colors.white,
  ///     ),
  ///     child: Lottie.network(
  ///       'https://example.does.not.exist/lottie.json',
  ///       errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
  ///         // Appropriate logging or analytics, e.g.
  ///         // myAnalytics.recordError(
  ///         //   'An error occurred loading "https://example.does.not.exist/animation.json"',
  ///         //   exception,
  ///         //   stackTrace,
  ///         // );
  ///         return const Text('😢');
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  _LottieState createState() => _LottieState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LottieProvider>('lottie', lottie));
    properties.add(DiagnosticsProperty<Function>('frameBuilder', frameBuilder));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: null));
  }
}

class _LottieState extends State<Lottie> with SingleTickerProviderStateMixin<Lottie>, WidgetsBindingObserver {
  static const _kDefaultDuration = Duration(seconds: 1);

  late AnimationController _controller;
  LottieComposition? _composition;
  Future<LottieComposition>? _loadingFuture;
  Object? _error;
  StackTrace? _errorStacktrace;
  Timer? _intervalTimer;
  double _progress = 0.0; // Animation progress of [_composition].

  void _handleCompositionLoaded(LottieComposition composition) {
    _composition = composition;
    _controller.duration = composition.duration;
    widget.onLoaded?.call(composition);
  }

  void _scheduleForward([Duration? delay]) {
    _intervalTimer?.cancel();
    _intervalTimer = Timer(delay ?? widget.interval, () => _controller.forward(from: 0.0));
  }

  void _handleToggle() {
    final wasAnimating = _controller.isAnimating;

    // Stop anything that could still animate the controller.
    _intervalTimer?.cancel();
    _controller.stop();

    if (!widget.animate) return; // Not needed to begin the animation.

    if (widget.repeat && widget._preferRepeatingSimulation) {
      _controller.repeat(reverse: widget.reverse); // Prefer the repeating simulation, when possible.
    } else {
      final delay = !wasAnimating ? widget.delay : widget.interval;
      if (delay > Duration.zero) {
        _scheduleForward(delay);
      } else {
        _controller.forward();
      }
    }
  }

  void _handleAnimation() {
    if (_error != null || _composition == null) return;

    final progress = _composition!.roundProgress(_controller.value, frameRate: widget.frameRate);
    if (progress != _progress) {
      _progress = progress;
      markNeedsBuild();
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        if (widget.animate) {
          if (widget.interval > Duration.zero) {
            _scheduleForward();
          } else {
            _controller.forward(from: 0.0);
          }
        }
        break;
      case AnimationStatus.completed:
        if (widget.animate) {
          if (widget.reverse) {
            _controller.reverse();
          } else if (widget.interval > Duration.zero) {
            _scheduleForward();
          } else {
            _controller.forward(from: 0.0);
          }
        }
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break; // Do nothing.
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _composition?.duration ?? _kDefaultDuration,
      animationBehavior: AnimationBehavior.preserve,
    )
      ..addStatusListener(_handleAnimationStatus)
      ..addListener(_handleAnimation);

    _handleToggle();
    _loadComposition();

    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _controller.dispose();
    _intervalTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(Lottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lottie != widget.lottie) _loadComposition();
    if (oldWidget.animate != widget.animate || oldWidget.interval != widget.interval) _handleToggle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_controller.isAnimating && widget.animate) _handleToggle();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _intervalTimer?.cancel();
        break;
    }
  }

  Future _loadComposition() async {
    final targetLottie = widget.lottie;

    _loadingFuture = widget.lottie.load();

    try {
      final composition = await _loadingFuture;
      if (composition != null && mounted && widget.lottie == targetLottie) {
        if (widget.onWarning != null) {
          composition.onWarning = widget.onWarning;

          for (final warning in composition.warnings) {
            widget.onWarning!(warning);
          }
        }

        _error = null;
        _errorStacktrace = null;
        _handleCompositionLoaded(composition);
        markNeedsBuild();
      }
    } catch (e, t) {
      if (mounted) {
        _error = e;
        _errorStacktrace = t;
        markNeedsBuild();
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, _errorStacktrace);
      } else if (kDebugMode) {
        return ErrorWidget(_error!);
      }
    }

    final lottieWidget = RawLottie(
      key: ValueKey(_composition),
      composition: _composition,
      delegates: widget.delegates,
      options: widget.options,
      progress: _progress,
      frameRate: widget.frameRate,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      willChange: widget.animate,
      isComplex: true,
    );

    final repaintBoundary = widget.addRepaintBoundary
        ? RepaintBoundary(
            key: lottieWidget.key,
            child: lottieWidget,
          )
        : lottieWidget;

    return widget.frameBuilder?.call(context, repaintBoundary, _composition) ?? repaintBoundary;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<Future<LottieComposition>>('loadingFuture', _loadingFuture));
  }
}
