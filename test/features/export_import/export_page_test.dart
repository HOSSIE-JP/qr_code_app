import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/database/app_database.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/data/repositories/export_repository.dart';
import 'package:qr_code_app/data/repositories/qr_repository.dart';
import 'package:qr_code_app/data/repositories/tag_repository.dart';
import 'package:qr_code_app/features/export_import/export_page.dart';
import 'package:qr_code_app/providers/providers.dart';

class _FakeCancelableExportRepository extends ExportRepository {
  _FakeCancelableExportRepository(this.db)
    : super(QrRepository(db), TagRepository(db));

  final AppDatabase db;

  @override
  Future<String> exportAsJson({
    List<String>? entryIds,
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    const total = 10;
    for (var index = 1; index <= total; index++) {
      cancellationToken?.throwIfCancellationRequested();
      onProgress?.call(
        ImportExportProgress(
          phase: ImportExportProcessPhase.processingEntries,
          processed: index,
          total: total,
          message: 'テスト進捗 $index/$total',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return '/tmp/fake.qrjson';
  }

  @override
  Future<String> exportAsZip({
    List<String>? entryIds,
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    final file = File('${Directory.systemTemp.path}/test_export.qrdb');
    await file.writeAsBytes(const [1, 2, 3, 4], flush: true);
    return file.path;
  }
}

void main() {
  late AppDatabase db;
  late _FakeCancelableExportRepository fakeRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeRepository = _FakeCancelableExportRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  QrEntryModel createEntry({
    required String id,
    required String name,
    String? categoryId,
    List<TagModel> tags = const [],
  }) {
    final data = Uint8List.fromList(name.codeUnits);
    return QrEntryModel(
      id: id,
      databaseId: 'default',
      categoryId: categoryId,
      name: name,
      description: '$name の説明',
      originalData: data,
      dataSize: data.length,
      chunkCount: 1,
      isTextMode: true,
      tags: tags,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  Widget buildTarget({
    required List<QrEntryModel> entries,
    required List<TagModel> tags,
    required List<CategoryModel> categories,
  }) {
    return ProviderScope(
      overrides: [
        qrEntriesProvider.overrideWith((ref) => Stream.value(entries)),
        allTagsProvider.overrideWith((ref) => Stream.value(tags)),
        allCategoriesProvider.overrideWith((ref) => Stream.value(categories)),
        exportRepositoryProvider.overrideWith((ref) => fakeRepository),
      ],
      child: const MaterialApp(home: ExportPage()),
    );
  }

  testWidgets('タグとカテゴリ条件でエクスポート対象をフィルタできる', (tester) async {
    const tagA = TagModel(id: 'tag-a', databaseId: 'default', name: '仕事');
    const tagB = TagModel(id: 'tag-b', databaseId: 'default', name: '個人');
    const categoryA = CategoryModel(
      id: 'cat-a',
      databaseId: 'default',
      name: 'カテゴリA',
      sortOrder: 0,
    );

    final entries = [
      createEntry(id: '1', name: '会議メモ', categoryId: 'cat-a', tags: [tagA]),
      createEntry(id: '2', name: '旅行計画', tags: [tagB]),
    ];

    await tester.pumpWidget(
      buildTarget(
        entries: entries,
        tags: [tagA, tagB],
        categories: [categoryA],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('会議メモ'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('カテゴリA').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('仕事'));
    await tester.pumpAndSettle();

    expect(find.text('会議メモ'), findsOneWidget);
    expect(find.text('旅行計画'), findsNothing);
  });

  testWidgets('エクスポート中は進捗オーバーレイを表示しキャンセルできる', (tester) async {
    final entry = createEntry(id: '1', name: '進捗確認');

    await tester.pumpWidget(
      buildTarget(entries: [entry], tags: const [], categories: const []),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('JSON'));
    await tester.pump();

    expect(find.text('エクスポート処理中'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('エクスポート処理中'), findsNothing);
    expect(find.text('エクスポートをキャンセルしました'), findsOneWidget);
  });

  testWidgets('OneDrive保存ボタンを表示する', (tester) async {
    final entry = createEntry(id: '1', name: 'OneDrive確認');

    await tester.pumpWidget(
      buildTarget(entries: [entry], tags: const [], categories: const []),
    );
    await tester.pumpAndSettle();

    expect(find.text('OneDriveへ保存'), findsOneWidget);
  });
}
