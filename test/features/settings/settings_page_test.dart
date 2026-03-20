import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/features/settings/settings_page.dart';
import 'package:qr_code_app/providers/providers.dart';

void main() {
  testWidgets('設定画面でカテゴリ/DB追加ダイアログを開閉しても例外が出ない', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDatabaseIdProvider.overrideWith(() => CurrentDatabaseId()),
          allDatabasesProvider.overrideWith(
            (ref) => Stream.value([
              QrDatabaseModel(
                id: 'default',
                name: 'デフォルト',
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ]),
          ),
          allCategoriesProvider.overrideWith((ref) => Stream.value(const [])),
          allTagsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    final addCategoryTile = find.widgetWithText(ListTile, '新しいカテゴリを作成');
    await tester.scrollUntilVisible(addCategoryTile, 200);
    await tester.tap(addCategoryTile);
    await tester.pumpAndSettle();
    expect(find.text('新しいカテゴリ'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    final addDatabaseTile = find.widgetWithText(ListTile, '新しいデータベースを作成');
    await tester.scrollUntilVisible(addDatabaseTile, 200);
    await tester.tap(addDatabaseTile);
    await tester.pumpAndSettle();
    expect(find.text('新しいデータベース'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('設定画面の高度なQR生成設定を展開できる', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDatabaseIdProvider.overrideWith(() => CurrentDatabaseId()),
          allDatabasesProvider.overrideWith(
            (ref) => Stream.value([
              QrDatabaseModel(
                id: 'default',
                name: 'デフォルト',
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ]),
          ),
          allCategoriesProvider.overrideWith((ref) => Stream.value(const [])),
          allTagsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('高度な設定（QR生成）'));
    await tester.pumpAndSettle();

    expect(find.text('誤り訂正レベル'), findsOneWidget);
    expect(find.text('ギャップレス描画'), findsOneWidget);
    expect(find.text('余白'), findsOneWidget);
  });
}
