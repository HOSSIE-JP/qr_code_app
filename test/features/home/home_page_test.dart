import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/features/home/home_page.dart';
import 'package:qr_code_app/providers/providers.dart';

void main() {
  QrEntryModel createEntry({
    required String id,
    required String name,
    bool isFavorite = false,
    String? categoryId,
  }) {
    return QrEntryModel(
      id: id,
      name: name,
      databaseId: 'default',
      categoryId: categoryId,
      originalData: Uint8List.fromList(const [1, 2, 3]),
      dataSize: 3,
      isFavorite: isFavorite,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  Widget buildTarget({
    required List<QrEntryModel> entries,
    required List<CategoryModel> categories,
  }) {
    return ProviderScope(
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
        qrEntriesProvider.overrideWith((ref) => Stream.value(entries)),
        allCategoriesProvider.overrideWith((ref) => Stream.value(categories)),
      ],
      child: const MaterialApp(home: HomePage()),
    );
  }

  testWidgets('ホーム画面に大きいQRスキャンボタンが表示される', (tester) async {
    await tester.pumpWidget(
      buildTarget(
        entries: [createEntry(id: '1', name: 'A')],
        categories: const [],
      ),
    );
    await tester.pumpAndSettle();

    final button = find.text('QRをスキャン');
    expect(button, findsOneWidget);

    final size = tester.getSize(
      find.ancestor(of: button, matching: find.byType(SizedBox)).first,
    );
    expect(size.height, greaterThanOrEqualTo(56));
  });

  testWidgets('カテゴリに属するエントリがカテゴリ見出しで表示される', (tester) async {
    const category = CategoryModel(
      id: 'cat-1',
      databaseId: 'default',
      name: '業務',
      sortOrder: 0,
    );

    await tester.pumpWidget(
      buildTarget(
        entries: [createEntry(id: '1', name: 'A', categoryId: 'cat-1')],
        categories: const [category],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('業務'), findsOneWidget);
  });

  testWidgets('ホーム画面下部に検索ボタンが表示される', (tester) async {
    await tester.pumpWidget(
      buildTarget(
        entries: [createEntry(id: '1', name: 'A')],
        categories: const [],
      ),
    );
    await tester.pumpAndSettle();

    final bottomSearchButton = find.byWidgetPredicate(
      (widget) =>
          widget is FloatingActionButton && widget.heroTag == 'search-bottom',
      description: 'bottom search floating action button',
    );
    expect(bottomSearchButton, findsOneWidget);
  });

  testWidgets('一括開閉ボタンでお気に入りとカテゴリをまとめて閉じられる', (tester) async {
    const category = CategoryModel(
      id: 'cat-1',
      databaseId: 'default',
      name: '業務',
      sortOrder: 0,
    );

    await tester.pumpWidget(
      buildTarget(
        entries: [
          createEntry(id: 'fav-1', name: 'お気に入り項目', isFavorite: true),
          createEntry(id: 'cat-1', name: 'カテゴリ項目', categoryId: 'cat-1'),
        ],
        categories: const [category],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('すべて閉じる'), findsOneWidget);
    expect(find.text('お気に入り項目'), findsOneWidget);
    expect(find.text('カテゴリ項目'), findsOneWidget);

    await tester.tap(find.byTooltip('すべて閉じる'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('すべて開く'), findsOneWidget);
    expect(find.text('お気に入り項目'), findsNothing);
    expect(find.text('カテゴリ項目'), findsNothing);
  });
}
