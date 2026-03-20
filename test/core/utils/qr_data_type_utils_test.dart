import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/core/utils/qr_data_type_utils.dart';

void main() {
  group('QrDataTypeUtils isLikelyText', () {
    test('UTF-8の日本語テキストをテキストとして判定する', () {
      final data = Uint8List.fromList(utf8.encode('こんにちは QR'));

      final result = QrDataTypeUtils.isLikelyText(data);

      expect(result, isTrue);
    });

    test('バイナリデータをバイナリとして判定する', () {
      final data = Uint8List.fromList(<int>[0, 255, 10, 128, 64, 0, 31]);

      final result = QrDataTypeUtils.isLikelyText(data);

      expect(result, isFalse);
    });
  });
}
