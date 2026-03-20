import 'package:drift/drift.dart';

/// QR データベース（コレクション）テーブル。
///
/// エントリやタグを論理的にグループ化し、ホーム画面で切り替えて使う。
/// 既定のデータベース（id = 'default'）が 1 つ自動作成される。
class QrDatabases extends Table {
  /// データベースの一意識別子。
  TextColumn get id => text()();

  /// データベース名（ユーザーが設定する表示名）。
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// データベースの説明メモ。
  TextColumn get description => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
