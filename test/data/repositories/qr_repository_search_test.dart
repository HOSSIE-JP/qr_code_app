import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/database/app_database.dart';
import 'package:qr_code_app/data/repositories/qr_repository.dart';

void main() {
  group('QrRepository search', () {
    late AppDatabase db;
    late QrRepository qrRepository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      qrRepository = QrRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('検索条件なしでも対象DBの全件を返す', () async {
      final database = await qrRepository.createDatabase(name: '検索DB');

      await qrRepository.createEntry(
        name: 'タグなしエントリ',
        description: '説明',
        data: Uint8List.fromList([1, 2, 3]),
        chunkCount: 1,
        databaseId: database.id,
      );
      await qrRepository.createEntry(
        name: '未登録エントリ',
        description: '説明',
        data: Uint8List(0),
        chunkCount: 0,
        databaseId: database.id,
      );

      final results = await qrRepository.search(
        textQuery: null,
        tagIds: const [],
        databaseId: database.id,
        hasQrData: null,
      );

      expect(results, hasLength(2));
      expect(results.map((entry) => entry.name).toSet(), {
        'タグなしエントリ',
        '未登録エントリ',
      });
    });
  });
}
