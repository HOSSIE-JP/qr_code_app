import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:qr_shared/qr_shared.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

import '../editor_state.dart';

const int kExportVersion = 1;

/// 外部ファイルと [EditorDocument] を相互変換する I/O サービス。
class EditorFileService {
  /// 拡張子で読み込み形式を判定して [EditorDocument] を構築する。
  static Future<EditorDocument> loadFromPath(String filePath) async {
    final extension = p.extension(filePath).toLowerCase();
    switch (extension) {
      case '.qrjson':
      case '.json':
        return _loadFromJsonPath(filePath);
      case '.qrdb':
        return _loadFromQrdbPath(filePath);
      case '.xlsx':
        return _loadFromSpreadsheetPath(filePath, isOds: false);
      case '.ods':
        return _loadFromSpreadsheetPath(filePath, isOds: true);
      case '.csv':
        return _loadFromCsvPath(filePath);
      case '.yaml':
      case '.yml':
        return _loadFromYamlPath(filePath);
      default:
        throw FormatException('未対応の拡張子です: $extension');
    }
  }

  /// 拡張子で保存形式を判定して [document] を書き出す。
  static Future<void> saveToPath(
    String filePath,
    EditorDocument document,
  ) async {
    final extension = p.extension(filePath).toLowerCase();
    switch (extension) {
      case '.qrjson':
      case '.json':
        await _saveAsJson(filePath, document);
        return;
      case '.qrdb':
        await _saveAsQrdb(filePath, document);
        return;
      case '.xlsx':
        await _saveAsExcel(filePath, document);
        return;
      case '.ods':
        await _saveAsOds(filePath, document);
        return;
      case '.csv':
        await _saveAsCsvBundle(filePath, document);
        return;
      case '.yaml':
      case '.yml':
        await _saveAsYaml(filePath, document);
        return;
      default:
        throw FormatException('未対応の拡張子です: $extension');
    }
  }

  /// Excel/ODS の雛形ファイルを出力する。
  static Future<void> createTemplate({
    required String filePath,
    required bool ods,
  }) async {
    final template = EditorDocument.empty().copyWith(
      entries: [_sampleEntry()],
      tags: [_sampleTag()],
      categories: [_sampleCategory()],
    );
    if (ods) {
      await _saveAsOds(filePath, template, writeBinaryAssets: false);
      return;
    }
    await _saveAsExcel(filePath, template, writeBinaryAssets: false);
  }

  static Future<EditorDocument> _loadFromJsonPath(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON のトップレベルが Map ではありません。');
    }
    return _documentFromStandardMap(decoded, sourcePath: filePath);
  }

  static Future<EditorDocument> _loadFromYamlPath(String filePath) async {
    final content = await File(filePath).readAsString();
    final parsed = loadYaml(content);
    final map = _yamlToMap(parsed);
    final baseDir = p.dirname(filePath);
    return _documentFromStandardMap(
      map,
      sourcePath: filePath,
      baseDirForRelativeAssets: baseDir,
    );
  }

  static Future<EditorDocument> _loadFromQrdbPath(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final metadata =
        _readArchiveJson(archive, 'metadata.json') ?? <String, dynamic>{};
    final entriesList =
        _readArchiveJson(archive, 'entries.json') as List<dynamic>? ??
        <dynamic>[];
    final tagsList =
        _readArchiveJson(archive, 'tags.json') as List<dynamic>? ?? <dynamic>[];
    final categoriesList =
        _readArchiveJson(archive, 'categories.json') as List<dynamic>? ??
        <dynamic>[];

    final tags = tagsList
        .map((value) => TagModel.fromJson(_normalizeMap(value)))
        .toList();
    final categories = categoriesList
        .map((value) => CategoryModel.fromJson(_normalizeMap(value)))
        .toList();

    final entries = <QrEntryModel>[];
    for (final rawEntry in entriesList) {
      final map = _normalizeMap(rawEntry);
      final id = map['id']?.toString() ?? '';
      final dataFile = archive.findFile('data/$id.bin');
      final thumbnailFile = archive.findFile('thumbnails/$id.png');
      final originalData = dataFile == null
          ? Uint8List(0)
          : Uint8List.fromList(dataFile.content as List<int>);
      final thumbnail = thumbnailFile == null
          ? null
          : Uint8List.fromList(thumbnailFile.content as List<int>);
      map['originalData'] = originalData.toList();
      map['thumbnail'] = thumbnail?.toList();
      entries.add(QrEntryModel.fromJson(map));
    }

    final exportedAtRaw = metadata['exportedAt'];
    final exportedAt = exportedAtRaw is String
        ? DateTime.tryParse(exportedAtRaw)?.toUtc() ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    return EditorDocument(
      entries: entries,
      tags: tags,
      categories: categories,
      version: metadata['version'] is int
          ? metadata['version'] as int
          : kExportVersion,
      exportedAt: exportedAt,
      sourcePath: filePath,
      selectedEntryId: entries.isEmpty ? null : entries.first.id,
    );
  }

  static Future<EditorDocument> _loadFromSpreadsheetPath(
    String filePath, {
    required bool isOds,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);

    final entriesRows = _sheetRows(decoder, 'entries');
    final tagsRows = _sheetRows(decoder, 'tags');
    final categoriesRows = _sheetRows(decoder, 'categories');

    final baseDir = p.dirname(filePath);
    final entryRows = _entriesFromTabularRows(entriesRows, baseDir: baseDir);
    final tags = _tagsFromTabularRows(tagsRows);
    final categories = _categoriesFromTabularRows(categoriesRows);
    final tagsById = {for (final tag in tags) tag.id: tag};
    final entries = entryRows
        .map(
          (row) => row.entry.copyWith(
            tags: [
              for (final id in row.tagIds)
                if (tagsById[id] != null) tagsById[id]!,
            ],
          ),
        )
        .toList();

    return EditorDocument(
      entries: entries,
      tags: tags,
      categories: categories,
      version: kExportVersion,
      exportedAt: DateTime.now().toUtc(),
      sourcePath: filePath,
      selectedEntryId: entries.isEmpty ? null : entries.first.id,
    );
  }

  static Future<EditorDocument> _loadFromCsvPath(String filePath) async {
    final dir = Directory(p.dirname(filePath));
    final base = p.basenameWithoutExtension(filePath);
    final entriesFile = File(p.join(dir.path, '${base}_entries.csv'));
    final tagsFile = File(p.join(dir.path, '${base}_tags.csv'));
    final categoriesFile = File(p.join(dir.path, '${base}_categories.csv'));

    final resolvedEntries = await entriesFile.exists()
        ? entriesFile
        : File(filePath);
    final entriesRows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(await resolvedEntries.readAsString());

    final tagsRows = await tagsFile.exists()
        ? const CsvToListConverter(
            eol: '\n',
            shouldParseNumbers: false,
          ).convert(await tagsFile.readAsString())
        : <List<dynamic>>[];
    final categoriesRows = await categoriesFile.exists()
        ? const CsvToListConverter(
            eol: '\n',
            shouldParseNumbers: false,
          ).convert(await categoriesFile.readAsString())
        : <List<dynamic>>[];

    final entryRows = _entriesFromTabularRows(entriesRows, baseDir: dir.path);
    final tags = _tagsFromTabularRows(tagsRows);
    final categories = _categoriesFromTabularRows(categoriesRows);
    final tagsById = {for (final tag in tags) tag.id: tag};
    final entries = entryRows
        .map(
          (row) => row.entry.copyWith(
            tags: [
              for (final id in row.tagIds)
                if (tagsById[id] != null) tagsById[id]!,
            ],
          ),
        )
        .toList();

    return EditorDocument(
      entries: entries,
      tags: tags,
      categories: categories,
      version: kExportVersion,
      exportedAt: DateTime.now().toUtc(),
      sourcePath: filePath,
      selectedEntryId: entries.isEmpty ? null : entries.first.id,
    );
  }

  static Future<void> _saveAsJson(
    String filePath,
    EditorDocument document,
  ) async {
    final jsonMap = _toStandardMap(document, inlineBinary: true);
    await File(
      filePath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(jsonMap));
  }

  static Future<void> _saveAsYaml(
    String filePath,
    EditorDocument document,
  ) async {
    final map = _toStandardMap(
      document,
      inlineBinary: false,
      relativeAssetRoot: p.dirname(filePath),
    );
    final writer = YamlWriter();
    await File(filePath).writeAsString(writer.write(map));
  }

  static Future<void> _saveAsQrdb(
    String filePath,
    EditorDocument document,
  ) async {
    final archive = Archive();

    final metadata = <String, dynamic>{
      'version': document.version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'entryCount': document.entries.length,
      'tagCount': document.tags.length,
      'categoryCount': document.categories.length,
    };

    final entries = <Map<String, dynamic>>[];
    for (final entry in document.entries) {
      final entryJson = entry.toJson();
      entryJson.remove('originalData');
      entryJson.remove('thumbnail');
      entries.add(entryJson);

      archive.addFile(
        ArchiveFile(
          'data/${entry.id}.bin',
          entry.originalData.length,
          entry.originalData,
        ),
      );
      if (entry.thumbnail != null) {
        archive.addFile(
          ArchiveFile(
            'thumbnails/${entry.id}.png',
            entry.thumbnail!.length,
            entry.thumbnail!,
          ),
        );
      }
    }

    archive.addFile(
      ArchiveFile.string(
        'metadata.json',
        const JsonEncoder.withIndent('  ').convert(metadata),
      ),
    );
    archive.addFile(
      ArchiveFile.string(
        'entries.json',
        const JsonEncoder.withIndent('  ').convert(entries),
      ),
    );
    archive.addFile(
      ArchiveFile.string(
        'tags.json',
        const JsonEncoder.withIndent(
          '  ',
        ).convert(document.tags.map((e) => e.toJson()).toList()),
      ),
    );
    archive.addFile(
      ArchiveFile.string(
        'categories.json',
        const JsonEncoder.withIndent(
          '  ',
        ).convert(document.categories.map((e) => e.toJson()).toList()),
      ),
    );

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw const FileSystemException('ZIP エンコードに失敗しました。');
    }
    await File(filePath).writeAsBytes(encoded);
  }

  static Future<void> _saveAsExcel(
    String filePath,
    EditorDocument document, {
    bool writeBinaryAssets = true,
  }) async {
    final excel = Excel.createExcel();
    _writeTabularSheets(
      writeSheet: (name, rows) {
        final sheet = excel[name];
        for (final row in rows) {
          sheet.appendRow(row.map(TextCellValue.new).toList());
        }
      },
      document: document,
      baseDir: p.dirname(filePath),
      writeBinaryAssets: writeBinaryAssets,
    );

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    final bytes = excel.encode();
    if (bytes == null) {
      throw const FileSystemException('Excel のエンコードに失敗しました。');
    }
    await File(filePath).writeAsBytes(bytes);
  }

  static Future<void> _saveAsOds(
    String filePath,
    EditorDocument document, {
    bool writeBinaryAssets = true,
  }) async {
    final sheets = <String, List<List<String>>>{};
    _writeTabularSheets(
      writeSheet: (name, rows) => sheets[name] = rows,
      document: document,
      baseDir: p.dirname(filePath),
      writeBinaryAssets: writeBinaryAssets,
    );

    final archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        'mimetype',
        'application/vnd.oasis.opendocument.spreadsheet',
      ),
    );
    archive.addFile(
      ArchiveFile.string('content.xml', _buildOdsContentXml(sheets)),
    );
    archive.addFile(
      ArchiveFile.string(
        'META-INF/manifest.xml',
        '''<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2">
  <manifest:file-entry manifest:full-path="/" manifest:media-type="application/vnd.oasis.opendocument.spreadsheet"/>
  <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
</manifest:manifest>
''',
      ),
    );

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      throw const FileSystemException('ODS のエンコードに失敗しました。');
    }
    await File(filePath).writeAsBytes(bytes);
  }

  static Future<void> _saveAsCsvBundle(
    String filePath,
    EditorDocument document, {
    bool writeBinaryAssets = true,
  }) async {
    final dir = Directory(p.dirname(filePath));
    final base = p.basenameWithoutExtension(filePath);
    final sheets = <String, List<List<String>>>{};
    _writeTabularSheets(
      writeSheet: (name, rows) => sheets[name] = rows,
      document: document,
      baseDir: dir.path,
      writeBinaryAssets: writeBinaryAssets,
    );

    for (final entry in sheets.entries) {
      final csv = const ListToCsvConverter().convert(entry.value);
      await File(
        p.join(dir.path, '${base}_${entry.key}.csv'),
      ).writeAsString(csv);
    }
  }

  static void _writeTabularSheets({
    required void Function(String name, List<List<String>> rows) writeSheet,
    required EditorDocument document,
    required String baseDir,
    bool writeBinaryAssets = true,
  }) {
    final entries = <List<String>>[
      const <String>[
        'id',
        'databaseId',
        'categoryId',
        'name',
        'description',
        'isTextMode',
        'isFavorite',
        'dataSize',
        'textData',
        'dataFilePath',
        'thumbnailPath',
        'createdAt',
        'updatedAt',
        'tagIds',
      ],
    ];

    Directory? assetDataDir;
    Directory? assetThumbDir;
    if (writeBinaryAssets) {
      assetDataDir = Directory(p.join(baseDir, 'data'));
      assetThumbDir = Directory(p.join(baseDir, 'thumbnails'));
      if (!assetDataDir.existsSync()) {
        assetDataDir.createSync(recursive: true);
      }
      if (!assetThumbDir.existsSync()) {
        assetThumbDir.createSync(recursive: true);
      }
    }

    for (final entry in document.entries) {
      var dataPathForRow = '';
      if (writeBinaryAssets && assetDataDir != null) {
        final dataFilePath = p.join(assetDataDir.path, '${entry.id}.bin');
        File(dataFilePath).writeAsBytesSync(entry.originalData);
        dataPathForRow = p.relative(dataFilePath, from: baseDir);
      }

      String thumbnailPath = '';
      if (writeBinaryAssets &&
          entry.thumbnail != null &&
          assetThumbDir != null) {
        thumbnailPath = p.join(assetThumbDir.path, '${entry.id}.png');
        File(thumbnailPath).writeAsBytesSync(entry.thumbnail!);
      }

      entries.add(<String>[
        entry.id,
        entry.databaseId,
        entry.categoryId ?? '',
        entry.name,
        entry.description,
        entry.isTextMode.toString(),
        entry.isFavorite.toString(),
        entry.dataSize.toString(),
        entry.isTextMode
            ? utf8.decode(entry.originalData, allowMalformed: true)
            : '',
        dataPathForRow,
        thumbnailPath.isEmpty ? '' : p.relative(thumbnailPath, from: baseDir),
        entry.createdAt.toUtc().toIso8601String(),
        entry.updatedAt.toUtc().toIso8601String(),
        entry.tags.map((tag) => tag.id).join(';'),
      ]);
    }

    final tags = <List<String>>[
      const <String>['id', 'databaseId', 'name', 'color'],
      for (final tag in document.tags)
        <String>[tag.id, tag.databaseId, tag.name, tag.color.toString()],
    ];

    final categories = <List<String>>[
      const <String>['id', 'databaseId', 'name', 'sortOrder'],
      for (final category in document.categories)
        <String>[
          category.id,
          category.databaseId,
          category.name,
          category.sortOrder.toString(),
        ],
    ];

    writeSheet('entries', entries);
    writeSheet('tags', tags);
    writeSheet('categories', categories);
  }

  static List<List<dynamic>> _sheetRows(
    SpreadsheetDecoder decoder,
    String name,
  ) {
    final table = decoder.tables[name];
    if (table == null) {
      return <List<dynamic>>[];
    }
    return table.rows;
  }

  static List<_EntryRow> _entriesFromTabularRows(
    List<List<dynamic>> rows, {
    required String baseDir,
  }) {
    if (rows.isEmpty) {
      return <_EntryRow>[];
    }

    final headers = rows.first.map((e) => '$e').toList();
    final headerIndex = <String, int>{
      for (var i = 0; i < headers.length; i++) headers[i]: i,
    };

    String readCell(List<dynamic> row, String header) {
      final index = headerIndex[header];
      if (index == null || index >= row.length) {
        return '';
      }
      return '${row[index]}';
    }

    final entries = <_EntryRow>[];
    for (final row in rows.skip(1)) {
      final id = readCell(row, 'id');
      if (id.isEmpty) {
        continue;
      }
      final isTextMode = readCell(row, 'isTextMode').toLowerCase() == 'true';
      final textData = readCell(row, 'textData');
      final dataFilePath = readCell(row, 'dataFilePath');
      final thumbnailPath = readCell(row, 'thumbnailPath');

      Uint8List originalData = Uint8List(0);
      if (dataFilePath.isNotEmpty) {
        final dataFile = File(p.join(baseDir, dataFilePath));
        if (dataFile.existsSync()) {
          originalData = dataFile.readAsBytesSync();
        }
      } else if (isTextMode && textData.isNotEmpty) {
        originalData = Uint8List.fromList(utf8.encode(textData));
      }

      Uint8List? thumbnail;
      if (thumbnailPath.isNotEmpty) {
        final thumbFile = File(p.join(baseDir, thumbnailPath));
        if (thumbFile.existsSync()) {
          thumbnail = Uint8List.fromList(thumbFile.readAsBytesSync());
        }
      }

      final createdAt =
          DateTime.tryParse(readCell(row, 'createdAt')) ?? DateTime.now();
      final updatedAt =
          DateTime.tryParse(readCell(row, 'updatedAt')) ?? DateTime.now();

      final tagIds = readCell(row, 'tagIds')
          .split(';')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      entries.add(
        _EntryRow(
          tagIds: tagIds,
          entry: QrEntryModel(
            id: id,
            databaseId: readCell(row, 'databaseId').isEmpty
                ? 'default'
                : readCell(row, 'databaseId'),
            categoryId: readCell(row, 'categoryId').isEmpty
                ? null
                : readCell(row, 'categoryId'),
            name: readCell(row, 'name'),
            description: readCell(row, 'description'),
            originalData: originalData,
            dataSize: originalData.length,
            chunkCount: 1,
            isTextMode: isTextMode,
            isFavorite: readCell(row, 'isFavorite').toLowerCase() == 'true',
            thumbnail: thumbnail,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: const <TagModel>[],
          ),
        ),
      );
    }
    return entries;
  }

  static List<TagModel> _tagsFromTabularRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) {
      return <TagModel>[];
    }
    final headers = rows.first.map((e) => '$e').toList();
    final headerIndex = <String, int>{
      for (var i = 0; i < headers.length; i++) headers[i]: i,
    };

    String readCell(List<dynamic> row, String header) {
      final index = headerIndex[header];
      if (index == null || index >= row.length) {
        return '';
      }
      return '${row[index]}';
    }

    final tags = <TagModel>[];
    for (final row in rows.skip(1)) {
      final id = readCell(row, 'id');
      if (id.isEmpty) {
        continue;
      }
      tags.add(
        TagModel(
          id: id,
          databaseId: readCell(row, 'databaseId').isEmpty
              ? 'default'
              : readCell(row, 'databaseId'),
          name: readCell(row, 'name'),
          color: int.tryParse(readCell(row, 'color')) ?? 0xFF6750A4,
        ),
      );
    }
    return tags;
  }

  static List<CategoryModel> _categoriesFromTabularRows(
    List<List<dynamic>> rows,
  ) {
    if (rows.isEmpty) {
      return <CategoryModel>[];
    }
    final headers = rows.first.map((e) => '$e').toList();
    final headerIndex = <String, int>{
      for (var i = 0; i < headers.length; i++) headers[i]: i,
    };

    String readCell(List<dynamic> row, String header) {
      final index = headerIndex[header];
      if (index == null || index >= row.length) {
        return '';
      }
      return '${row[index]}';
    }

    final categories = <CategoryModel>[];
    for (final row in rows.skip(1)) {
      final id = readCell(row, 'id');
      if (id.isEmpty) {
        continue;
      }
      categories.add(
        CategoryModel(
          id: id,
          databaseId: readCell(row, 'databaseId').isEmpty
              ? 'default'
              : readCell(row, 'databaseId'),
          name: readCell(row, 'name'),
          sortOrder: int.tryParse(readCell(row, 'sortOrder')) ?? 0,
        ),
      );
    }
    return categories;
  }

  static Map<String, dynamic> _toStandardMap(
    EditorDocument document, {
    required bool inlineBinary,
    String? relativeAssetRoot,
  }) {
    final map = <String, dynamic>{
      'version': document.version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tags': document.tags.map((tag) => tag.toJson()).toList(),
      'categories': document.categories
          .map((category) => category.toJson())
          .toList(),
      'entries': <Map<String, dynamic>>[],
    };

    final entries = map['entries'] as List<Map<String, dynamic>>;
    for (final entry in document.entries) {
      final json = entry.toJson();
      if (!inlineBinary) {
        final root = relativeAssetRoot ?? Directory.current.path;
        final dataDir = Directory(p.join(root, 'data'));
        final thumbDir = Directory(p.join(root, 'thumbnails'));
        if (!dataDir.existsSync()) {
          dataDir.createSync(recursive: true);
        }
        if (!thumbDir.existsSync()) {
          thumbDir.createSync(recursive: true);
        }

        final dataPath = p.join(dataDir.path, '${entry.id}.bin');
        File(dataPath).writeAsBytesSync(entry.originalData);
        json['dataFilePath'] = p.relative(dataPath, from: root);
        json.remove('originalData');

        if (entry.thumbnail != null) {
          final thumbPath = p.join(thumbDir.path, '${entry.id}.png');
          File(thumbPath).writeAsBytesSync(entry.thumbnail!);
          json['thumbnailPath'] = p.relative(thumbPath, from: root);
        }
        json.remove('thumbnail');
      }
      entries.add(json);
    }
    return map;
  }

  static EditorDocument _documentFromStandardMap(
    Map<String, dynamic> map, {
    required String sourcePath,
    String? baseDirForRelativeAssets,
  }) {
    final tagsRaw = map['tags'] as List<dynamic>? ?? <dynamic>[];
    final categoriesRaw = map['categories'] as List<dynamic>? ?? <dynamic>[];
    final entriesRaw = map['entries'] as List<dynamic>? ?? <dynamic>[];

    final tags = tagsRaw
        .map((json) => TagModel.fromJson(_normalizeMap(json)))
        .toList();
    final categories = categoriesRaw
        .map((json) => CategoryModel.fromJson(_normalizeMap(json)))
        .toList();

    final entries = <QrEntryModel>[];
    for (final json in entriesRaw) {
      final entryMap = _normalizeMap(json);
      _normalizeBinaryFields(entryMap);
      if (!entryMap.containsKey('originalData') &&
          entryMap['dataFilePath'] is String) {
        final root = baseDirForRelativeAssets ?? p.dirname(sourcePath);
        final file = File(p.join(root, entryMap['dataFilePath'] as String));
        entryMap['originalData'] = file.existsSync()
            ? Uint8List.fromList(file.readAsBytesSync()).toList()
            : <int>[];
      }
      if (!entryMap.containsKey('thumbnail') &&
          entryMap['thumbnailPath'] is String) {
        final root = baseDirForRelativeAssets ?? p.dirname(sourcePath);
        final file = File(p.join(root, entryMap['thumbnailPath'] as String));
        entryMap['thumbnail'] = file.existsSync()
            ? Uint8List.fromList(file.readAsBytesSync()).toList()
            : null;
      }
      _normalizeBinaryFields(entryMap);
      entries.add(QrEntryModel.fromJson(entryMap));
    }

    final exportedAtRaw = map['exportedAt'];
    final exportedAt = exportedAtRaw is String
        ? DateTime.tryParse(exportedAtRaw)?.toUtc() ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    return EditorDocument(
      entries: entries,
      tags: tags,
      categories: categories,
      version: map['version'] is int ? map['version'] as int : kExportVersion,
      exportedAt: exportedAt,
      sourcePath: sourcePath,
      selectedEntryId: entries.isEmpty ? null : entries.first.id,
    );
  }

  static dynamic _readArchiveJson(Archive archive, String path) {
    final file = archive.findFile(path);
    if (file == null) {
      return null;
    }
    final content = utf8.decode(file.content as List<int>);
    return jsonDecode(content);
  }

  static Map<String, dynamic> _yamlToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map((key, value) => MapEntry('$key', _yamlValue(value)));
    }
    if (yaml is Map<String, dynamic>) {
      return yaml;
    }
    throw const FormatException('YAML のトップレベルが Map ではありません。');
  }

  static dynamic _yamlValue(dynamic value) {
    if (value is YamlMap) {
      return value.map((key, val) => MapEntry('$key', _yamlValue(val)));
    }
    if (value is YamlList) {
      return value.map(_yamlValue).toList();
    }
    return value;
  }

  static Map<String, dynamic> _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    throw const FormatException('Map 形式のデータが必要です。');
  }

  static void _normalizeBinaryFields(Map<String, dynamic> map) {
    final originalData = map['originalData'];
    if (originalData is List) {
      map['originalData'] = originalData
          .map((value) => (value as num).toInt())
          .toList();
    }
    final thumbnail = map['thumbnail'];
    if (thumbnail is List) {
      map['thumbnail'] = thumbnail
          .map((value) => (value as num).toInt())
          .toList();
    }
  }

  static String _buildOdsContentXml(Map<String, List<List<String>>> sheets) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" office:version="1.2">',
    );
    buffer.writeln('<office:body><office:spreadsheet>');

    for (final sheet in sheets.entries) {
      buffer.writeln('<table:table table:name="${_xmlEscape(sheet.key)}">');
      for (final row in sheet.value) {
        buffer.writeln('<table:table-row>');
        for (final cell in row) {
          buffer.writeln(
            '<table:table-cell office:value-type="string"><text:p>${_xmlEscape(cell)}</text:p></table:table-cell>',
          );
        }
        buffer.writeln('</table:table-row>');
      }
      buffer.writeln('</table:table>');
    }

    buffer.writeln(
      '</office:spreadsheet></office:body></office:document-content>',
    );
    return buffer.toString();
  }

  static String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static QrEntryModel _sampleEntry() {
    final now = DateTime.now().toUtc();
    final data = Uint8List.fromList(utf8.encode('sample text'));
    return QrEntryModel(
      id: 'sample-entry-id',
      databaseId: 'default',
      categoryId: 'sample-category-id',
      name: 'サンプルエントリ',
      description: 'この行を編集して利用してください。',
      originalData: data,
      dataSize: data.length,
      chunkCount: 1,
      isTextMode: true,
      isFavorite: false,
      thumbnail: null,
      createdAt: now,
      updatedAt: now,
      tags: const <TagModel>[],
    );
  }

  static TagModel _sampleTag() {
    return const TagModel(
      id: 'sample-tag-id',
      databaseId: 'default',
      name: 'sample-tag',
      color: 0xFF6750A4,
    );
  }

  static CategoryModel _sampleCategory() {
    return const CategoryModel(
      id: 'sample-category-id',
      databaseId: 'default',
      name: 'sample-category',
      sortOrder: 0,
    );
  }
}

class _EntryRow {
  const _EntryRow({required this.entry, required this.tagIds});

  final QrEntryModel entry;
  final List<String> tagIds;
}
