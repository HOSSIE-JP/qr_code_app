// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$QrEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $QrDatabasesTable get qrDatabases => attachedDatabase.qrDatabases;
  $CategoriesTable get categories => attachedDatabase.categories;
  $QrEntriesTable get qrEntries => attachedDatabase.qrEntries;
  $TagsTable get tags => attachedDatabase.tags;
  $EntryTagsTable get entryTags => attachedDatabase.entryTags;
  QrEntryDaoManager get managers => QrEntryDaoManager(this);
}

class QrEntryDaoManager {
  final _$QrEntryDaoMixin _db;
  QrEntryDaoManager(this._db);
  $$QrDatabasesTableTableManager get qrDatabases =>
      $$QrDatabasesTableTableManager(_db.attachedDatabase, _db.qrDatabases);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$QrEntriesTableTableManager get qrEntries =>
      $$QrEntriesTableTableManager(_db.attachedDatabase, _db.qrEntries);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$EntryTagsTableTableManager get entryTags =>
      $$EntryTagsTableTableManager(_db.attachedDatabase, _db.entryTags);
}
