import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/category_dao.dart';
import 'daos/qr_entry_dao.dart';
import 'daos/tag_dao.dart';
import 'tables/categories.dart';
import 'tables/entry_tags.dart';
import 'tables/qr_databases.dart';
import 'tables/qr_entries.dart';
import 'tables/tags.dart';

part 'app_database.g.dart';

/// Web 版 drift が読み込む sqlite3.wasm の配置パス。
const String driftSqliteWasmPath = 'sqlite3.wasm';

/// Web 版 drift が利用するワーカースクリプトの配置パス。
const String driftWorkerPath = 'drift_worker.js';

/// drift の Web 初期化オプションを返す。
///
/// `drift_flutter` 0.2.8 以降では Web 実行時に `web` オプション指定が必須。
DriftWebOptions createDriftWebOptions() {
  return DriftWebOptions(
    sqlite3Wasm: Uri.parse(driftSqliteWasmPath),
    driftWorker: Uri.parse(driftWorkerPath),
  );
}

/// アプリ全体で使用する drift データベース。
///
/// [schemaVersion] を上げるたびに [migration] にマイグレーションを追加する。
@DriftDatabase(
  tables: [QrDatabases, Categories, QrEntries, Tags, EntryTags],
  daos: [QrEntryDao, TagDao, CategoryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// デフォルトデータベースの固定 ID。
  static const defaultDatabaseId = 'default';

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // デフォルトデータベースを挿入
      await _insertDefaultDatabase();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: qr_entries テーブルに isTextMode カラムを追加
      if (from < 2) {
        await m.addColumn(qrEntries, qrEntries.isTextMode);
      }
      // v2 → v3: qr_entries テーブルに isFavorite カラムを追加
      if (from < 3) {
        await m.addColumn(qrEntries, qrEntries.isFavorite);
      }
      // v3 → v4: 複数データベース対応 + QR 未登録対応
      if (from < 4) {
        await m.createTable(qrDatabases);
        await _insertDefaultDatabase();
        await m.addColumn(qrEntries, qrEntries.databaseId);
        await m.addColumn(tags, tags.databaseId);
      }
      // v4 → v5: カテゴリ機能を追加
      if (from < 5) {
        await m.createTable(categories);
        await m.addColumn(qrEntries, qrEntries.categoryId);
      }
    },
  );

  /// デフォルトデータベースレコードを挿入する。
  Future<void> _insertDefaultDatabase() async {
    await into(qrDatabases).insertOnConflictUpdate(
      QrDatabasesCompanion.insert(
        id: defaultDatabaseId,
        name: 'デフォルト',
        description: const Value('既定のデータベース'),
      ),
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'qr_code_app', web: createDriftWebOptions());
  }
}
