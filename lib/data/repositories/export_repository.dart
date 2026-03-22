import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

import 'qr_repository.dart';
import 'tag_repository.dart';

/// Import/Export 処理の進捗通知コールバック。
typedef ImportExportProgressCallback =
    void Function(ImportExportProgress progress);

/// Import/Export の処理段階。
enum ImportExportProcessPhase {
  preparing,
  readingArchive,
  processingCategories,
  processingTags,
  processingEntries,
  writingFile,
  completed,
  cancelled,
}

/// Import/Export の進捗スナップショット。
class ImportExportProgress {
  const ImportExportProgress({
    required this.phase,
    required this.processed,
    required this.total,
    required this.message,
  });

  final ImportExportProcessPhase phase;
  final int processed;
  final int total;
  final String message;

  /// 進捗割合。総数不明時は null。
  double? get fraction {
    if (total <= 0) return null;
    return (processed / total).clamp(0, 1).toDouble();
  }
}

/// Import/Export のキャンセル要求を共有するトークン。
class ImportExportCancellationToken {
  bool _isCancellationRequested = false;

  bool get isCancellationRequested => _isCancellationRequested;

  void requestCancel() {
    _isCancellationRequested = true;
  }

  void throwIfCancellationRequested() {
    if (_isCancellationRequested) {
      throw const ImportExportCanceledException();
    }
  }
}

/// Import/Export 処理のキャンセル例外。
class ImportExportCanceledException implements Exception {
  const ImportExportCanceledException();

  @override
  String toString() => 'Import/Export 処理がキャンセルされました。';
}

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
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.preparing,
      processed: 0,
      total: 0,
      message: 'エクスポート準備中',
    );
    cancellationToken?.throwIfCancellationRequested();

    final allEntries = await _qrRepo.getAllEntries(databaseId: databaseId);
    final selectedIdSet = entryIds?.toSet();
    final entries = selectedIdSet == null
        ? allEntries
        : allEntries
              .where((entry) => selectedIdSet.contains(entry.id))
              .toList();

    final targetDatabaseId = databaseId ?? 'default';
    final tags = await _tagRepo.getAllTags(databaseId: targetDatabaseId);
    final categories = await _qrRepo.getCategoriesByDatabase(targetDatabaseId);
    cancellationToken?.throwIfCancellationRequested();

    final archive = Archive();
    final total = entries.length + 4;
    var processed = 0;

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
    processed++;
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.processingEntries,
      processed: processed,
      total: total,
      message: 'メタデータを作成中',
    );
    cancellationToken?.throwIfCancellationRequested();

    // Add tags JSON
    final tagsJson = tags.map((t) => t.toJson()).toList();
    archive.addFile(
      ArchiveFile.bytes('tags.json', utf8.encode(jsonEncode(tagsJson))),
    );
    processed++;
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.processingTags,
      processed: processed,
      total: total,
      message: 'タグ情報を作成中',
    );
    cancellationToken?.throwIfCancellationRequested();

    // Add categories JSON
    final categoriesJson = categories.map((c) => c.toJson()).toList();
    archive.addFile(
      ArchiveFile.bytes(
        'categories.json',
        utf8.encode(jsonEncode(categoriesJson)),
      ),
    );
    processed++;
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.processingCategories,
      processed: processed,
      total: total,
      message: 'カテゴリ情報を作成中',
    );
    cancellationToken?.throwIfCancellationRequested();

    // Add entries
    final entriesJson = <Map<String, dynamic>>[];
    for (var index = 0; index < entries.length; index++) {
      cancellationToken?.throwIfCancellationRequested();
      final entry = entries[index];
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

      _emitProgress(
        onProgress,
        phase: ImportExportProcessPhase.processingEntries,
        processed: processed + index + 1,
        total: total,
        message: 'エントリをエクスポート中 (${index + 1}/${entries.length})',
      );
    }

    archive.addFile(
      ArchiveFile.bytes('entries.json', utf8.encode(jsonEncode(entriesJson))),
    );
    processed += entries.length;
    cancellationToken?.throwIfCancellationRequested();

    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.writingFile,
      processed: processed,
      total: total,
      message: 'ZIPファイルを生成中',
    );
    final zipData = ZipEncoder().encode(archive);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/qr_export_$timestamp.qrdb';
    await File(filePath).writeAsBytes(zipData);

    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.completed,
      processed: total,
      total: total,
      message: 'エクスポート完了',
    );

    return filePath;
  }

  /// 選択された（または全）エントリを JSON ファイルにエクスポートする。
  /// [databaseId] を指定すると対象 DB に属するデータのみを対象にする。
  Future<String> exportAsJson({
    List<String>? entryIds,
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.preparing,
      processed: 0,
      total: 0,
      message: 'エクスポート準備中',
    );
    cancellationToken?.throwIfCancellationRequested();

    final allEntries = await _qrRepo.getAllEntries(databaseId: databaseId);
    final selectedIdSet = entryIds?.toSet();
    final entries = selectedIdSet == null
        ? allEntries
        : allEntries
              .where((entry) => selectedIdSet.contains(entry.id))
              .toList();

    final targetDatabaseId = databaseId ?? 'default';
    final tags = await _tagRepo.getAllTags(databaseId: targetDatabaseId);
    final categories = await _qrRepo.getCategoriesByDatabase(targetDatabaseId);
    cancellationToken?.throwIfCancellationRequested();
    final total = entries.length + 3;

    final exportData = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };

    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.processingEntries,
      processed: entries.length,
      total: total,
      message: 'JSONデータを組み立て中',
    );
    cancellationToken?.throwIfCancellationRequested();

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/qr_export_$timestamp.qrjson';
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.writingFile,
      processed: total - 1,
      total: total,
      message: 'JSONファイルを書き込み中',
    );
    await File(filePath).writeAsString(jsonEncode(exportData));

    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.completed,
      processed: total,
      total: total,
      message: 'エクスポート完了',
    );

    return filePath;
  }

  /// ZIP ファイルからエントリをインポートする。
  /// [databaseId] を指定すると、インポート先のデータベースを明示する。
  /// インポート件数を返す。
  Future<int> importFromZip(
    Uint8List zipBytes, {
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.readingArchive,
      processed: 0,
      total: 0,
      message: 'ZIPを展開中',
    );
    cancellationToken?.throwIfCancellationRequested();

    final archive = ZipDecoder().decodeBytes(
      zipBytes,
      callback: (_) {
        cancellationToken?.throwIfCancellationRequested();
      },
    );
    return _importFromArchive(
      archive,
      databaseId: databaseId,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  /// ZIP ファイルパスからエントリをインポートする。
  ///
  /// ローカルファイルをストリームで読み込むため、巨大な ZIP でも
  /// `readAsBytes()` よりメモリピークを抑えられる。
  Future<int> importFromZipFile(
    String zipFilePath, {
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.readingArchive,
      processed: 0,
      total: 0,
      message: 'ZIPを展開中',
    );
    cancellationToken?.throwIfCancellationRequested();

    final input = InputFileStream(zipFilePath);
    try {
      final archive = ZipDecoder().decodeStream(
        input,
        callback: (_) {
          cancellationToken?.throwIfCancellationRequested();
        },
      );
      return _importFromArchive(
        archive,
        databaseId: databaseId,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
    } finally {
      input.close();
    }
  }

  Future<int> _importFromArchive(
    Archive archive, {
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    return _qrRepo.runInTransaction(() async {
      var importedCount = 0;
      final targetDatabaseId = databaseId ?? 'default';
      final archiveFileByName = <String, ArchiveFile>{
        for (final file in archive.files) file.name: file,
      };
      final categoriesFile = archiveFileByName['categories.json'];
      final tagsFile = archiveFileByName['tags.json'];
      final entriesFile = archiveFileByName['entries.json'];

      final categoriesJson = categoriesFile != null
          ? jsonDecode(utf8.decode(categoriesFile.content as List<int>)) as List
          : const <dynamic>[];
      final tagsJson = tagsFile != null
          ? jsonDecode(utf8.decode(tagsFile.content as List<int>)) as List
          : const <dynamic>[];
      if (entriesFile == null) return 0;
      final entriesJson =
          jsonDecode(utf8.decode(entriesFile.content as List<int>)) as List;

      final total =
          categoriesJson.length + tagsJson.length + entriesJson.length;
      var processed = 0;

      final existingCategories = await _qrRepo.getCategoriesByDatabase(
        targetDatabaseId,
      );
      final categoryNameMap = {
        for (final category in existingCategories) category.name: category,
      };

      final existingTags = await _tagRepo.getAllTags(
        databaseId: targetDatabaseId,
      );
      final tagNameMap = {for (final tag in existingTags) tag.name: tag};

      final existingEntryIdByName = await _qrRepo.getEntryNameIdMapByDatabase(
        targetDatabaseId,
      );
      cancellationToken?.throwIfCancellationRequested();

      // Read categories
      final categoryIdMap = <String, String>{};
      for (final categoryJson in categoriesJson) {
        await _cooperativeCheckpoint(cancellationToken, processed: processed);
        final map = (categoryJson as Map).cast<String, dynamic>();
        final oldCategoryId = map['id'] as String?;
        final name = map['name'] as String;
        final category =
            categoryNameMap[name] ??
            await _qrRepo.createCategory(
              name: name,
              databaseId: targetDatabaseId,
            );
        categoryNameMap[name] = category;
        if (oldCategoryId != null && oldCategoryId.isNotEmpty) {
          categoryIdMap[oldCategoryId] = category.id;
        }
        processed++;
        _emitProgress(
          onProgress,
          phase: ImportExportProcessPhase.processingCategories,
          processed: processed,
          total: total,
          message: 'カテゴリをインポート中 ($processed/$total)',
        );
      }

      // Read tags
      final tagIdMap = <String, String>{};
      for (final tagJson in tagsJson) {
        await _cooperativeCheckpoint(cancellationToken, processed: processed);
        final map = (tagJson as Map).cast<String, dynamic>();
        final oldTagId = map['id'] as String?;
        final name = map['name'] as String;
        final tag =
            tagNameMap[name] ??
            await _tagRepo.createTag(
              name: name,
              color: map['color'] as int?,
              databaseId: targetDatabaseId,
            );
        tagNameMap[name] = tag;
        if (oldTagId != null && oldTagId.isNotEmpty) {
          tagIdMap[oldTagId] = tag.id;
        }
        processed++;
        _emitProgress(
          onProgress,
          phase: ImportExportProcessPhase.processingTags,
          processed: processed,
          total: total,
          message: 'タグをインポート中 ($processed/$total)',
        );
      }

      // Read entries
      for (final entryJson in entriesJson) {
        await _cooperativeCheckpoint(cancellationToken, processed: processed);
        final map = (entryJson as Map).cast<String, dynamic>();
        final id = map['id'] as String;
        final entryName = map['name'] as String;

        final existingId = existingEntryIdByName[entryName];

        // Get binary data
        final dataFile = archiveFileByName['data/$id.bin'];
        if (dataFile == null) continue;

        final thumbnailFile = archiveFileByName['thumbnails/$id.png'];

        final originalTagIds = _extractTagIds(map['tags']);
        final tagIds = originalTagIds
            .map((id) => tagIdMap[id])
            .whereType<String>()
            .toList(growable: false);

        final resolvedCategoryId = _resolveCategoryId(
          rawCategoryId: map['categoryId'],
          categoryIdMap: categoryIdMap,
        );

        final importDescription = (map['description'] as String?) ?? '';
        final importData = _asUint8List(dataFile.content);
        final importThumbnail = thumbnailFile != null
            ? _asUint8List(thumbnailFile.content)
            : null;

        if (existingId == null) {
          final created = await _qrRepo.createEntry(
            name: entryName,
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
          existingEntryIdByName[entryName] = created.id;
        } else {
          await _qrRepo.overwriteEntryFromImport(
            id: existingId,
            name: entryName,
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
        processed++;
        if (_shouldEmitEntryProgress(importedCount, entriesJson.length)) {
          _emitProgress(
            onProgress,
            phase: ImportExportProcessPhase.processingEntries,
            processed: processed,
            total: total,
            message: 'エントリをインポート中 ($importedCount/${entriesJson.length})',
          );
        }
      }

      _emitProgress(
        onProgress,
        phase: ImportExportProcessPhase.completed,
        processed: total,
        total: total,
        message: 'インポート完了',
      );

      return importedCount;
    });
  }

  /// Archive のファイル内容を Uint8List として返す。
  ///
  /// すでに Uint8List の場合はコピーを避け、そのまま利用する。
  Uint8List _asUint8List(Object? content) {
    if (content is Uint8List) {
      return content;
    }
    if (content is List<int>) {
      return Uint8List.fromList(content);
    }
    throw StateError('ZIP 内のデータ形式が不正です。');
  }

  /// キャンセル要求を取りこぼさないための協調チェックポイント。
  ///
  /// 一定件数ごとにイベントループへ制御を戻し、UI 側のキャンセル入力を処理できるようにする。
  Future<void> _cooperativeCheckpoint(
    ImportExportCancellationToken? cancellationToken, {
    required int processed,
  }) async {
    cancellationToken?.throwIfCancellationRequested();
    if (processed > 0 && processed % 8 == 0) {
      await Future<void>.delayed(Duration.zero);
      cancellationToken?.throwIfCancellationRequested();
    }
  }

  /// エントリ処理の進捗通知間隔を調整する。
  ///
  /// 通知頻度を抑えることで、進捗UI更新に伴う再描画コストを低減する。
  bool _shouldEmitEntryProgress(int importedCount, int totalEntries) {
    if (importedCount == totalEntries) return true;
    if (importedCount <= 3) return true;
    return importedCount % 8 == 0;
  }

  /// JSON 文字列からエントリをインポートする。
  /// [databaseId] を指定すると、インポート先のデータベースを明示する。
  /// インポート件数を返す。
  Future<int> importFromJson(
    String jsonString, {
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.preparing,
      processed: 0,
      total: 0,
      message: 'JSONを解析中',
    );
    cancellationToken?.throwIfCancellationRequested();

    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    var importedCount = 0;
    final targetDatabaseId = databaseId ?? 'default';
    final categoriesJson = data['categories'] as List? ?? [];
    final tagsJson = data['tags'] as List? ?? [];
    final entriesJson = data['entries'] as List? ?? [];
    final total = categoriesJson.length + tagsJson.length + entriesJson.length;
    var processed = 0;

    final existingCategories = await _qrRepo.getCategoriesByDatabase(
      targetDatabaseId,
    );
    final categoryNameMap = {
      for (final category in existingCategories) category.name: category,
    };

    final existingTags = await _tagRepo.getAllTags(
      databaseId: targetDatabaseId,
    );
    final tagNameMap = {for (final tag in existingTags) tag.name: tag};

    final existingEntryIdByName = <String, String>{};
    cancellationToken?.throwIfCancellationRequested();

    // Import categories
    final categoryIdMap = <String, String>{};
    for (final categoryJson in categoriesJson) {
      cancellationToken?.throwIfCancellationRequested();
      final map = (categoryJson as Map).cast<String, dynamic>();
      final oldCategoryId = map['id'] as String?;
      final name = map['name'] as String;
      final category =
          categoryNameMap[name] ??
          await _qrRepo.createCategory(
            name: name,
            databaseId: targetDatabaseId,
          );
      categoryNameMap[name] = category;
      if (oldCategoryId != null && oldCategoryId.isNotEmpty) {
        categoryIdMap[oldCategoryId] = category.id;
      }
      processed++;
      _emitProgress(
        onProgress,
        phase: ImportExportProcessPhase.processingCategories,
        processed: processed,
        total: total,
        message: 'カテゴリをインポート中 ($processed/$total)',
      );
    }

    // Import tags
    final tagIdMap = <String, String>{};
    for (final tagJson in tagsJson) {
      cancellationToken?.throwIfCancellationRequested();
      final map = (tagJson as Map).cast<String, dynamic>();
      final oldTagId = map['id'] as String?;
      final name = map['name'] as String;
      final tag =
          tagNameMap[name] ??
          await _tagRepo.createTag(
            name: name,
            color: map['color'] as int?,
            databaseId: targetDatabaseId,
          );
      tagNameMap[name] = tag;
      if (oldTagId != null && oldTagId.isNotEmpty) {
        tagIdMap[oldTagId] = tag.id;
      }
      processed++;
      _emitProgress(
        onProgress,
        phase: ImportExportProcessPhase.processingTags,
        processed: processed,
        total: total,
        message: 'タグをインポート中 ($processed/$total)',
      );
    }

    // Import entries
    for (final entryJson in entriesJson) {
      cancellationToken?.throwIfCancellationRequested();
      final map = (entryJson as Map).cast<String, dynamic>();
      final entryName = map['name'] as String;
      var existingId = existingEntryIdByName[entryName];
      existingId ??= await _qrRepo.getEntryIdByName(
        databaseId: targetDatabaseId,
        name: entryName,
      );
      if (existingId != null) {
        existingEntryIdByName[entryName] = existingId;
      }

      final originalData = map['originalData'] as List?;
      if (originalData == null) continue;

      final thumbnailData = map['thumbnail'] as List?;
      final originalTagIds = _extractTagIds(map['tags']);
      final tagIds = originalTagIds
          .map((id) => tagIdMap[id])
          .whereType<String>()
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

      if (existingId == null) {
        final created = await _qrRepo.createEntry(
          name: entryName,
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
        existingEntryIdByName[entryName] = created.id;
      } else {
        await _qrRepo.overwriteEntryFromImport(
          id: existingId,
          name: entryName,
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
      processed++;
      _emitProgress(
        onProgress,
        phase: ImportExportProcessPhase.processingEntries,
        processed: processed,
        total: total,
        message: 'エントリをインポート中 ($importedCount/${entriesJson.length})',
      );
    }

    _emitProgress(
      onProgress,
      phase: ImportExportProcessPhase.completed,
      processed: total,
      total: total,
      message: 'インポート完了',
    );

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
    return categoryIdMap[rawCategoryId];
  }

  /// 進捗を通知する。
  void _emitProgress(
    ImportExportProgressCallback? onProgress, {
    required ImportExportProcessPhase phase,
    required int processed,
    required int total,
    required String message,
  }) {
    if (onProgress == null) return;
    onProgress(
      ImportExportProgress(
        phase: phase,
        processed: processed,
        total: total,
        message: message,
      ),
    );
  }
}
