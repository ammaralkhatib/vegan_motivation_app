// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_dao.dart';

// ignore_for_file: type=lint
mixin _$QuoteDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $QuotesTable get quotes => attachedDatabase.quotes;
  QuoteDaoManager get managers => QuoteDaoManager(this);
}

class QuoteDaoManager {
  final _$QuoteDaoMixin _db;
  QuoteDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$QuotesTableTableManager get quotes =>
      $$QuotesTableTableManager(_db.attachedDatabase, _db.quotes);
}
