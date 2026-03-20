import 'package:drift/drift.dart';

import 'qr_entries.dart';
import 'tags.dart';

/// エントリとタグの多対多関係を管理する中間テーブル。

@DataClassName('EntryTag')
class EntryTags extends Table {
  TextColumn get entryId => text().references(QrEntries, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {entryId, tagId};
}
