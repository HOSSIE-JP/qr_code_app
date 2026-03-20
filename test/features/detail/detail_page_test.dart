import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/features/detail/detail_page.dart';
import 'package:qr_code_app/providers/providers.dart';

void main() {
  QrEntryModel createEntry({
    required String id,
    required String dataText,
    Uint8List? thumbnail,
  }) {
    final bytes = Uint8List.fromList(dataText.codeUnits);
    return QrEntryModel(
      id: id,
      databaseId: 'default',
      name: 'エントリ$id',
      description: '説明',
      originalData: bytes,
      dataSize: bytes.length,
      chunkCount: 1,
      isTextMode: true,
      thumbnail: thumbnail,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  Widget buildTarget({
    required QrEntryModel entry,
    List<QrEntryModel> allEntries = const [],
    String? scopedEntryIds,
  }) {
    final entries = allEntries.isEmpty ? [entry] : allEntries;
    return ProviderScope(
      overrides: [
        currentDatabaseIdProvider.overrideWith(() => CurrentDatabaseId()),
        qrEntriesProvider.overrideWith((ref) => Stream.value(entries)),
        qrEntryByIdProvider(
          entry.id,
        ).overrideWith((ref) => Future.value(entry)),
      ],
      child: MaterialApp(
        home: DetailPage(entryId: entry.id, scopedEntryIds: scopedEntryIds),
      ),
    );
  }

  testWidgets('詳細画面下部に固定アクションが3つ表示される', (tester) async {
    final entry = createEntry(id: '1', dataText: 'https://example.com');

    await tester.pumpWidget(buildTarget(entry: entry));
    await tester.pumpAndSettle();

    expect(find.text('QRコードを表示'), findsOneWidget);
    expect(find.text('URLを開く'), findsOneWidget);
    expect(find.text('情報を編集'), findsOneWidget);
  });

  testWidgets('下部固定ボタンは左URL・中央QR表示・右編集の順で表示される', (tester) async {
    final entry = createEntry(id: '1', dataText: 'https://example.com');

    await tester.pumpWidget(buildTarget(entry: entry));
    await tester.pumpAndSettle();

    final urlX = tester.getCenter(find.text('URLを開く')).dx;
    final qrX = tester.getCenter(find.text('QRコードを表示')).dx;
    final editX = tester.getCenter(find.text('情報を編集')).dx;

    expect(urlX, lessThan(qrX));
    expect(qrX, lessThan(editX));
  });

  testWidgets('スワイプ対象が複数ある場合に左右の遷移ボタンが表示される', (tester) async {
    final entry = createEntry(id: '1', dataText: 'https://example.com');

    await tester.pumpWidget(
      buildTarget(
        entry: entry,
        allEntries: [
          entry,
          createEntry(id: '2', dataText: 'https://example.org'),
        ],
        scopedEntryIds: '1\n2',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('前のQRへ'), findsOneWidget);
    expect(find.byTooltip('次のQRへ'), findsOneWidget);
  });

  testWidgets('前後フローティングボタンは同じ高さに配置される', (tester) async {
    final entry = createEntry(id: '1', dataText: 'https://example.com');

    await tester.pumpWidget(
      buildTarget(
        entry: entry,
        allEntries: [
          entry,
          createEntry(id: '2', dataText: 'https://example.org'),
        ],
        scopedEntryIds: '1\n2',
      ),
    );
    await tester.pumpAndSettle();

    final prevButton = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == '前のQRへ',
      description: 'prev navigation icon button',
    );
    final nextButton = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == '次のQRへ',
      description: 'next navigation icon button',
    );
    expect(prevButton, findsOneWidget);
    expect(nextButton, findsOneWidget);
    final prevCenter = tester.getCenter(prevButton).dy;
    final nextCenter = tester.getCenter(nextButton).dy;

    expect((prevCenter - nextCenter).abs(), lessThan(1));
  });

  testWidgets('サムネイルタップで拡大プレビューへ遷移する', (tester) async {
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
    final entry = createEntry(
      id: '1',
      dataText: 'https://example.com',
      thumbnail: Uint8List.fromList(k1x1TransparentPng),
    );

    await tester.pumpWidget(buildTarget(entry: entry));
    await tester.pumpAndSettle();

    final thumbnail = tester.widget<GestureDetector>(
      find.byKey(const Key('detail-thumbnail')),
    );
    thumbnail.onTap?.call();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('thumbnail-preview-page')), findsOneWidget);
  });
}
