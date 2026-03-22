import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/database/app_database.dart';
import 'package:qr_code_app/data/repositories/export_repository.dart';
import 'package:qr_code_app/data/repositories/qr_repository.dart';
import 'package:qr_code_app/data/repositories/tag_repository.dart';

void main() {
  group('ExportRepository 大容量ZIP検証', () {
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

    test('生成した大量ZIPを新規取込と上書き取込で検証する', () async {
      const entryCount = 220;
      final zipBytes = _buildBulkZipBytes(entryCount: entryCount);

      final targetDatabase = await qrRepository.createDatabase(name: '大容量検証');
      var firstProgressEvents = 0;
      final firstStopwatch = Stopwatch()..start();

      final firstImportedCount = await exportRepository.importFromZip(
        zipBytes,
        databaseId: targetDatabase.id,
        onProgress: (_) {
          firstProgressEvents++;
        },
      );

      firstStopwatch.stop();

      final entries = await qrRepository.getAllEntries(
        databaseId: targetDatabase.id,
      );

      expect(firstImportedCount, greaterThan(0));
      expect(entries.length, firstImportedCount);

      var overwriteProgressEvents = 0;
      final overwriteStopwatch = Stopwatch()..start();
      final overwriteImportedCount = await exportRepository.importFromZip(
        zipBytes,
        databaseId: targetDatabase.id,
        onProgress: (_) {
          overwriteProgressEvents++;
        },
      );
      overwriteStopwatch.stop();

      final entriesAfterOverwrite = await qrRepository.getAllEntries(
        databaseId: targetDatabase.id,
      );

      expect(overwriteImportedCount, firstImportedCount);
      expect(entriesAfterOverwrite.length, firstImportedCount);

      // ignore: avoid_print
      print(
        'LARGE_DATA_IMPORT_RESULT firstImported=$firstImportedCount '
        'firstProgress=$firstProgressEvents '
        'firstElapsedMs=${firstStopwatch.elapsedMilliseconds} '
        'overwriteImported=$overwriteImportedCount '
        'overwriteProgress=$overwriteProgressEvents '
        'overwriteElapsedMs=${overwriteStopwatch.elapsedMilliseconds}',
      );
    });
  });
}

/// 回帰検証用の疑似大量 ZIP を生成する。
Uint8List _buildBulkZipBytes({required int entryCount}) {
  final archive = Archive();
  archive.addFile(
    ArchiveFile.bytes(
      'categories.json',
      utf8.encode(
        jsonEncode([
          {'id': 'category-1', 'name': 'カテゴリA', 'sortOrder': 0},
        ]),
      ),
    ),
  );
  archive.addFile(
    ArchiveFile.bytes(
      'tags.json',
      utf8.encode(
        jsonEncode([
          {'id': 'tag-1', 'name': 'タグA', 'color': 0xFF334455},
        ]),
      ),
    ),
  );

  final entries = <Map<String, dynamic>>[];
  for (var index = 0; index < entryCount; index++) {
    final id = 'bulk-entry-$index';
    entries.add({
      'id': id,
      'name': '一括取込$index',
      'description': '説明$index',
      'chunkCount': 1,
      'isTextMode': false,
      'isFavorite': index.isEven,
      'categoryId': 'category-1',
      'tags': ['tag-1'],
    });

    final payload = List<int>.generate(
      2048,
      (offset) => (index + offset) % 256,
    );
    archive.addFile(ArchiveFile.bytes('data/$id.bin', payload));
    if (index % 4 == 0) {
      archive.addFile(
        ArchiveFile.bytes('thumbnails/$id.png', <int>[1, 2, 3, 4]),
      );
    }
  }

  archive.addFile(
    ArchiveFile.bytes('entries.json', utf8.encode(jsonEncode(entries))),
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
