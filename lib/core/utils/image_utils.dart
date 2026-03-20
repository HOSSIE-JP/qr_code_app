import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../constants/app_constants.dart';

/// サムネイル画像のリサイズ・トリミングユーティリティ。
///
/// [image] パッケージを利用して、ピクセル単位で画像を扱う。
/// 出力は常に PNG 形式の [Uint8List]。
abstract final class ImageUtils {
  /// 画像バイト列を最大幅 [AppConstants.thumbnailMaxWidth] px にリサイズする。
  ///
  /// アスペクト比を維持し、幅が最大幅以下ならそのまま PNG エンコードする。
  static Uint8List resizeToThumbnail(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Unable to decode image data');
    }

    const maxWidth = AppConstants.thumbnailMaxWidth;
    if (decoded.width <= maxWidth) {
      return Uint8List.fromList(img.encodePng(decoded));
    }
    final resized = img.copyResize(decoded, width: maxWidth);
    return Uint8List.fromList(img.encodePng(resized));
  }

  /// 指定矩形でクロップした後、最大幅にリサイズする。
  static Uint8List cropAndResize(
    Uint8List imageBytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Unable to decode image data');
    }

    final cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    const maxWidth = AppConstants.thumbnailMaxWidth;
    if (cropped.width <= maxWidth) {
      return Uint8List.fromList(img.encodePng(cropped));
    }
    final resized = img.copyResize(cropped, width: maxWidth);
    return Uint8List.fromList(img.encodePng(resized));
  }
}
