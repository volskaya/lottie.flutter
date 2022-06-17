import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import '../lottie.dart';
import 'frame_rate.dart';
import 'lottie_drawable.dart';

/// A Lottie animation in the render tree.
///
/// The RenderLottie attempts to find a size for itself that fits in the given
/// constraints and preserves the composition's intrinsic aspect ratio.
class RenderLottie extends RenderBox {
  RenderLottie({
    required LottieComposition? composition,
    required Animation<double> animation,
    LottieDelegates? delegates,
    bool enableMergePaths = false,
    bool antiAliasingSuggested = true,
    double progress = 0.0,
    FrameRate frameRate = FrameRate.max,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    this.isComplex = false,
    this.willChange = false,
  })  : assert(progress >= 0.0 && progress <= 1.0),
        _animation = animation,
        _width = width,
        _height = height,
        _fit = fit,
        _alignment = alignment,
        _scale = scale,
        _drawable = composition != null
            ? (LottieDrawable(
                composition,
                enableMergePaths: enableMergePaths,
                antiAliasingSuggested: antiAliasingSuggested,
              )
              ..setProgress(progress)
              ..delegates = delegates)
            : null;

  bool isComplex;
  bool willChange;
  LottieDrawable? _drawable;

  /// The lottie composition to display.
  LottieComposition? get composition => _drawable?.composition;
  void setComposition(
    LottieComposition? composition, {
    required LottieDelegates? delegates,
    bool? enableMergePaths,
  }) {
    assert(_animation != null); // Set animation first.

    var drawable = _drawable;
    enableMergePaths ??= false;

    var needsLayout = false;
    var needsPaint = false;
    if (composition == null) {
      if (drawable != null) {
        drawable = _drawable = null;
        needsPaint = true;
        needsLayout = true;
      }
    } else {
      if (drawable == null || drawable.composition != composition || drawable.enableMergePaths != enableMergePaths) {
        drawable = _drawable = LottieDrawable(composition, enableMergePaths: enableMergePaths);
        needsLayout = true;
        needsPaint = true;
      }

      _updateProgress();

      if (drawable.delegates != delegates) {
        drawable.delegates = delegates;
        needsPaint = true;
      }
    }

    if (needsPaint) {
      markNeedsPaint();
    }
    if (needsLayout && (_width == null || _height == null)) {
      markNeedsLayout();
    }
  }

  double? _previousEffectiveProgress;
  bool _updateProgress() {
    final effectiveProgress = composition?.roundProgress(animation.value, frameRate: frameRate) ?? 0;
    if (_previousEffectiveProgress != effectiveProgress) {
      _previousEffectiveProgress = effectiveProgress;
      if (_drawable != null) {
        _drawable!.setProgress(effectiveProgress);
        markNeedsPaint();
        return true;
      }
    }
    return false;
  }

  Animation<double> get animation => _animation!;
  Animation<double>? _animation;
  set animation(Animation<double> value) {
    if (_animation == value) return;
    if (attached && _animation != null) animation.removeListener(_updateProgress);
    _animation = value;
    if (attached) animation.addListener(_updateProgress);
    _updateProgress();
  }

  double get scale => _scale;
  double _scale = 1.0;
  set scale(double value) {
    if (value == _scale) {
      return;
    }
    _scale = value;
    markNeedsPaint();
  }

  FrameRate get frameRate => _frameRate;
  FrameRate _frameRate = FrameRate.max;
  set frameRate(FrameRate value) {
    if (value == _frameRate) {
      return;
    }
    _frameRate = value;
  }

  /// If non-null, requires the composition to have this width.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double? get width => _width;
  double? _width;
  set width(double? value) {
    if (value == _width) {
      return;
    }
    _width = value;
    markNeedsLayout();
  }

  /// If non-null, require the composition to have this height.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double? get height => _height;
  double? _height;
  set height(double? value) {
    if (value == _height) {
      return;
    }
    _height = value;
    markNeedsLayout();
  }

  /// How to inscribe the composition into the space allocated during layout.
  BoxFit get fit => _fit;
  BoxFit _fit = BoxFit.contain;
  set fit(BoxFit value) {
    if (value == _fit) {
      return;
    }
    _fit = value;
    markNeedsPaint();
  }

  /// How to align the composition within its bounds.
  ///
  /// If this is set to a text-direction-dependent value, [textDirection] must
  /// not be null.
  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (value == _alignment) {
      return;
    }
    _alignment = value;
  }

  /// Find a size for the render composition within the given constraints.
  ///
  ///  - The dimensions of the RenderLottie must fit within the constraints.
  ///  - The aspect ratio of the RenderLottie matches the intrinsic aspect
  ///    ratio of the Lottie animation.
  ///  - The RenderLottie's dimension are maximal subject to being smaller than
  ///    the intrinsic size of the composition.
  Size _sizeForConstraints(BoxConstraints constraints) {
    // Folds the given |width| and |height| into |constraints| so they can all
    // be treated uniformly.
    constraints = BoxConstraints.tightFor(
      width: _width,
      height: _height,
    ).enforce(constraints);

    if (_drawable == null) {
      return constraints.smallest;
    }

    return constraints.constrainSizeAndAttemptToPreserveAspectRatio(_drawable!.size);
  }

  void _setRasterCacheHints(PaintingContext context) {
    if (isComplex) context.setIsComplexHint();
    if (willChange) context.setWillChangeHint();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(height >= 0.0);
    if (_width == null && _height == null) {
      return 0.0;
    }
    return _sizeForConstraints(BoxConstraints.tightForFinite(height: height)).width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(height >= 0.0);
    return _sizeForConstraints(BoxConstraints.tightForFinite(height: height)).width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(width >= 0.0);
    if (_width == null && _height == null) {
      return 0.0;
    }
    return _sizeForConstraints(BoxConstraints.tightForFinite(width: width)).height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(width >= 0.0);
    return _sizeForConstraints(BoxConstraints.tightForFinite(width: width)).height;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _sizeForConstraints(constraints);
  }

  @override
  void performLayout() {
    size = _sizeForConstraints(constraints);
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    animation.addListener(_updateProgress);
    _updateProgress();
  }

  @override
  void detach() {
    animation.removeListener(_updateProgress);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_drawable == null) return;

    _setRasterCacheHints(context);
    _drawable!.draw(
      context.canvas,
      offset & size,
      fit: _fit,
      alignment: _alignment.resolve(TextDirection.ltr),
      scale: scale,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LottieComposition>('composition', composition));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: null));
  }
}
