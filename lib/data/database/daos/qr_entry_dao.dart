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

  /// 指定データベースの一覧表示向けエントリを監視する。
  ///
  /// `originalData` の BLOB 列を読み込まず、初期描画を軽量化する。
  Stream<List<QrEntry>> watchEntrySummariesByDatabase(String databaseId) {
    final query =
        (selectOnly(qrEntries)
              ..addColumns(_summaryColumns)
              ..where(qrEntries.databaseId.equals(databaseId))
              ..orderBy([OrderingTerm.desc(qrEntries.updatedAt)]))
            .watch();

    return query.map(
      (rows) => rows.map(_toSummaryEntry).toList(growable: false),
    );
  }

  Stream<List<QrEntry>> watchAllEntries() => (select(
    qrEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<QrEntry?> getEntryById(String id) =>
      (select(qrEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 指定データベース内で名称が一致するエントリを取得する。
  Future<QrEntry?> getEntryByNameInDatabase(String databaseId, String name) =>
      (select(qrEntries)..where(
            (t) => t.databaseId.equals(databaseId) & t.name.equals(name),
          ))
          .getSingleOrNull();

  /// 指定データベース内で名称が一致するエントリIDを取得する。
  ///
  /// BLOB 列を含む全カラムを読み込まず、軽量に存在確認を行う用途向け。
  Future<String?> getEntryIdByNameInDatabase(
    String databaseId,
    String name,
  ) async {
    final row =
        await (selectOnly(qrEntries)
              ..addColumns([qrEntries.id])
              ..where(
                qrEntries.databaseId.equals(databaseId) &
                    qrEntries.name.equals(name),
              )
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return row.read(qrEntries.id);
  }

  /// 指定データベースのエントリ名とIDの対応表を取得する。
  ///
  /// インポート時の重複判定用に、BLOB列を含まない最小カラムのみを読み込む。
  Future<Map<String, String>> getEntryNameIdMapByDatabase(
    String databaseId,
  ) async {
    final rows =
        await (selectOnly(qrEntries)
              ..addColumns([qrEntries.id, qrEntries.name])
              ..where(qrEntries.databaseId.equals(databaseId)))
            .get();

    final result = <String, String>{};
    for (final row in rows) {
      final id = row.read(qrEntries.id);
      final name = row.read(qrEntries.name);
      if (id == null || name == null || name.isEmpty) {
        continue;
      }
      result.putIfAbsent(name, () => id);
    }
    return result;
  }

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
    // タグ指定がない場合は、テキスト有無で検索経路を切り替える。
    if (tagIds.isEmpty) {
      // テキスト検索がある場合はタグ名検索も含めるため JOIN する。
      if (textQuery != null && textQuery.isNotEmpty) {
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

      // テキスト検索がない場合は単純な一覧/フィルタとして扱う。
      final query = select(qrEntries);
      Expression<bool>? condition;
      if (databaseId != null) {
        condition = qrEntries.databaseId.equals(databaseId);
      }
      if (hasQrData == true) {
        final c = qrEntries.dataSize.isBiggerThanValue(0);
        condition = condition == null ? c : condition & c;
      } else if (hasQrData == false) {
        final c = qrEntries.dataSize.equals(0);
        condition = condition == null ? c : condition & c;
      }
      if (condition != null) {
        query.where((_) => condition!);
      }
      query.orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
      return query.get();
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

  /// 指定データベースの一覧表示向けエントリを取得する。
  ///
  /// `originalData` の BLOB 列を除外し、初期表示を軽量化する。
  Future<List<QrEntry>> getEntrySummariesByDatabase(
    String databaseId, {
    bool? hasQrData,
  }) async {
    final query =
        (selectOnly(qrEntries)
              ..addColumns(_summaryColumns)
              ..where(
                qrEntries.databaseId.equals(databaseId) &
                    _hasQrDataCondition(hasQrData),
              )
              ..orderBy([OrderingTerm.desc(qrEntries.updatedAt)]))
            .get();
    final rows = await query;
    return rows.map(_toSummaryEntry).toList(growable: false);
  }

  /// 一覧向け軽量取得で使うカラム一覧。
  List<GeneratedColumn<Object>> get _summaryColumns =>
      <GeneratedColumn<Object>>[
        qrEntries.id,
        qrEntries.databaseId,
        qrEntries.categoryId,
        qrEntries.name,
        qrEntries.description,
        qrEntries.dataSize,
        qrEntries.chunkCount,
        qrEntries.isTextMode,
        qrEntries.isFavorite,
        qrEntries.thumbnail,
        qrEntries.createdAt,
        qrEntries.updatedAt,
      ];

  /// QR 登録状態フィルタの条件式を返す。
  Expression<bool> _hasQrDataCondition(bool? hasQrData) {
    if (hasQrData == true) {
      return qrEntries.dataSize.isBiggerThanValue(0);
    }
    if (hasQrData == false) {
      return qrEntries.dataSize.equals(0);
    }
    return const Constant(true);
  }

  /// 軽量クエリ結果を [QrEntry] へ変換する。
  QrEntry _toSummaryEntry(TypedResult row) {
    return QrEntry(
      id: row.read(qrEntries.id)!,
      databaseId: row.read(qrEntries.databaseId)!,
      categoryId: row.read(qrEntries.categoryId),
      name: row.read(qrEntries.name)!,
      description: row.read(qrEntries.description)!,
      originalData: Uint8List(0),
      dataSize: row.read(qrEntries.dataSize)!,
      chunkCount: row.read(qrEntries.chunkCount)!,
      isTextMode: row.read(qrEntries.isTextMode)!,
      isFavorite: row.read(qrEntries.isFavorite)!,
      thumbnail: row.read(qrEntries.thumbnail),
      createdAt: row.read(qrEntries.createdAt)!,
      updatedAt: row.read(qrEntries.updatedAt)!,
    );
  }

  /// Get tags for a specific entry.
  Future<List<Tag>> getTagsForEntry(String entryId) async {
    final entry = await getEntryById(entryId);
    if (entry == null) {
      return const <Tag>[];
    }

    final query =
        select(tags).join([
          innerJoin(entryTags, entryTags.tagId.equalsExp(tags.id)),
        ])..where(
          entryTags.entryId.equals(entryId) &
              tags.databaseId.equals(entry.databaseId),
        );

    return query.map((r) => r.readTable(tags)).get();
  }

  /// Set tags for an entry (replaces existing).
  Future<void> setTagsForEntry(String entryId, List<String> tagIds) async {
    final entry = await getEntryById(entryId);
    if (entry == null) {
      return;
    }

    await (delete(entryTags)..where((t) => t.entryId.equals(entryId))).go();

    if (tagIds.isEmpty) {
      return;
    }

    final validTags =
        await (select(tags)..where(
              (t) => t.id.isIn(tagIds) & t.databaseId.equals(entry.databaseId),
            ))
            .get();
    final validTagIds = validTags.map((tag) => tag.id).toSet();
    final filteredTagIds = tagIds
        .where(validTagIds.contains)
        .toList(growable: false);

    if (filteredTagIds.isEmpty) {
      return;
    }

    await batch((b) {
      b.insertAll(
        entryTags,
        filteredTagIds.map(
          (tagId) => EntryTagsCompanion.insert(entryId: entryId, tagId: tagId),
        ),
      );
    });
  }
}
