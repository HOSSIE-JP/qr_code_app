import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';
import '../tables/qr_entries.dart';

part 'category_dao.g.dart';

/// カテゴリの CRUD 操作と並び順更新を行う DAO。
@DriftAccessor(tables: [Categories, QrEntries])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// 指定データベースのカテゴリを表示順で取得する。
  Future<List<Category>> getCategoriesByDatabase(String databaseId) =>
      (select(categories)
            ..where((t) => t.databaseId.equals(databaseId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  /// 指定データベースのカテゴリを表示順で監視する。
  Stream<List<Category>> watchCategoriesByDatabase(String databaseId) =>
      (select(categories)
            ..where((t) => t.databaseId.equals(databaseId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  Future<void> updateCategory(CategoriesCompanion category) => (update(
    categories,
  )..where((t) => t.id.equals(category.id.value))).write(category);

  /// カテゴリ削除時は紐づくエントリの categoryId を null に戻す。
  Future<void> deleteCategory(String id) async {
    await (update(qrEntries)..where((t) => t.categoryId.equals(id))).write(
      const QrEntriesCompanion(categoryId: Value(null)),
    );
    await (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  /// 指定データベース内のカテゴリ順を一括更新する。
  Future<void> updateSortOrders(String databaseId, List<String> orderedIds) {
    return batch((batch) {
      for (var index = 0; index < orderedIds.length; index++) {
        final id = orderedIds[index];
        batch.update(
          categories,
          CategoriesCompanion(sortOrder: Value(index)),
          where: (table) =>
              table.id.equals(id) & table.databaseId.equals(databaseId),
        );
      }
    });
  }
}
