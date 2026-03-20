import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/entry_tags.dart';
import '../tables/tags.dart';

part 'tag_dao.g.dart';

/// タグの CRUD 操作を行う DAO。
///
/// [getOrCreateTag] で同名・同 DB のタグが存在する場合は既存を返し、重複を防ぐ。
@DriftAccessor(tables: [Tags, EntryTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Future<List<Tag>> getAllTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  /// 指定データベースの全タグを取得する。
  Future<List<Tag>> getTagsByDatabase(String databaseId) =>
      (select(tags)
            ..where((t) => t.databaseId.equals(databaseId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// 指定データベースのタグ一覧を監視する。
  Stream<List<Tag>> watchTagsByDatabase(String databaseId) =>
      (select(tags)
            ..where((t) => t.databaseId.equals(databaseId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Stream<List<Tag>> watchAllTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<Tag?> getTagById(String id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Tag?> getTagByName(String name) =>
      (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();

  /// 指定 DB 内で同名タグを検索する。
  Future<Tag?> getTagByNameInDatabase(String name, String databaseId) =>
      (select(tags)..where(
            (t) => t.name.equals(name) & t.databaseId.equals(databaseId),
          ))
          .getSingleOrNull();

  Future<void> insertTag(TagsCompanion tag) => into(tags).insert(tag);

  Future<void> updateTag(TagsCompanion tag) =>
      (update(tags)..where((t) => t.id.equals(tag.id.value))).write(tag);

  /// タグを削除する。紐付いている EntryTags のレコードも先に削除する。
  Future<void> deleteTag(String id) async {
    await (delete(entryTags)..where((t) => t.tagId.equals(id))).go();
    await (delete(tags)..where((t) => t.id.equals(id))).go();
  }

  /// 指定 DB 内で名前からタグを検索し、存在しなければ新規作成して返す。
  Future<Tag> getOrCreateTag(
    String name, {
    int? color,
    String databaseId = 'default',
  }) async {
    final existing = await getTagByNameInDatabase(name, databaseId);
    if (existing != null) return existing;

    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final companion = TagsCompanion.insert(
      id: id,
      name: name,
      color: Value(color ?? 0xFF6750A4),
      databaseId: Value(databaseId),
    );
    await into(tags).insert(companion);
    return (await getTagById(id))!;
  }
}
