import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

class AssetLottie extends LottieProvider {
  AssetLottie(
    this.assetName, {
    this.bundle,
    this.package,
    LottieImageProviderFactory? imageProviderFactory,
  }) : super(imageProviderFactory: imageProviderFactory);

  final String assetName;
  final AssetBundle? bundle;
  final String? package;

  String get keyName => package == null ? assetName : 'packages/$package/$assetName';

  @override
  Future<LottieComposition> load() async {
    var cacheKey = 'asset-$keyName-$bundle';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      final chosenBundle = bundle ?? rootBundle;
      final data = await chosenBundle.load(keyName);
      final composition = await LottieComposition.fromByteData(data,
          name: p.url.basenameWithoutExtension(keyName), imageProviderFactory: imageProviderFactory);

      for (final image in composition.images.values) {
        image.loadedImage ??= await _loadImage(composition, image);
      }

      return composition;
    });
  }

  Future<ui.Image?> _loadImage(LottieComposition composition, LottieImageAsset lottieImage) {
    var imageProvider = getImageProvider(lottieImage);

    if (imageProvider == null) {
      var imageAssetPath = p.url.join(p.dirname(assetName), lottieImage.dirName, lottieImage.fileName);
      imageProvider = AssetImage(imageAssetPath, bundle: bundle, package: package);
    }

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AssetLottie && other.keyName == keyName && other.bundle == bundle;
  }

  @override
  int get hashCode => hashValues(keyName, bundle);

  @override
  String toString() => '$runtimeType(bundle: $bundle, name: "$keyName")';
}
