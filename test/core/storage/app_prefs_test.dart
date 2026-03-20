import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/core/storage/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppPrefs', () {
    test('初期化後にデフォルト値を取得できる', () async {
      SharedPreferences.setMockInitialValues({});
      await AppPrefs.init();

      expect(AppPrefs.homeGridView, isTrue);
      expect(AppPrefs.qrViewerDefaultSize, 300);
      expect(AppPrefs.qrGenerationErrorLevel, 'medium');
      expect(AppPrefs.qrGenerationGapless, isFalse);
      expect(AppPrefs.qrGenerationPadding, 16);
      expect(AppPrefs.currentDatabaseId, isNull);
    });

    test('保存した設定を再取得できる', () async {
      SharedPreferences.setMockInitialValues({});
      await AppPrefs.init();

      await AppPrefs.setCurrentDatabaseId('db-test');
      await AppPrefs.setSortField('name');
      await AppPrefs.setSortAscending(true);
      await AppPrefs.setHomeGridView(false);
      await AppPrefs.setQrViewerDefaultSize(420);
      await AppPrefs.setQrGenerationErrorLevel('high');
      await AppPrefs.setQrGenerationGapless(true);
      await AppPrefs.setQrGenerationPadding(10);

      expect(AppPrefs.currentDatabaseId, 'db-test');
      expect(AppPrefs.sortField, 'name');
      expect(AppPrefs.sortAscending, isTrue);
      expect(AppPrefs.homeGridView, isFalse);
      expect(AppPrefs.qrViewerDefaultSize, 420);
      expect(AppPrefs.qrGenerationErrorLevel, 'high');
      expect(AppPrefs.qrGenerationGapless, isTrue);
      expect(AppPrefs.qrGenerationPadding, 10);
    });
  });
}
