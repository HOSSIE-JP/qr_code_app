import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/features/viewer/qr_viewer_page.dart';
import 'package:qr_code_app/providers/providers.dart';

void main() {
  QrEntryModel createEntry() {
    final bytes = Uint8List.fromList('viewer-test'.codeUnits);
    return QrEntryModel(
      id: 'entry-1',
      databaseId: 'default',
      name: 'Viewer テスト',
      originalData: bytes,
      dataSize: bytes.length,
      chunkCount: 1,
      isTextMode: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  testWidgets('QR表示画面でサイズ変更してもグローバル初期サイズは更新しない', (tester) async {
    final container = ProviderContainer(
      overrides: [
        qrEntryByIdProvider(
          'entry-1',
        ).overrideWith((ref) => Future.value(createEntry())),
      ],
    );
    addTearDown(container.dispose);

    container.read(qrViewerDefaultSizeProvider.notifier).setSize(260);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: QrViewerPage(entryId: 'entry-1')),
      ),
    );
    await tester.pumpAndSettle();

    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);

    await tester.drag(slider, const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(container.read(qrViewerDefaultSizeProvider), 260);
  });
}
