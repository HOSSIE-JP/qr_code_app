import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:db_editor/src/editor_state.dart';
import 'package:db_editor/src/io/editor_file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_shared/qr_shared.dart';

void main() {
  group('EditorFileService', () {
    test('qrjson を保存して再読み込みできる', () async {
      final dir = await Directory.systemTemp.createTemp(
        'db_editor_qrjson_test',
      );
      addTearDown(() => dir.delete(recursive: true));

      final source = _sampleDocument();
      final filePath = '${dir.path}/data.qrjson';

      await EditorFileService.saveToPath(filePath, source);
      final loaded = await EditorFileService.loadFromPath(filePath);

      expect(loaded.entries.length, 1);
      expect(loaded.tags.length, 1);
      expect(loaded.categories.length, 1);
      expect(loaded.entries.first.name, source.entries.first.name);
      expect(
        loaded.entries.first.originalData,
        source.entries.first.originalData,
      );
      expect(loaded.entries.first.tags.map((tag) => tag.id).toList(), [
        'tag-1',
      ]);
    });

    test('qrdb を保存して再読み込みできる', () async {
      final dir = await Directory.systemTemp.createTemp('db_editor_qrdb_test');
      addTearDown(() => dir.delete(recursive: true));

      final source = _sampleDocument();
      final filePath = '${dir.path}/data.qrdb';

      await EditorFileService.saveToPath(filePath, source);
      final loaded = await EditorFileService.loadFromPath(filePath);

      expect(loaded.entries.length, 1);
      expect(loaded.tags.single.name, 'tag-name');
      expect(loaded.categories.single.name, 'category-name');
      expect(loaded.entries.single.thumbnail, isNotNull);
      expect(
        loaded.entries.single.originalData,
        source.entries.single.originalData,
      );
    });

    test('yaml 形式で相対パス資産を出力できる', () async {
      final dir = await Directory.systemTemp.createTemp('db_editor_yaml_test');
      addTearDown(() => dir.delete(recursive: true));

      final source = _sampleDocument();
      final filePath = '${dir.path}/data.yaml';

      await EditorFileService.saveToPath(filePath, source);
      final content = await File(filePath).readAsString();
      final loaded = await EditorFileService.loadFromPath(filePath);

      expect(content.contains('dataFilePath:'), isTrue);
      expect(File('${dir.path}/data/entry-1.bin').existsSync(), isTrue);
      expect(File('${dir.path}/thumbnails/entry-1.png').existsSync(), isTrue);
      expect(
        loaded.entries.single.originalData,
        source.entries.single.originalData,
      );
    });

    test('bytes から qrdb を読み込める', () async {
      final dir = await Directory.systemTemp.createTemp('db_editor_qrdb_bytes');
      addTearDown(() => dir.delete(recursive: true));

      final source = _sampleDocument();
      final filePath = '${dir.path}/data.qrdb';
      await EditorFileService.saveToPath(filePath, source);

      final bytes = await File(filePath).readAsBytes();
      final loaded = await EditorFileService.loadFromBytes(
        fileName: 'data.qrdb',
        bytes: bytes,
      );

      expect(loaded.entries, isNotEmpty);
      expect(loaded.entries.single.name, source.entries.single.name);
      expect(
        loaded.entries.single.originalData,
        source.entries.single.originalData,
      );
    });

    test('bytes 出力で qrdb を生成できる', () async {
      final source = _sampleDocument();
      final bytes = await EditorFileService.exportAsBytes(
        extension: '.qrdb',
        document: source,
      );

      expect(bytes, isNotEmpty);
      final loaded = await EditorFileService.loadFromBytes(
        fileName: 'exported.qrdb',
        bytes: bytes,
      );

      expect(loaded.entries.single.name, source.entries.single.name);
      expect(loaded.tags.single.name, source.tags.single.name);
    });
  });
}

EditorDocument _sampleDocument() {
  final now = DateTime.parse('2026-03-20T00:00:00.000Z');
  final tag = const TagModel(
    id: 'tag-1',
    databaseId: 'default',
    name: 'tag-name',
    color: 0xFF111111,
  );
  final category = const CategoryModel(
    id: 'category-1',
    databaseId: 'default',
    name: 'category-name',
    sortOrder: 0,
  );
  final data = Uint8List.fromList(utf8.encode('hello'));

  final entry = QrEntryModel(
    id: 'entry-1',
    databaseId: 'default',
    categoryId: category.id,
    name: 'entry-name',
    description: 'entry-description',
    originalData: data,
    dataSize: data.length,
    chunkCount: 1,
    isTextMode: true,
    isFavorite: true,
    thumbnail: Uint8List.fromList(<int>[1, 2, 3, 4]),
    createdAt: now,
    updatedAt: now,
    tags: <TagModel>[tag],
  );

  return EditorDocument(
    entries: <QrEntryModel>[entry],
    tags: <TagModel>[tag],
    categories: <CategoryModel>[category],
    version: 1,
    exportedAt: now,
    sourcePath: null,
    selectedEntryId: entry.id,
  );
}
