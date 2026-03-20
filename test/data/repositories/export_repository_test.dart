import 'dart:convert';

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

      final payload = <String, dynamic>{
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tags': [
          {'id': 'old-tag-1', 'name': '重要', 'color': 0xFF123456},
        ],
        'entries': [
          {
            'id': 'entry-1',
            'databaseId': 'default',
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
      expect(entries.single.tags, hasLength(1));
      expect(entries.single.tags.single.name, '重要');
      expect(entries.single.tags.single.databaseId, database.id);

      final tags = await tagRepository.getAllTags(databaseId: database.id);
      expect(tags, hasLength(1));
      expect(tags.single.name, '重要');
    });
  });
}
