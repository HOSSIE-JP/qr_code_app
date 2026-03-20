// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $QrDatabasesTable get qrDatabases => attachedDatabase.qrDatabases;
  $CategoriesTable get categories => attachedDatabase.categories;
  $QrEntriesTable get qrEntries => attachedDatabase.qrEntries;
  CategoryDaoManager get managers => CategoryDaoManager(this);
}

class CategoryDaoManager {
  final _$CategoryDaoMixin _db;
  CategoryDaoManager(this._db);
  $$QrDatabasesTableTableManager get qrDatabases =>
      $$QrDatabasesTableTableManager(_db.attachedDatabase, _db.qrDatabases);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$QrEntriesTableTableManager get qrEntries =>
      $$QrEntriesTableTableManager(_db.attachedDatabase, _db.qrEntries);
}
