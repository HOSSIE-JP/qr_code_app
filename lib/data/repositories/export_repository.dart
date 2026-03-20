import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/qr_entry_model.dart';
import 'qr_repository.dart';
import 'tag_repository.dart';

/// エントリとタグのエクスポート・インポートを行うリポジトリ。
///
/// ZIP 形式（バイナリデータを別ファイルに分離）と JSON 形式（全データを
/// 単一ファイルに埋め込み）の 2 つのフォーマットに対応する。
/// データベース ID を指定すると、そのデータベースに属するデータのみを対象にする。
class ExportRepository {
  ExportRepository(this._qrRepo, this._tagRepo);

  final QrRepository _qrRepo;
  final TagRepository _tagRepo;

  /// 選択された（または全）エントリを ZIP ファイルにエクスポートする。
  /// [databaseId] を指定すると対象 DB に属するエントリとタグのみを対象にする。
  /// 生成したファイルパスを返す。
  Future<String> exportAsZip({
    List<String>? entryIds,
    String? databaseId,
  }) async {
    final entries = entryIds != null
        ? await Future.wait(
            entryIds.map((id) => _qrRepo.getEntryById(id)),
          ).then((list) => list.whereType<QrEntryModel>().toList())
        : await _qrRepo.getAllEntries(databaseId: databaseId);

    final targetDatabaseId = databaseId ?? 'default';
    final tags = await _tagRepo.getAllTags(databaseId: targetDatabaseId);
    final categories = await _qrRepo.getCategoriesByDatabase(targetDatabaseId);

    final archive = Archive();

    // Add metadata JSON
    final metadata = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'entryCount': entries.length,
      'tagCount': tags.length,
      'categoryCount': categories.length,
    };
    archive.addFile(
      ArchiveFile.bytes('metadata.json', utf8.encode(jsonEncode(metadata))),
    );

    // Add tags JSON
    final tagsJson = tags.map((t) => t.toJson()).toList();
    archive.addFile(
      ArchiveFile.bytes('tags.json', utf8.encode(jsonEncode(tagsJson))),
    );

    // Add categories JSON
    final categoriesJson = categories.map((c) => c.toJson()).toList();
    archive.addFile(
      ArchiveFile.bytes(
        'categories.json',
        utf8.encode(jsonEncode(categoriesJson)),
      ),
    );

    // Add entries
    final entriesJson = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final entryMap = entry.toJson();
      // Remove binary data from JSON (stored separately)
      entryMap.remove('originalData');
      entryMap.remove('thumbnail');
      entriesJson.add(entryMap);

      // Store binary data as separate files
      archive.addFile(
        ArchiveFile.bytes('data/${entry.id}.bin', entry.originalData),
      );

      if (entry.thumbnail != null) {
        archive.addFile(
          ArchiveFile.bytes('thumbnails/${entry.id}.png', entry.thumbnail!),
        );
      }
    }

    archive.addFile(
      ArchiveFile.bytes('entries.json', utf8.encode(jsonEncode(entriesJson))),
    );

    final zipData = ZipEncoder().encode(archive);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/qr_export_$timestamp.qrdb';
    await File(filePath).writeAsBytes(zipData);

    return filePath;
  }

  /// 選択された（または全）エントリを JSON ファイルにエクスポートする。
  /// [databaseId] を指定すると対象 DB に属するデータのみを対象にする。
  Future<String> exportAsJson({
    List<String>? entryIds,
    String? databaseId,
  }) async {
    final entries = entryIds != null
        ? await Future.wait(
            entryIds.map((id) => _qrRepo.getEntryById(id)),
          ).then((list) => list.whereType<QrEntryModel>().toList())
        : await _qrRepo.getAllEntries(databaseId: databaseId);

    final targetDatabaseId = databaseId ?? 'default';
    final tags = await _tagRepo.getAllTags(databaseId: targetDatabaseId);
    final categories = await _qrRepo.getCategoriesByDatabase(targetDatabaseId);

    final exportData = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/qr_export_$timestamp.qrjson';
    await File(filePath).writeAsString(jsonEncode(exportData));

    return filePath;
  }

  /// ZIP ファイルからエントリをインポートする。
  /// [databaseId] を指定すると、インポート先のデータベースを明示する。
  /// インポート件数を返す。
  Future<int> importFromZip(Uint8List zipBytes, {String? databaseId}) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    var importedCount = 0;
    final targetDatabaseId = databaseId ?? 'default';

    // Read categories
    final categoryIdMap = <String, String>{};
    final categoriesFile = archive.findFile('categories.json');
    if (categoriesFile != null) {
      final categoriesJson =
          jsonDecode(utf8.decode(categoriesFile.content as List<int>)) as List;
      for (final categoryJson in categoriesJson) {
        final map = (categoryJson as Map).cast<String, dynamic>();
        final oldCategoryId = map['id'] as String?;
        final created = await _upsertCategory(
          name: map['name'] as String,
          databaseId: targetDatabaseId,
        );
        if (oldCategoryId != null && oldCategoryId.isNotEmpty) {
          categoryIdMap[oldCategoryId] = created.id;
        }
      }
    }

    // Read tags
    final tagIdMap = <String, String>{};
    final tagsFile = archive.findFile('tags.json');
    if (tagsFile != null) {
      final tagsJson =
          jsonDecode(utf8.decode(tagsFile.content as List<int>)) as List;
      for (final tagJson in tagsJson) {
        final map = (tagJson as Map).cast<String, dynamic>();
        final oldTagId = map['id'] as String?;
        final created = await _tagRepo.createTag(
          name: map['name'] as String,
          color: map['color'] as int?,
          databaseId: targetDatabaseId,
        );
        if (oldTagId != null && oldTagId.isNotEmpty) {
          tagIdMap[oldTagId] = created.id;
        }
      }
    }

    // Read entries
    final entriesFile = archive.findFile('entries.json');
    if (entriesFile == null) return 0;

    final entriesJson =
        jsonDecode(utf8.decode(entriesFile.content as List<int>)) as List;

    for (final entryJson in entriesJson) {
      final map = (entryJson as Map).cast<String, dynamic>();
      final id = map['id'] as String;

      final existing = await _qrRepo.getEntryByName(
        databaseId: targetDatabaseId,
        name: map['name'] as String,
      );

      // Get binary data
      final dataFile = archive.findFile('data/$id.bin');
      if (dataFile == null) continue;

      final thumbnailFile = archive.findFile('thumbnails/$id.png');

      final originalTagIds = _extractTagIds(map['tags']);
      final tagIds = originalTagIds
          .map((id) => tagIdMap[id] ?? id)
          .toList(growable: false);

      final resolvedCategoryId = _resolveCategoryId(
        rawCategoryId: map['categoryId'],
        categoryIdMap: categoryIdMap,
      );

      final importDescription = (map['description'] as String?) ?? '';
      final importData = Uint8List.fromList(dataFile.content as List<int>);
      final importThumbnail = thumbnailFile != null
          ? Uint8List.fromList(thumbnailFile.content as List<int>)
          : null;

      if (existing == null) {
        await _qrRepo.createEntry(
          name: map['name'] as String,
          description: importDescription,
          data: importData,
          chunkCount: (map['chunkCount'] as int?) ?? 1,
          isTextMode: (map['isTextMode'] as bool?) ?? false,
          isFavorite: (map['isFavorite'] as bool?) ?? false,
          thumbnail: importThumbnail,
          tagIds: tagIds,
          databaseId: targetDatabaseId,
          categoryId: resolvedCategoryId,
        );
      } else {
        await _qrRepo.overwriteEntryFromImport(
          id: existing.id,
          name: map['name'] as String,
          description: importDescription,
          data: importData,
          chunkCount: (map['chunkCount'] as int?) ?? 1,
          isTextMode: (map['isTextMode'] as bool?) ?? false,
          isFavorite: (map['isFavorite'] as bool?) ?? false,
          thumbnail: importThumbnail,
          categoryId: resolvedCategoryId,
          tagIds: tagIds,
        );
      }

      importedCount++;
    }

    return importedCount;
  }

  /// JSON 文字列からエントリをインポートする。
  /// [databaseId] を指定すると、インポート先のデータベースを明示する。
  /// インポート件数を返す。
  Future<int> importFromJson(String jsonString, {String? databaseId}) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    var importedCount = 0;
    final targetDatabaseId = databaseId ?? 'default';

    // Import categories
    final categoryIdMap = <String, String>{};
    final categoriesJson = data['categories'] as List? ?? [];
    for (final categoryJson in categoriesJson) {
      final map = (categoryJson as Map).cast<String, dynamic>();
      final oldCategoryId = map['id'] as String?;
      final created = await _upsertCategory(
        name: map['name'] as String,
        databaseId: targetDatabaseId,
      );
      if (oldCategoryId != null && oldCategoryId.isNotEmpty) {
        categoryIdMap[oldCategoryId] = created.id;
      }
    }

    // Import tags
    final tagIdMap = <String, String>{};
    final tagsJson = data['tags'] as List? ?? [];
    for (final tagJson in tagsJson) {
      final map = (tagJson as Map).cast<String, dynamic>();
      final oldTagId = map['id'] as String?;
      final created = await _tagRepo.createTag(
        name: tagJson['name'] as String,
        color: tagJson['color'] as int?,
        databaseId: targetDatabaseId,
      );
      if (oldTagId != null && oldTagId.isNotEmpty) {
        tagIdMap[oldTagId] = created.id;
      }
    }

    // Import entries
    final entriesJson = data['entries'] as List? ?? [];
    for (final entryJson in entriesJson) {
      final map = (entryJson as Map).cast<String, dynamic>();
      final existing = await _qrRepo.getEntryByName(
        databaseId: targetDatabaseId,
        name: map['name'] as String,
      );

      final originalData = map['originalData'] as List?;
      if (originalData == null) continue;

      final thumbnailData = map['thumbnail'] as List?;
      final originalTagIds = _extractTagIds(map['tags']);
      final tagIds = originalTagIds
          .map((id) => tagIdMap[id] ?? id)
          .toList(growable: false);

      final resolvedCategoryId = _resolveCategoryId(
        rawCategoryId: map['categoryId'],
        categoryIdMap: categoryIdMap,
      );

      final importDescription = (map['description'] as String?) ?? '';
      final importData = Uint8List.fromList(originalData.cast<int>());
      final importThumbnail = thumbnailData != null
          ? Uint8List.fromList(thumbnailData.cast<int>())
          : null;

      if (existing == null) {
        await _qrRepo.createEntry(
          name: map['name'] as String,
          description: importDescription,
          data: importData,
          chunkCount: (map['chunkCount'] as int?) ?? 1,
          isTextMode: (map['isTextMode'] as bool?) ?? false,
          isFavorite: (map['isFavorite'] as bool?) ?? false,
          thumbnail: importThumbnail,
          tagIds: tagIds,
          databaseId: targetDatabaseId,
          categoryId: resolvedCategoryId,
        );
      } else {
        await _qrRepo.overwriteEntryFromImport(
          id: existing.id,
          name: map['name'] as String,
          description: importDescription,
          data: importData,
          chunkCount: (map['chunkCount'] as int?) ?? 1,
          isTextMode: (map['isTextMode'] as bool?) ?? false,
          isFavorite: (map['isFavorite'] as bool?) ?? false,
          thumbnail: importThumbnail,
          categoryId: resolvedCategoryId,
          tagIds: tagIds,
        );
      }

      importedCount++;
    }

    return importedCount;
  }

  /// JSON 内の tags フィールドからタグID一覧を抽出する。
  ///
  /// 旧形式（[{id: ...}]) と新形式（['id1', 'id2']）の双方を受け付ける。
  List<String> _extractTagIds(dynamic rawTags) {
    if (rawTags is! List) {
      return const <String>[];
    }
    return rawTags
        .map<String?>((tag) {
          if (tag is String) return tag;
          if (tag is Map && tag['id'] is String) {
            return tag['id'] as String;
          }
          return null;
        })
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  /// カテゴリIDを旧ID→新IDマップで解決する。
  String? _resolveCategoryId({
    required dynamic rawCategoryId,
    required Map<String, String> categoryIdMap,
  }) {
    if (rawCategoryId is! String || rawCategoryId.isEmpty) {
      return null;
    }
    return categoryIdMap[rawCategoryId] ?? rawCategoryId;
  }

  /// カテゴリ名で重複を避けてカテゴリを取得または作成する。
  Future<CategoryModel> _upsertCategory({
    required String name,
    required String databaseId,
  }) async {
    final categories = await _qrRepo.getCategoriesByDatabase(databaseId);
    for (final category in categories) {
      if (category.name == name) {
        return category;
      }
    }
    return _qrRepo.createCategory(name: name, databaseId: databaseId);
  }
}
