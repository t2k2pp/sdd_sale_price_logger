import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // Default tax rate in percent (e.g. 8 or 10)
  RealColumn get taxRate => real().withDefault(const Constant(10.0))();
}

class Shops extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get memo => text().nullable()();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get imagePath => text().nullable()();
  TextColumn get emoji => text().nullable()();
  RealColumn get volume => real().nullable()();
  TextColumn get volumeUnit => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Prices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get shopId => integer().references(Shops, #id)();
  IntColumn get price => integer()();
  // Whether the entered price includes tax
  BoolColumn get isTaxIncluded => boolean().withDefault(const Constant(true))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ShopEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shopId => integer().references(Shops, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  // 'recurring' or 'oneTime'
  TextColumn get eventType => text().withDefault(const Constant('recurring'))();
  // For recurring: day of week (1=Monday, 7=Sunday), nullable
  IntColumn get dayOfWeek => integer().nullable()();
  // For recurring: day of month (1-31), nullable
  IntColumn get dayOfMonth => integer().nullable()();
  // For one-time events: specific date
  DateTimeColumn get date => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Categories, Shops, Products, Prices, ShopEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(categories, categories.taxRate);
          await m.addColumn(prices, prices.isTaxIncluded);
        }
        if (from < 4) {
          await m.addColumn(products, products.emoji);
        }
        if (from < 5) {
          await m.addColumn(shops, shops.memo);
          await m.addColumn(products, products.volume);
          await m.addColumn(products, products.volumeUnit);
          await m.createTable(shopEvents);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
