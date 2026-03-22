import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/database/app_database.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/data/repositories/qr_repository.dart';
import 'package:qr_code_app/features/search/search_page.dart';
import 'package:qr_code_app/providers/providers.dart';

class _SpyQrRepository extends QrRepository {
  _SpyQrRepository(super.db, this._entriesById);

  final Map<String, QrEntryModel> _entriesById;
  int getEntryByIdCallCount = 0;

  @override
  Future<QrEntryModel?> getEntryById(String id) async {
    getEntryByIdCallCount += 1;
    return _entriesById[id];
  }
}

void main() {
  group('SearchPage 段階読込', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    QrEntryModel createEntry(int index) {
      final bytes = Uint8List.fromList(<int>[index, index + 1, index + 2]);
      return QrEntryModel(
        id: 'entry-$index',
        databaseId: 'default',
        name: '検索$index',
        description: '説明$index',
        originalData: bytes,
        dataSize: bytes.length,
        chunkCount: 1,
        isTextMode: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
    }

    testWidgets('初期表示で可視範囲の詳細のみ段階的に読込む', (tester) async {
      final entries = List<QrEntryModel>.generate(30, createEntry);
      final entriesById = <String, QrEntryModel>{
        for (final entry in entries) entry.id: entry,
      };
      final repository = _SpyQrRepository(db, entriesById);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDatabaseIdProvider.overrideWith(() => CurrentDatabaseId()),
            qrRepositoryProvider.overrideWithValue(repository),
            searchResultsProvider.overrideWith((ref) => Future.value(entries)),
            allTagsProvider.overrideWith(
              (ref) => Stream.value(const <TagModel>[]),
            ),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 180));

      expect(repository.getEntryByIdCallCount, greaterThan(0));
      expect(repository.getEntryByIdCallCount, lessThan(entries.length));
    });
  });
}
