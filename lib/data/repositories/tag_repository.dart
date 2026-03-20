import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/qr_entry_model.dart';

/// タグの取得・作成・削除を提供するリポジトリ。
///
/// [TagDao] をラップし、ドメインモデル ([TagModel]) への変換を行う。
/// タグはデータベース単位でスコープされる。
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  /// 全タグを取得する。[databaseId] 指定時はそのDBのみ。
  Future<List<TagModel>> getAllTags({String? databaseId}) async {
    final List<Tag> tags;
    if (databaseId != null) {
      tags = await _db.tagDao.getTagsByDatabase(databaseId);
    } else {
      tags = await _db.tagDao.getAllTags();
    }
    return tags
        .map(
          (t) => TagModel(
            id: t.id,
            databaseId: t.databaseId,
            name: t.name,
            color: t.color,
          ),
        )
        .toList();
  }

  /// 指定データベースのタグを監視する。
  Stream<List<TagModel>> watchTagsByDatabase(String databaseId) {
    return _db.tagDao
        .watchTagsByDatabase(databaseId)
        .map(
          (tags) => tags
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

  Stream<List<TagModel>> watchAllTags() {
    return _db.tagDao.watchAllTags().map(
      (tags) => tags
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

  Future<TagModel> createTag({
    required String name,
    int? color,
    String databaseId = 'default',
  }) async {
    final tag = await _db.tagDao.getOrCreateTag(
      name,
      color: color,
      databaseId: databaseId,
    );
    return TagModel(
      id: tag.id,
      databaseId: tag.databaseId,
      name: tag.name,
      color: tag.color,
    );
  }

  Future<void> deleteTag(String id) => _db.tagDao.deleteTag(id);

  /// タグ名を更新する。
  Future<void> updateTagName(String id, String newName) async {
    await _db.tagDao.updateTag(
      TagsCompanion(id: Value(id), name: Value(newName)),
    );
  }
}
