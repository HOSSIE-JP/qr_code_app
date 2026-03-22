import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/features/detail/edit_page.dart';
import 'package:qr_code_app/providers/providers.dart';

void main() {
  QrEntryModel createEntry({
    required String id,
    bool hasQrData = true,
    bool isFavorite = false,
  }) {
    final data = hasQrData
        ? Uint8List.fromList(<int>[1, 2, 3, 4])
        : Uint8List(0);
    return QrEntryModel(
      id: id,
      databaseId: 'default',
      name: 'エントリ$id',
      description: '説明$id',
      originalData: data,
      dataSize: data.length,
      chunkCount: 1,
      isTextMode: true,
      isFavorite: isFavorite,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  Widget buildTarget({
    required QrEntryModel current,
    List<QrEntryModel>? allEntries,
  }) {
    final entries = allEntries ?? [current];
    return ProviderScope(
      overrides: [
        currentDatabaseIdProvider.overrideWith(() => CurrentDatabaseId()),
        qrEntriesProvider.overrideWith((ref) => Stream.value(entries)),
        allTagsProvider.overrideWith((ref) => Stream.value(const <TagModel>[])),
        allCategoriesProvider.overrideWith(
          (ref) => Stream.value(const <CategoryModel>[]),
        ),
        for (final entry in entries)
          qrEntryByIdProvider(
            entry.id,
          ).overrideWith((ref) => Future.value(entry)),
      ],
      child: MaterialApp(home: EditPage(entryId: current.id)),
    );
  }

  testWidgets('お気に入りはチェックボックスではなくサムネイル横ハートで操作する', (tester) async {
    final entry = createEntry(id: '1', isFavorite: true);

    await tester.pumpWidget(buildTarget(current: entry));
    await tester.pumpAndSettle();

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byTooltip('お気に入り解除'), findsOneWidget);
  });

  testWidgets('編集画面下部にQR更新ブロックと保存ボタンを固定表示する', (tester) async {
    final entry = createEntry(id: '1', hasQrData: true);

    await tester.pumpWidget(buildTarget(current: entry));
    await tester.pumpAndSettle();

    expect(find.text('QR 登録済み（4 B）'), findsOneWidget);
    expect(find.text('QR を読み取って変更'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '保存'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('編集すると保存ボタンが活性化される', (tester) async {
    final entry = createEntry(id: '1', hasQrData: true);

    await tester.pumpWidget(buildTarget(current: entry));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'エントリ1_編集済み');
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '保存'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('編集画面で左右スワイプと左右ボタンで前後エントリへ遷移できる', (tester) async {
    final first = createEntry(id: '1');
    final second = createEntry(id: '2', hasQrData: false);

    await tester.pumpWidget(
      buildTarget(current: first, allEntries: [first, second]),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('前のQRへ'), findsOneWidget);
    expect(find.byTooltip('次のQRへ'), findsOneWidget);

    expect(find.text('QR 登録済み（4 B）'), findsOneWidget);

    await tester.fling(
      find.byType(SingleChildScrollView).first,
      const Offset(-500, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.text('QR 未登録'), findsOneWidget);

    await tester.tap(find.byTooltip('前のQRへ'));
    await tester.pumpAndSettle();
    expect(find.text('QR 登録済み（4 B）'), findsOneWidget);
  });

  testWidgets('未保存のまま別エントリへ移動しようとすると警告ダイアログを表示する', (tester) async {
    final first = createEntry(id: '1', hasQrData: true);
    final second = createEntry(id: '2', hasQrData: false);

    await tester.pumpWidget(
      buildTarget(current: first, allEntries: [first, second]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'エントリ1_未保存変更');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('次のQRへ'));
    await tester.pumpAndSettle();

    expect(find.text('未保存の変更があります'), findsOneWidget);
    expect(find.text('破棄して移動'), findsOneWidget);

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('QR 登録済み（4 B）'), findsOneWidget);

    await tester.tap(find.byTooltip('次のQRへ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄して移動'));
    await tester.pumpAndSettle();

    expect(find.text('QR 未登録'), findsOneWidget);
  });
}
