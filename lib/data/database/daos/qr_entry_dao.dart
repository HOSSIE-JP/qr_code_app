import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/entry_tags.dart';
import '../tables/qr_databases.dart';
import '../tables/qr_entries.dart';
import '../tables/tags.dart';

part 'qr_entry_dao.g.dart';

/// QR エントリの CRUD 、検索、タグ管理を行う DAO。
@DriftAccessor(tables: [QrDatabases, QrEntries, EntryTags, Tags])
class QrEntryDao extends DatabaseAccessor<AppDatabase> with _$QrEntryDaoMixin {
  QrEntryDao(super.db);

  // --- データベース (コレクション) ---

  /// 全データベースを取得する。
  Future<List<QrDatabase>> getAllDatabases() =>
      (select(qrDatabases)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  /// 全データベースを監視する。
  Stream<List<QrDatabase>> watchAllDatabases() =>
      (select(qrDatabases)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// データベースを挿入する。
  Future<void> insertDatabase(QrDatabasesCompanion db) =>
      into(qrDatabases).insert(db);

  /// データベースを更新する。
  Future<void> updateDatabase(QrDatabasesCompanion db) =>
      (update(qrDatabases)..where((t) => t.id.equals(db.id.value))).write(db);

  /// データベースを削除する。配下のエントリとタグも削除する。
  Future<void> deleteDatabase(String id) async {
    // そのDBに属するエントリの entryTags を先に削除
    final entries = await (select(
      qrEntries,
    )..where((t) => t.databaseId.equals(id))).get();
    for (final entry in entries) {
      await (delete(entryTags)..where((t) => t.entryId.equals(entry.id))).go();
    }
    await (delete(qrEntries)..where((t) => t.databaseId.equals(id))).go();
    // そのDBに属するタグを削除
    final dbTags = await (select(
      tags,
    )..where((t) => t.databaseId.equals(id))).get();
    for (final tag in dbTags) {
      await (delete(entryTags)..where((t) => t.tagId.equals(tag.id))).go();
    }
    await (delete(tags)..where((t) => t.databaseId.equals(id))).go();
    await (delete(qrDatabases)..where((t) => t.id.equals(id))).go();
  }

  // --- エントリ ---

  Future<List<QrEntry>> getAllEntries() => select(qrEntries).get();

  /// 指定データベースの全エントリを取得する。
  Future<List<QrEntry>> getEntriesByDatabase(String databaseId) =>
      (select(qrEntries)
            ..where((t) => t.databaseId.equals(databaseId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  /// 指定データベースの全エントリを監視する。
  Stream<List<QrEntry>> watchEntriesByDatabase(String databaseId) =>
      (select(qrEntries)
            ..where((t) => t.databaseId.equals(databaseId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Stream<List<QrEntry>> watchAllEntries() => (select(
    qrEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<QrEntry?> getEntryById(String id) =>
      (select(qrEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 指定データサイズに一致するエントリ一覧を返す（重複検出の前段フィルタ用）。
  Future<List<QrEntry>> getEntriesByDataSize(int size) =>
      (select(qrEntries)..where((t) => t.dataSize.equals(size))).get();

  Stream<QrEntry?> watchEntryById(String id) =>
      (select(qrEntries)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> insertEntry(QrEntriesCompanion entry) =>
      into(qrEntries).insert(entry);

  Future<void> updateEntry(QrEntriesCompanion entry) => (update(
    qrEntries,
  )..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> deleteEntry(String id) async {
    await (delete(entryTags)..where((t) => t.entryId.equals(id))).go();
    await (delete(qrEntries)..where((t) => t.id.equals(id))).go();
  }

  /// 複数エントリを一括削除する。
  Future<void> deleteEntries(List<String> ids) async {
    for (final id in ids) {
      await deleteEntry(id);
    }
  }

  /// 複数エントリのカテゴリを一括更新する。
  Future<void> setCategoryForEntries(List<String> ids, String? categoryId) {
    return batch((batch) {
      for (final id in ids) {
        batch.update(
          qrEntries,
          QrEntriesCompanion(categoryId: Value(categoryId)),
          where: (table) => table.id.equals(id),
        );
      }
    });
  }

  /// テキスト検索（名前・説明・タグ名にマッチ）。指定 DB スコープ。
  Future<List<QrEntry>> searchEntries(String query, {String? databaseId}) {
    final pattern = '%$query%';
    // タグ名でもヒットさせるため LEFT JOIN で tags を結合
    final q = select(qrEntries).join([
      leftOuterJoin(entryTags, entryTags.entryId.equalsExp(qrEntries.id)),
      leftOuterJoin(tags, tags.id.equalsExp(entryTags.tagId)),
    ]);

    Expression<bool> condition =
        qrEntries.name.like(pattern) |
        qrEntries.description.like(pattern) |
        tags.name.like(pattern);

    if (databaseId != null) {
      condition = condition & qrEntries.databaseId.equals(databaseId);
    }

    q
      ..where(condition)
      ..groupBy([qrEntries.id])
      ..orderBy([OrderingTerm.desc(qrEntries.updatedAt)]);

    return q.map((r) => r.readTable(qrEntries)).get();
  }

  /// Search entries that have ALL of the specified tag IDs.
  Future<List<QrEntry>> searchByTags(
    List<String> tagIds, {
    String? databaseId,
  }) async {
    if (tagIds.isEmpty) return getAllEntries();

    final query = select(
      qrEntries,
    ).join([innerJoin(entryTags, entryTags.entryId.equalsExp(qrEntries.id))]);

    Expression<bool> condition = entryTags.tagId.isIn(tagIds);
    if (databaseId != null) {
      condition = condition & qrEntries.databaseId.equals(databaseId);
    }

    query
      ..where(condition)
      ..groupBy([
        qrEntries.id,
      ], having: entryTags.tagId.count().equals(tagIds.length));

    final rows = await query.get();
    return rows.map((r) => r.readTable(qrEntries)).toList();
  }

  /// 複合検索: テキスト + タグ + QR 登録状態フィルタ。指定 DB スコープ。
  Future<List<QrEntry>> searchEntriesWithTags(
    String? textQuery,
    List<String> tagIds, {
    String? databaseId,
    bool? hasQrData,
  }) async {
    if (tagIds.isEmpty &&
        (textQuery == null || textQuery.isEmpty) &&
        databaseId == null &&
        hasQrData == null) {
      return getAllEntries();
    }

    // テキスト検索がありタグなしの場合、タグ名検索も含める
    if (tagIds.isEmpty && textQuery != null && textQuery.isNotEmpty) {
      final pattern = '%$textQuery%';
      final q = select(qrEntries).join([
        leftOuterJoin(entryTags, entryTags.entryId.equalsExp(qrEntries.id)),
        leftOuterJoin(tags, tags.id.equalsExp(entryTags.tagId)),
      ]);

      Expression<bool> condition =
          qrEntries.name.like(pattern) |
          qrEntries.description.like(pattern) |
          tags.name.like(pattern);

      if (databaseId != null) {
        condition = condition & qrEntries.databaseId.equals(databaseId);
      }
      if (hasQrData == true) {
        condition = condition & qrEntries.dataSize.isBiggerThanValue(0);
      } else if (hasQrData == false) {
        condition = condition & qrEntries.dataSize.equals(0);
      }

      q
        ..where(condition)
        ..groupBy([qrEntries.id])
        ..orderBy([OrderingTerm.desc(qrEntries.updatedAt)]);

      return q.map((r) => r.readTable(qrEntries)).get();
    }

    // タグありの場合
    final pattern = textQuery != null && textQuery.isNotEmpty
        ? '%$textQuery%'
        : null;

    final query = select(
      qrEntries,
    ).join([innerJoin(entryTags, entryTags.entryId.equalsExp(qrEntries.id))]);

    Expression<bool> condition = entryTags.tagId.isIn(tagIds);
    if (pattern != null) {
      condition =
          condition &
          (qrEntries.name.like(pattern) | qrEntries.description.like(pattern));
    }
    if (databaseId != null) {
      condition = condition & qrEntries.databaseId.equals(databaseId);
    }
    if (hasQrData == true) {
      condition = condition & qrEntries.dataSize.isBiggerThanValue(0);
    } else if (hasQrData == false) {
      condition = condition & qrEntries.dataSize.equals(0);
    }

    query
      ..where(condition)
      ..groupBy([
        qrEntries.id,
      ], having: entryTags.tagId.count().equals(tagIds.length))
      ..orderBy([OrderingTerm.desc(qrEntries.updatedAt)]);

    final rows = await query.get();
    return rows.map((r) => r.readTable(qrEntries)).toList();
  }

  /// Get tags for a specific entry.
  Future<List<Tag>> getTagsForEntry(String entryId) {
    final query = select(tags).join([
      innerJoin(entryTags, entryTags.tagId.equalsExp(tags.id)),
    ])..where(entryTags.entryId.equals(entryId));

    return query.map((r) => r.readTable(tags)).get();
  }

  /// Set tags for an entry (replaces existing).
  Future<void> setTagsForEntry(String entryId, List<String> tagIds) async {
    await (delete(entryTags)..where((t) => t.entryId.equals(entryId))).go();
    await batch((b) {
      b.insertAll(
        entryTags,
        tagIds.map(
          (tagId) => EntryTagsCompanion.insert(entryId: entryId, tagId: tagId),
        ),
      );
    });
  }
}
