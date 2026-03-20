import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_code_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme テーマ設定', () {
    test('ライトテーマが Material 3 の light brightness を持つ', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
    });

    test('ダークテーマが Material 3 の dark brightness を持つ', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });
  });
}
