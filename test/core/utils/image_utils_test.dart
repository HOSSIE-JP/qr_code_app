import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr_code_app/core/utils/image_utils.dart';

void main() {
  group('ImageUtils resizeToThumbnail', () {
    test('幅が 512 以下の画像はリサイズされない（アスペクト比維持）', () {
      // 200x100 の画像を作成
      final original = img.Image(width: 200, height: 100);
      final bytes = Uint8List.fromList(img.encodePng(original));

      final result = ImageUtils.resizeToThumbnail(bytes);
      final decoded = img.decodePng(result);

      expect(decoded, isNotNull);
      // 幅が 512 以下なのでそのまま
      expect(decoded!.width, 200);
      expect(decoded.height, 100);
    });

    test('幅が 512 超の画像は 512px にリサイズされアスペクト比が維持される', () {
      // 1024x512 の画像を作成
      final original = img.Image(width: 1024, height: 512);
      final bytes = Uint8List.fromList(img.encodePng(original));

      final result = ImageUtils.resizeToThumbnail(bytes);
      final decoded = img.decodePng(result);

      expect(decoded, isNotNull);
      expect(decoded!.width, 512);
      // アスペクト比 2:1 なので高さは 256
      expect(decoded.height, 256);
    });

    test('不正なデータで ArgumentError をスローする', () {
      expect(
        () => ImageUtils.resizeToThumbnail(Uint8List.fromList([0, 1, 2])),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ImageUtils cropAndResize', () {
    test('クロップ後に最大幅 512 でリサイズされる', () {
      // 1000x1000 の画像から 800x400 をクロップ
      final original = img.Image(width: 1000, height: 1000);
      final bytes = Uint8List.fromList(img.encodePng(original));

      final result = ImageUtils.cropAndResize(
        bytes,
        x: 0,
        y: 0,
        width: 800,
        height: 400,
      );
      final decoded = img.decodePng(result);

      expect(decoded, isNotNull);
      expect(decoded!.width, 512);
      // アスペクト比 2:1 なので高さは 256
      expect(decoded.height, 256);
    });

    test('クロップ後の幅が 512 以下ならリサイズしない', () {
      final original = img.Image(width: 600, height: 600);
      final bytes = Uint8List.fromList(img.encodePng(original));

      final result = ImageUtils.cropAndResize(
        bytes,
        x: 0,
        y: 0,
        width: 300,
        height: 300,
      );
      final decoded = img.decodePng(result);

      expect(decoded, isNotNull);
      expect(decoded!.width, 300);
      expect(decoded.height, 300);
    });
  });
}
