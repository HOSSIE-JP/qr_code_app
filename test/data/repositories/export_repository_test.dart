import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/database/app_database.dart';
import 'package:qr_code_app/data/repositories/export_repository.dart';
import 'package:qr_code_app/data/repositories/qr_repository.dart';
import 'package:qr_code_app/data/repositories/tag_repository.dart';

void main() {
  group('ExportRepository importFromJson', () {
    late AppDatabase db;
    late QrRepository qrRepository;
    late TagRepository tagRepository;
    late ExportRepository exportRepository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      qrRepository = QrRepository(db);
      tagRepository = TagRepository(db);
      exportRepository = ExportRepository(qrRepository, tagRepository);
    });

    tearDown(() async {
      await db.close();
    });

    test('日本語テキストとタグ情報を別DBへ正しくインポートできる', () async {
      final database = await qrRepository.createDatabase(name: '検証DB');
      final category = await qrRepository.createCategory(
        name: '業務',
        databaseId: database.id,
      );

      final payload = <String, dynamic>{
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tags': [
          {'id': 'old-tag-1', 'name': '重要', 'color': 0xFF123456},
        ],
        'categories': [
          {'id': 'old-category-1', 'name': category.name, 'sortOrder': 0},
        ],
        'entries': [
          {
            'id': 'entry-1',
            'databaseId': 'default',
            'categoryId': 'old-category-1',
            'name': 'タイトル日本語',
            'description': '説明メモ日本語',
            'originalData': utf8.encode('テキスト本文'),
            'dataSize': utf8.encode('テキスト本文').length,
            'chunkCount': 1,
            'isTextMode': true,
            'isFavorite': false,
            'thumbnail': null,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'tags': [
              {'id': 'old-tag-1', 'name': '重要', 'color': 0xFF123456},
            ],
          },
        ],
      };

      final importedCount = await exportRepository.importFromJson(
        jsonEncode(payload),
        databaseId: database.id,
      );

      expect(importedCount, 1);
      final entries = await qrRepository.getAllEntries(databaseId: database.id);
      expect(entries, hasLength(1));
      expect(entries.single.name, 'タイトル日本語');
      expect(entries.single.description, '説明メモ日本語');
      expect(entries.single.categoryId, category.id);
      expect(entries.single.tags, hasLength(1));
      expect(entries.single.tags.single.name, '重要');
      expect(entries.single.tags.single.databaseId, database.id);

      final tags = await tagRepository.getAllTags(databaseId: database.id);
      expect(tags, hasLength(1));
      expect(tags.single.name, '重要');
    });

    test('同名エントリを再インポートすると新規作成せず更新する', () async {
      final database = await qrRepository.createDatabase(name: '更新検証DB');
      final existing = await qrRepository.createEntry(
        name: '同名データ',
        description: '旧説明',
        data: Uint8List.fromList(utf8.encode('old')),
        chunkCount: 1,
        isTextMode: true,
        databaseId: database.id,
      );

      final payload = <String, dynamic>{
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'tags': [
          {'id': 'old-tag-1', 'name': '更新タグ', 'color': 0xFF654321},
        ],
        'categories': [
          {'id': 'old-category-1', 'name': '更新カテゴリ', 'sortOrder': 0},
        ],
        'entries': [
          {
            'id': 'entry-ignored',
            'databaseId': 'default',
            'categoryId': 'old-category-1',
            'name': '同名データ',
            'description': '新説明',
            'originalData': utf8.encode('new-data'),
            'dataSize': utf8.encode('new-data').length,
            'chunkCount': 1,
            'isTextMode': true,
            'isFavorite': true,
            'thumbnail': [1, 2, 3],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'tags': ['old-tag-1'],
          },
        ],
      };

      final importedCount = await exportRepository.importFromJson(
        jsonEncode(payload),
        databaseId: database.id,
      );

      expect(importedCount, 1);
      final entries = await qrRepository.getAllEntries(databaseId: database.id);
      expect(entries, hasLength(1));
      expect(entries.single.id, existing.id);
      expect(entries.single.description, '新説明');
      expect(utf8.decode(entries.single.originalData), 'new-data');
      expect(entries.single.isFavorite, isTrue);
      expect(entries.single.tags.map((tag) => tag.name), ['更新タグ']);

      final categories = await qrRepository.getCategoriesByDatabase(
        database.id,
      );
      expect(categories, hasLength(1));
      expect(entries.single.categoryId, categories.single.id);
    });

    test('ZIPインポートは他DBの同一ID既存データに影響されず取り込める', () async {
      final targetDatabase = await qrRepository.createDatabase(name: 'ZIP取込先');

      final existingDefault = await qrRepository.createEntry(
        name: '既存デフォルト',
        description: 'default',
        data: Uint8List.fromList([9, 9, 9]),
        chunkCount: 1,
        databaseId: 'default',
      );

      final archive = Archive();
      archive.addFile(
        ArchiveFile.bytes(
          'categories.json',
          utf8.encode(
            jsonEncode([
              {'id': 'old-category', 'name': 'ZIPカテゴリ', 'sortOrder': 0},
            ]),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'tags.json',
          utf8.encode(
            jsonEncode([
              {'id': 'old-tag', 'name': 'ZIPタグ', 'color': 0xFF010203},
            ]),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'entries.json',
          utf8.encode(
            jsonEncode([
              {
                'id': existingDefault.id,
                'name': 'ZIP取込エントリ',
                'description': 'zip説明',
                'chunkCount': 1,
                'isTextMode': false,
                'isFavorite': false,
                'categoryId': 'old-category',
                'tags': ['old-tag'],
              },
            ]),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes('data/${existingDefault.id}.bin', [1, 2, 3, 4]),
      );
      archive.addFile(
        ArchiveFile.bytes('thumbnails/${existingDefault.id}.png', [8, 8, 8]),
      );

      final zipBytes = ZipEncoder().encode(archive);
      final importedCount = await exportRepository.importFromZip(
        Uint8List.fromList(zipBytes),
        databaseId: targetDatabase.id,
      );

      expect(importedCount, 1);
      final targetEntries = await qrRepository.getAllEntries(
        databaseId: targetDatabase.id,
      );
      expect(targetEntries, hasLength(1));
      expect(targetEntries.single.name, 'ZIP取込エントリ');
      expect(targetEntries.single.thumbnail, isNotNull);
    });

    test('ZIPファイルパスからのインポートでも取り込める', () async {
      final targetDatabase = await qrRepository.createDatabase(
        name: 'ZIPパス取込先',
      );

      final archive = Archive();
      archive.addFile(
        ArchiveFile.bytes(
          'categories.json',
          utf8.encode(
            jsonEncode([
              {'id': 'old-category', 'name': 'ZIPカテゴリ', 'sortOrder': 0},
            ]),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'tags.json',
          utf8.encode(
            jsonEncode([
              {'id': 'old-tag', 'name': 'ZIPタグ', 'color': 0xFF010203},
            ]),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'entries.json',
          utf8.encode(
            jsonEncode([
              {
                'id': 'zip-path-entry-id',
                'name': 'ZIPパス取込エントリ',
                'description': 'zip説明',
                'chunkCount': 1,
                'isTextMode': false,
                'isFavorite': false,
                'categoryId': 'old-category',
                'tags': ['old-tag'],
              },
            ]),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes('data/zip-path-entry-id.bin', [1, 2, 3]),
      );

      final zipBytes = ZipEncoder().encode(archive);
      final file = File(
        '${Directory.systemTemp.path}/export_repository_zip_path_test.qrdb',
      );
      await file.writeAsBytes(zipBytes, flush: true);
      addTearDown(() async {
        if (await file.exists()) {
          await file.delete();
        }
      });

      final importedCount = await exportRepository.importFromZipFile(
        file.path,
        databaseId: targetDatabase.id,
      );

      expect(importedCount, 1);
      final targetEntries = await qrRepository.getAllEntries(
        databaseId: targetDatabase.id,
      );
      expect(targetEntries, hasLength(1));
      expect(targetEntries.single.name, 'ZIPパス取込エントリ');
    });

    test('JSONインポートで進捗通知を受け取れる', () async {
      final payload = <String, dynamic>{
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'tags': const [],
        'categories': const [],
        'entries': List.generate(
          5,
          (index) => {
            'id': 'progress-$index',
            'databaseId': 'default',
            'name': '進捗テスト$index',
            'description': '説明$index',
            'originalData': [1, 2, 3],
            'dataSize': 3,
            'chunkCount': 1,
            'isTextMode': false,
            'isFavorite': false,
            'thumbnail': null,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'tags': const <String>[],
          },
        ),
      };
      final progressLogs = <ImportExportProgress>[];
      await exportRepository.importFromJson(
        jsonEncode(payload),
        databaseId: 'default',
        onProgress: progressLogs.add,
      );

      expect(progressLogs, isNotEmpty);
      expect(
        progressLogs.any(
          (progress) =>
              progress.phase == ImportExportProcessPhase.processingEntries,
        ),
        isTrue,
      );
      expect(progressLogs.last.phase, ImportExportProcessPhase.completed);
    });

    test('JSONインポート処理はキャンセルできる', () async {
      final token = ImportExportCancellationToken();
      final payload = <String, dynamic>{
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'tags': const [],
        'categories': const [],
        'entries': List.generate(
          30,
          (index) => {
            'id': 'entry-$index',
            'databaseId': 'default',
            'name': 'キャンセル対象$index',
            'description': 'desc',
            'originalData': [1, 2, 3],
            'dataSize': 3,
            'chunkCount': 1,
            'isTextMode': false,
            'isFavorite': false,
            'thumbnail': null,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'tags': const <String>[],
          },
        ),
      };

      expect(
        () async => exportRepository.importFromJson(
          jsonEncode(payload),
          cancellationToken: token,
          onProgress: (progress) {
            if (progress.processed >= 3) {
              token.requestCancel();
            }
          },
        ),
        throwsA(isA<ImportExportCanceledException>()),
      );
    });

    test('ZIPインポート処理はキャンセルできる', () async {
      final targetDatabase = await qrRepository.createDatabase(
        name: 'ZIPキャンセル',
      );
      final token = ImportExportCancellationToken();

      final archive = Archive();
      archive.addFile(
        ArchiveFile.bytes(
          'categories.json',
          utf8.encode(
            jsonEncode([
              {'id': 'old-category', 'name': 'ZIPカテゴリ', 'sortOrder': 0},
            ]),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'tags.json',
          utf8.encode(
            jsonEncode([
              {'id': 'old-tag', 'name': 'ZIPタグ', 'color': 0xFF010203},
            ]),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'entries.json',
          utf8.encode(
            jsonEncode(
              List.generate(
                40,
                (index) => {
                  'id': 'zip-cancel-entry-$index',
                  'name': 'ZIPキャンセル$index',
                  'description': 'zip説明',
                  'chunkCount': 1,
                  'isTextMode': false,
                  'isFavorite': false,
                  'categoryId': 'old-category',
                  'tags': ['old-tag'],
                },
              ),
            ),
          ),
        ),
      );

      for (var index = 0; index < 40; index++) {
        archive.addFile(
          ArchiveFile.bytes('data/zip-cancel-entry-$index.bin', [1, 2, 3, 4]),
        );
      }

      final zipBytes = ZipEncoder().encode(archive);

      expect(
        () async => exportRepository.importFromZip(
          Uint8List.fromList(zipBytes),
          databaseId: targetDatabase.id,
          cancellationToken: token,
          onProgress: (progress) {
            if (progress.phase == ImportExportProcessPhase.processingEntries &&
                progress.processed >= 5) {
              token.requestCancel();
            }
          },
        ),
        throwsA(isA<ImportExportCanceledException>()),
      );
    });
  });
}
