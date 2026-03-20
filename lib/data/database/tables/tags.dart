import 'package:drift/drift.dart';

import 'qr_databases.dart';

/// タグテーブル。エントリを分類するためのラベルを管理する。
///
/// タグはデータベース単位で管理される。同名タグでもデータベースが異なれば別物。
class Tags extends Table {
  TextColumn get id => text()();

  /// 所属するデータベースの ID。
  TextColumn get databaseId => text()
      .withDefault(const Constant('default'))
      .references(QrDatabases, #id)();

  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get color => integer().withDefault(const Constant(0xFF6750A4))();

  @override
  Set<Column> get primaryKey => {id};
}
