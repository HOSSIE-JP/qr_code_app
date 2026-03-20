import 'package:drift/drift.dart';

import 'categories.dart';
import 'qr_databases.dart';

/// QRエントリのメインテーブル。
///
/// [originalData] が空（長さ 0）の場合は QR コード未登録のエントリとして扱う。
/// テキストモード（[isTextMode] = true）の場合、[originalData] には
/// UTF-8 エンコードされたプレーンテキストが格納され、
/// QR コードにはそのまま文字列として書き込まれる。
/// バイナリモードでは base64 エンコードした標準 QR コードとして扱う。
class QrEntries extends Table {
  TextColumn get id => text()();

  /// 所属するデータベースの ID。
  TextColumn get databaseId => text()
      .withDefault(const Constant('default'))
      .references(QrDatabases, #id)();

  /// 所属カテゴリの ID。未設定時は null。
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withDefault(const Constant(''))();

  /// QR コードの元データ。空の場合は QR 未登録。
  BlobColumn get originalData => blob()();
  IntColumn get dataSize => integer()();

  /// レガシー: チャンク数。v4 以降は常に 1。
  IntColumn get chunkCount => integer().withDefault(const Constant(1))();

  /// テキストモードかどうか。
  /// true の場合、originalData は UTF-8 テキストとして扱い、
  /// QR コードにもプレーンテキストとして格納する。
  BoolColumn get isTextMode => boolean().withDefault(const Constant(false))();

  /// お気に入りフラグ。ホーム画面で優先表示される。
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  BlobColumn get thumbnail => blob().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
