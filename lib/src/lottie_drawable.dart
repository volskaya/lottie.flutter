import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

import 'composition.dart';
import 'frame_rate.dart';
import 'lottie_delegates.dart';
import 'model/key_path.dart';
import 'model/layer/composition_layer.dart';
import 'parser/layer_parser.dart';
import 'utils.dart';
import 'value_delegate.dart';

class LottieDrawable {
  LottieDrawable(
    this.composition, {
    this.enableMergePaths = false,
    this.antiAliasingSuggested = true,
    LottieDelegates? delegates,
  }) : size = Size(composition.bounds.width.toDouble(), composition.bounds.height.toDouble()) {
    this.delegates = delegates; // Make sure to call the `delegates` setter.
    _compositionLayer = CompositionLayer(this, LayerParser.parse(composition), composition.layers, composition);
  }

  final LottieComposition composition;
  final Size size;
  final bool enableMergePaths;
  late CompositionLayer _compositionLayer;

  final _matrix = Matrix4.identity();

  LottieDelegates? _delegates;
  bool _isDirty = true;
  bool antiAliasingSuggested = true;

  CompositionLayer get compositionLayer => _compositionLayer;

  /// Sets whether to apply opacity to the each layer instead of shape.
  ///
  /// Opacity is normally applied directly to a shape. In cases where translucent
  /// shapes overlap, applying opacity to a layer will be more accurate at the
  /// expense of performance.
  ///
  /// The default value is false.
  ///
  /// Note: This process is very expensive. The performance impact will be reduced
  /// when hardware acceleration is enabled.
  bool isApplyingOpacityToLayersEnabled = false;

  void invalidateSelf() {
    _isDirty = true;
  }

  double get progress => _progress ?? 0.0;
  double? _progress;
  bool setProgress(double value) {
    if (value != _progress) {
      _isDirty = false;
      _progress = value;
      _compositionLayer.setProgress(value);
      return _isDirty;
    } else {
      return false;
    }
  }

  LottieDelegates? get delegates => _delegates;
  set delegates(LottieDelegates? delegates) {
    if (_delegates != delegates) {
      _delegates = delegates;
      _updateValueDelegates(delegates?.values);
    }
  }

  bool get useTextGlyphs {
    return delegates?.text == null && composition.characters.isNotEmpty;
  }

  ui.Image? getImageAsset(String? ref) {
    var imageAsset = composition.images[ref];
    if (imageAsset != null) {
      var imageDelegate = delegates?.image;
      ui.Image? image;
      if (imageDelegate != null) {
        image = imageDelegate(composition, imageAsset);
      }

      return image ?? imageAsset.loadedImage;
    } else {
      return null;
    }
  }

  TextStyle getTextStyle(String font, String style) {
    return (_delegates?.textStyle ?? defaultTextStyleDelegate)(LottieFontStyle(fontFamily: font, style: style));
  }

  List<ValueDelegate> _valueDelegates = <ValueDelegate>[];
  void _updateValueDelegates(List<ValueDelegate>? newDelegates) {
    if (identical(_valueDelegates, newDelegates)) return;

    newDelegates ??= const <ValueDelegate>[];
    final delegates = <ValueDelegate>[];

    for (var newDelegate in newDelegates) {
      var existingDelegate = _valueDelegates.firstWhereOrNull((f) => f.isSameProperty(newDelegate));
      if (existingDelegate != null) {
        var resolved = internalResolved(existingDelegate);
        resolved.updateDelegate(newDelegate);
        delegates.add(existingDelegate);
      } else {
        var keyPaths = _resolveKeyPath(KeyPath(newDelegate.keyPath));
        var resolvedValueDelegate = internalResolve(newDelegate, keyPaths);
        resolvedValueDelegate.addValueCallback(this);
        delegates.add(newDelegate);
      }
    }
    for (var oldDelegate in _valueDelegates) {
      if (delegates.every((c) => !c.isSameProperty(oldDelegate))) {
        var resolved = internalResolved(oldDelegate);
        resolved.clear();
      }
    }
    _valueDelegates = delegates;
  }

  /// Takes a {@link KeyPath}, potentially with wildcards or globstars and resolve it to a list of
  /// zero or more actual {@link KeyPath Keypaths} that exist in the current animation.
  /// <p>
  /// If you want to set value callbacks for any of these values, it is recommend to use the
  /// returned {@link KeyPath} objects because they will be internally resolved to their content
  /// and won't trigger a tree walk of the animation contents when applied.
  List<KeyPath> _resolveKeyPath(KeyPath keyPath) {
    var keyPaths = <KeyPath>[];
    _compositionLayer.resolveKeyPath(keyPath, 0, keyPaths, KeyPath([]));
    return keyPaths;
  }

  void draw(
    ui.Canvas canvas,
    ui.Rect rect, {
    required BoxFit fit,
    required Alignment alignment,
  }) {
    if (rect.isEmpty) return;

    final canvasSize = rect.size;

    final BoxFit effectiveFit;
    switch (fit) {
      case BoxFit.scaleDown: // I haven't implement logic for this.
      case BoxFit.contain: // Couldn't get contain to work properly, but this fallback gives the correct behavior.
        effectiveFit = canvasSize.width > canvasSize.height ? BoxFit.fitHeight : BoxFit.fitWidth;
        break;
      case BoxFit.none:
      case BoxFit.cover: // Falling back to fitHeight / fitWidth gives the correct behavior.
        effectiveFit = canvasSize.width < canvasSize.height ? BoxFit.fitHeight : BoxFit.fitWidth;
        break;
      case BoxFit.fill:
      case BoxFit.fitWidth:
      case BoxFit.fitHeight:
        effectiveFit = fit;
        break;
    }

    final sizes = applyBoxFit(effectiveFit, size, canvasSize);
    final translation = alignment.alongSize(sizes.destination);
    final scaleX = sizes.destination.width / size.width;
    final scaleY = sizes.destination.height / size.height;

    // canvas.save();
    _matrix.setIdentity();

    switch (effectiveFit) {
      case BoxFit.fill:
        _matrix
          ..translate(
            -(size.width / 2.0 * scaleX) + translation.dx,
            -(size.height / 2.0 * scaleY) + translation.dy,
          )
          ..scale(scaleX, scaleY);
        break;
      case BoxFit.fitWidth:
        _matrix
          ..translate(
            -(size.width / 2.0 * scaleX) + translation.dx,
            -(size.height / 2.0 * scaleX) + translation.dy,
          )
          ..scale(scaleX);
        break;
      case BoxFit.fitHeight:
        _matrix
          ..translate(
            -(size.width / 2.0 * scaleY) + translation.dx,
            -(size.height / 2.0 * scaleY) + translation.dy,
          )
          ..scale(scaleY);
        break;
      case BoxFit.none:
      case BoxFit.cover:
      case BoxFit.scaleDown:
      case BoxFit.contain:
        throw UnsupportedError('effectiveFit should not have been $effectiveFit at this part of the code');
    }

    _compositionLayer.draw(canvas, rect.size, _matrix, parentAlpha: 255);
    // canvas.restore();
  }
}

class LottieFontStyle {
  const LottieFontStyle({
    required this.fontFamily,
    required this.style,
  });

  final String fontFamily;
  final String style;
}
