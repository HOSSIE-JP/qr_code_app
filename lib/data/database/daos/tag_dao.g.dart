// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_dao.dart';

// ignore_for_file: type=lint
mixin _$TagDaoMixin on DatabaseAccessor<AppDatabase> {
  $QrDatabasesTable get qrDatabases => attachedDatabase.qrDatabases;
  $TagsTable get tags => attachedDatabase.tags;
  $CategoriesTable get categories => attachedDatabase.categories;
  $QrEntriesTable get qrEntries => attachedDatabase.qrEntries;
  $EntryTagsTable get entryTags => attachedDatabase.entryTags;
  TagDaoManager get managers => TagDaoManager(this);
}

class TagDaoManager {
  final _$TagDaoMixin _db;
  TagDaoManager(this._db);
  $$QrDatabasesTableTableManager get qrDatabases =>
      $$QrDatabasesTableTableManager(_db.attachedDatabase, _db.qrDatabases);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$QrEntriesTableTableManager get qrEntries =>
      $$QrEntriesTableTableManager(_db.attachedDatabase, _db.qrEntries);
  $$EntryTagsTableTableManager get entryTags =>
      $$EntryTagsTableTableManager(_db.attachedDatabase, _db.entryTags);
}
