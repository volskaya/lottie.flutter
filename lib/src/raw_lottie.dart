import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../lottie.dart';
import 'frame_rate.dart';
import 'lottie_drawable.dart';
import 'render_lottie.dart';

/// A widget that displays a [LottieDrawable] directly.
///
/// This widget is rarely used directly. Instead, consider using [Lottie] or [LottieAnimation].
class RawLottie extends LeafRenderObjectWidget {
  /// Creates a widget that displays a Lottie composition.
  const RawLottie({
    Key? key,
    required this.animation,
    this.composition,
    this.delegates,
    this.options = const LottieOptions(),
    this.frameRate = FrameRate.max,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.isComplex = false,
    this.willChange = false,
    this.scale = 1.0,
  }) : super(key: key);

  final bool isComplex;
  final bool willChange;

  /// The scaling to apply to the paint matrix.
  final double scale;

  /// The Lottie composition to display.
  final LottieComposition? composition;

  /// Allows to modify the Lottie animation at runtime
  final LottieDelegates? delegates;

  final LottieOptions options;

  /// The number of frames per second to render.
  /// Use `FrameRate.composition` to use the original frame rate of the Lottie composition (default)
  /// Use `FrameRate.max` to advance the animation progression at every frame.
  final FrameRate frameRate;

  /// If non-null, require the Lottie composition to have this width.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double? width;

  /// If non-null, require the Lottie composition to have this height.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double? height;

  /// How to inscribe the Lottie composition into the space allocated during layout.
  final BoxFit fit;

  /// How to align the composition within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
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

  final Animation<double> animation;

  @override
  RenderLottie createRenderObject(BuildContext context) {
    return RenderLottie(
      composition: composition,
      delegates: delegates,
      enableMergePaths: options.enableMergePaths,
      antiAliasingSuggested: options.antiAliasingSuggested,
      animation: animation,
      frameRate: frameRate,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      isComplex: isComplex,
      willChange: willChange,
      scale: scale,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLottie renderObject) {
    renderObject
      ..width = width
      ..height = height
      ..alignment = alignment
      ..fit = fit
      ..isComplex = isComplex
      ..willChange = willChange
      ..scale = scale
      ..animation = animation
      ..setComposition(
        composition,
        delegates: delegates,
        enableMergePaths: options.enableMergePaths,
      );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LottieComposition>('composition', composition));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(EnumProperty<double>('scale', scale, defaultValue: 1.0));
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: null));
  }
}
