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
    bool hasQrData = true,
    Uint8List? thumbnail,
  }) {
    final data = hasQrData ? const <int>[1, 2, 3] : const <int>[];
    return QrEntryModel(
      id: id,
      name: name,
      databaseId: 'default',
      categoryId: categoryId,
      originalData: Uint8List.fromList(data),
      dataSize: data.length,
      isFavorite: isFavorite,
      thumbnail: thumbnail,
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
    await tester.pump();

    expect(find.byTooltip('すべて閉じる'), findsOneWidget);
    expect(find.text('お気に入り項目'), findsOneWidget);
    expect(find.text('カテゴリ項目'), findsOneWidget);

    await tester.tap(find.byTooltip('すべて閉じる'));
    await tester.pump();

    expect(find.byTooltip('すべて開く'), findsOneWidget);
    expect(find.text('お気に入り項目'), findsNothing);
    expect(find.text('カテゴリ項目'), findsNothing);
  });

  testWidgets('リスト表示ではQR未登録エントリのサムネイルをグレースケール表示する', (tester) async {
    const k1x1TransparentPng = <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ];

    await tester.pumpWidget(
      buildTarget(
        entries: [
          createEntry(
            id: '1',
            name: 'QRなし',
            hasQrData: false,
            thumbnail: Uint8List.fromList(k1x1TransparentPng),
          ),
        ],
        categories: const [],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('リスト表示'));
    await tester.pumpAndSettle();

    expect(find.byType(ColorFiltered), findsWidgets);
  });

  testWidgets('カテゴリ見出しは展開中カテゴリのみピン止めされる', (tester) async {
    const categoryA = CategoryModel(
      id: 'cat-a',
      databaseId: 'default',
      name: 'カテゴリA',
      sortOrder: 0,
    );
    const categoryB = CategoryModel(
      id: 'cat-b',
      databaseId: 'default',
      name: 'カテゴリB',
      sortOrder: 1,
    );

    await tester.pumpWidget(
      buildTarget(
        entries: [
          createEntry(id: '1', name: 'A1', categoryId: 'cat-a'),
          createEntry(id: '2', name: 'B1', categoryId: 'cat-b'),
        ],
        categories: const [categoryA, categoryB],
      ),
    );
    await tester.pumpAndSettle();

    var headers = tester.widgetList<SliverPersistentHeader>(
      find.byType(SliverPersistentHeader),
    );
    expect(headers.where((header) => header.pinned).length, 2);

    await tester.tap(find.textContaining('カテゴリB').first);
    await tester.pumpAndSettle();

    headers = tester.widgetList<SliverPersistentHeader>(
      find.byType(SliverPersistentHeader),
    );
    expect(headers.where((header) => header.pinned).length, 1);
  });
}
