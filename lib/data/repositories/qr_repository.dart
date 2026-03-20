import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/qr_entry_model.dart';

/// QR エントリの CRUD 操作を提供するリポジトリ。
///
/// [AppDatabase] の DAO をラップし、ドメインモデル ([QrEntryModel]) への
/// 変換やタグ付けを一括で行う。
class QrRepository {
  QrRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // --- データベース (コレクション) ---

  /// 全データベースを取得する。
  Future<List<QrDatabaseModel>> getAllDatabases() async {
    final dbs = await _db.qrEntryDao.getAllDatabases();
    return dbs.map(_dbToModel).toList();
  }

  /// 全データベースを監視する。
  Stream<List<QrDatabaseModel>> watchAllDatabases() {
    return _db.qrEntryDao.watchAllDatabases().map(
      (dbs) => dbs.map(_dbToModel).toList(),
    );
  }

  /// 新規データベースを作成する。
  Future<QrDatabaseModel> createDatabase({
    required String name,
    String description = '',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.qrEntryDao.insertDatabase(
      QrDatabasesCompanion.insert(
        id: id,
        name: name,
        description: Value(description),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return QrDatabaseModel(
      id: id,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// データベースの名前・説明を更新する。
  Future<void> updateDatabase({
    required String id,
    String? name,
    String? description,
  }) async {
    await _db.qrEntryDao.updateDatabase(
      QrDatabasesCompanion(
        id: Value(id),
        name: name != null ? Value(name) : const Value.absent(),
        description: description != null
            ? Value(description)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// データベースとその配下のデータをすべて削除する。
  Future<void> deleteDatabase(String id) => _db.qrEntryDao.deleteDatabase(id);

  // --- カテゴリ ---

  /// 指定データベースのカテゴリを表示順で監視する。
  Stream<List<CategoryModel>> watchCategoriesByDatabase(String databaseId) {
    return _db.categoryDao
        .watchCategoriesByDatabase(databaseId)
        .map(
          (rows) => rows
              .map(
                (row) => CategoryModel(
                  id: row.id,
                  databaseId: row.databaseId,
                  name: row.name,
                  sortOrder: row.sortOrder,
                ),
              )
              .toList(),
        );
  }

  /// 新規カテゴリを作成する。
  Future<CategoryModel> createCategory({
    required String name,
    String databaseId = 'default',
  }) async {
    final existing = await _db.categoryDao.getCategoriesByDatabase(databaseId);
    final id = _uuid.v4();
    final sortOrder = existing.length;
    await _db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        id: id,
        databaseId: Value(databaseId),
        name: name,
        sortOrder: Value(sortOrder),
      ),
    );
    return CategoryModel(
      id: id,
      databaseId: databaseId,
      name: name,
      sortOrder: sortOrder,
    );
  }

  /// カテゴリ名を更新する。
  Future<void> updateCategory({required String id, String? name}) {
    return _db.categoryDao.updateCategory(
      CategoriesCompanion(
        id: Value(id),
        name: name != null ? Value(name) : const Value.absent(),
      ),
    );
  }

  /// カテゴリを削除する。
  Future<void> deleteCategory(String id) => _db.categoryDao.deleteCategory(id);

  /// カテゴリ表示順を更新する。
  Future<void> reorderCategories(String databaseId, List<String> orderedIds) {
    return _db.categoryDao.updateSortOrders(databaseId, orderedIds);
  }

  // --- エントリ ---

  /// 全エントリを取得する。[databaseId] 指定時はそのDBのみ。タグ情報も同時に読み込む。
  Future<List<QrEntryModel>> getAllEntries({String? databaseId}) async {
    final List<QrEntry> entries;
    if (databaseId != null) {
      entries = await _db.qrEntryDao.getEntriesByDatabase(databaseId);
    } else {
      entries = await _db.qrEntryDao.getAllEntries();
    }
    return Future.wait(entries.map(_toModel));
  }

  /// 指定データベースのエントリをリアルタイム監視するストリーム。
  Stream<List<QrEntryModel>> watchEntriesByDatabase(String databaseId) {
    return _db.qrEntryDao
        .watchEntriesByDatabase(databaseId)
        .asyncMap((entries) => Future.wait(entries.map(_toModel)));
  }

  /// 全エントリをリアルタイム監視するストリーム。
  Stream<List<QrEntryModel>> watchAllEntries() {
    return _db.qrEntryDao.watchAllEntries().asyncMap(
      (entries) => Future.wait(entries.map(_toModel)),
    );
  }

  /// 指定 ID のエントリを取得する。見つからない場合は null。
  Future<QrEntryModel?> getEntryById(String id) async {
    final entry = await _db.qrEntryDao.getEntryById(id);
    if (entry == null) return null;
    return _toModel(entry);
  }

  /// 新規エントリを作成して返す。
  ///
  /// [data] が空の場合は QR コード未登録のエントリとなる。
  Future<QrEntryModel> createEntry({
    required String name,
    String description = '',
    required Uint8List data,
    required int chunkCount,
    bool isTextMode = false,
    bool isFavorite = false,
    Uint8List? thumbnail,
    List<String> tagIds = const [],
    String databaseId = 'default',
    String? categoryId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.qrEntryDao.insertEntry(
      QrEntriesCompanion.insert(
        id: id,
        databaseId: Value(databaseId),
        categoryId: Value(categoryId),
        name: name,
        description: Value(description),
        originalData: data,
        dataSize: data.length,
        chunkCount: Value(chunkCount),
        isTextMode: Value(isTextMode),
        isFavorite: Value(isFavorite),
        thumbnail: Value(thumbnail),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    if (tagIds.isNotEmpty) {
      await _db.qrEntryDao.setTagsForEntry(id, tagIds);
    }

    return (await getEntryById(id))!;
  }

  /// エントリのメタデータを更新する。
  Future<void> updateEntry({
    required String id,
    String? name,
    String? description,
    bool? isTextMode,
    bool? isFavorite,
    String? categoryId,
    bool clearCategory = false,
    Uint8List? thumbnail,
    List<String>? tagIds,
  }) async {
    final companion = QrEntriesCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      description: description != null
          ? Value(description)
          : const Value.absent(),
      isTextMode: isTextMode != null ? Value(isTextMode) : const Value.absent(),
      isFavorite: isFavorite != null ? Value(isFavorite) : const Value.absent(),
      categoryId: clearCategory
          ? const Value(null)
          : categoryId != null
          ? Value(categoryId)
          : const Value.absent(),
      thumbnail: thumbnail != null ? Value(thumbnail) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await _db.qrEntryDao.updateEntry(companion);

    if (tagIds != null) {
      await _db.qrEntryDao.setTagsForEntry(id, tagIds);
    }
  }

  /// エントリの QR コードデータを更新する。
  Future<void> updateQrData({
    required String id,
    required Uint8List data,
    required bool isTextMode,
  }) async {
    await _db.qrEntryDao.updateEntry(
      QrEntriesCompanion(
        id: Value(id),
        originalData: Value(data),
        dataSize: Value(data.length),
        isTextMode: Value(isTextMode),
        chunkCount: const Value(1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// エントリの QR コードデータを削除（空にする）する。
  Future<void> clearQrData(String id) async {
    await _db.qrEntryDao.updateEntry(
      QrEntriesCompanion(
        id: Value(id),
        originalData: Value(Uint8List(0)),
        dataSize: const Value(0),
        chunkCount: const Value(0),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteEntry(String id) => _db.qrEntryDao.deleteEntry(id);

  /// 複数エントリを一括削除する。
  Future<void> deleteEntries(List<String> ids) =>
      _db.qrEntryDao.deleteEntries(ids);

  /// 複数エントリにカテゴリを一括設定する。
  Future<void> setCategoryForEntries(
    List<String> entryIds,
    String? categoryId,
  ) {
    return _db.qrEntryDao.setCategoryForEntries(entryIds, categoryId);
  }

  /// お気に入り状態をトグルする。
  Future<void> toggleFavorite(String id) async {
    final entry = await _db.qrEntryDao.getEntryById(id);
    if (entry == null) return;
    await _db.qrEntryDao.updateEntry(
      QrEntriesCompanion(
        id: Value(id),
        isFavorite: Value(!entry.isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// originalData が完全一致するエントリを検索する。
  ///
  /// まず dataSize で候補を絞り込み、Dart 側でバイト列を比較する。
  Future<QrEntryModel?> findByOriginalData(Uint8List data) async {
    final candidates = await _db.qrEntryDao.getEntriesByDataSize(data.length);
    for (final entry in candidates) {
      if (listEquals(entry.originalData, data)) {
        return _toModel(entry);
      }
    }
    return null;
  }

  /// 検索。テキスト検索でタグ名も対象とする。
  Future<List<QrEntryModel>> search({
    String? textQuery,
    List<String> tagIds = const [],
    String? databaseId,
    bool? hasQrData,
  }) async {
    final entries = await _db.qrEntryDao.searchEntriesWithTags(
      textQuery,
      tagIds,
      databaseId: databaseId,
      hasQrData: hasQrData,
    );
    return Future.wait(entries.map(_toModel));
  }

  // --- 変換ヘルパー ---

  QrDatabaseModel _dbToModel(QrDatabase db) {
    return QrDatabaseModel(
      id: db.id,
      name: db.name,
      description: db.description,
      createdAt: db.createdAt,
      updatedAt: db.updatedAt,
    );
  }

  /// drift の行データをドメインモデルに変換する。タグも同時に取得する。
  Future<QrEntryModel> _toModel(QrEntry entry) async {
    final tags = await _db.qrEntryDao.getTagsForEntry(entry.id);
    return QrEntryModel(
      id: entry.id,
      databaseId: entry.databaseId,
      categoryId: entry.categoryId,
      name: entry.name,
      description: entry.description,
      originalData: entry.originalData,
      dataSize: entry.dataSize,
      chunkCount: entry.chunkCount,
      isTextMode: entry.isTextMode,
      isFavorite: entry.isFavorite,
      thumbnail: entry.thumbnail,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      tags: tags
          .map(
            (t) => TagModel(
              id: t.id,
              databaseId: t.databaseId,
              name: t.name,
              color: t.color,
            ),
          )
          .toList(),
    );
  }
}
