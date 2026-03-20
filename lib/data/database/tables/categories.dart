import 'package:drift/drift.dart';

import 'qr_databases.dart';

/// カテゴリテーブル。エントリを大分類するための情報を保持する。
class Categories extends Table {
  TextColumn get id => text()();

  /// 所属するデータベースの ID。
  TextColumn get databaseId => text()
      .withDefault(const Constant('default'))
      .references(QrDatabases, #id)();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// 同一 DB 内での表示順。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
