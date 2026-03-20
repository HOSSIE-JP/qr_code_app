import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';

void main() {
  group('QrEntryModel hasQrData', () {
    QrEntryModel createEntry({required int dataSize}) {
      return QrEntryModel(
        id: 'test-id',
        name: 'テスト',
        originalData: Uint8List(dataSize),
        dataSize: dataSize,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    }

    test('dataSize が 0 のとき hasQrData は false を返す', () {
      final entry = createEntry(dataSize: 0);
      expect(entry.hasQrData, isFalse);
    });

    test('dataSize が 1 以上のとき hasQrData は true を返す', () {
      final entry = createEntry(dataSize: 10);
      expect(entry.hasQrData, isTrue);
    });

    test('デフォルトの databaseId は "default"', () {
      final entry = createEntry(dataSize: 0);
      expect(entry.databaseId, 'default');
    });

    test('databaseId を指定できる', () {
      final entry = QrEntryModel(
        id: 'test-id',
        databaseId: 'custom-db',
        name: 'テスト',
        originalData: Uint8List(0),
        dataSize: 0,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      expect(entry.databaseId, 'custom-db');
    });
  });

  group('QrDatabaseModel', () {
    test('生成と基本プロパティ', () {
      final now = DateTime.now();
      final db = QrDatabaseModel(
        id: 'db-1',
        name: 'テストDB',
        description: '説明',
        createdAt: now,
        updatedAt: now,
      );
      expect(db.id, 'db-1');
      expect(db.name, 'テストDB');
      expect(db.description, '説明');
    });

    test('description のデフォルト値は空文字', () {
      final now = DateTime.now();
      final db = QrDatabaseModel(
        id: 'db-2',
        name: 'テスト',
        createdAt: now,
        updatedAt: now,
      );
      expect(db.description, '');
    });
  });

  group('TagModel', () {
    test('デフォルトの databaseId は "default"', () {
      const tag = TagModel(id: 'tag-1', name: 'テストタグ');
      expect(tag.databaseId, 'default');
    });

    test('databaseId を指定できる', () {
      const tag = TagModel(id: 'tag-2', name: 'テストタグ', databaseId: 'custom-db');
      expect(tag.databaseId, 'custom-db');
    });
  });
}
