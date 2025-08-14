import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'model_class.dart';

class DBHelper {
  static Database? _db;
  static const String _tbl = 'favorites';

  static Future<Database> init() async {
    if (_db != null) return _db!;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, 'coffee_favs.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE $_tbl (
          id TEXT PRIMARY KEY,
          name TEXT,
          lat REAL,
          lng REAL
        )
      ''');
    });
    return _db!;
  }

  static Future<void> addFavorite(CoffeeShop shop) async {
    final db = await init();
    await db.insert(_tbl, shop.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> removeFavorite(String id) async {
    final db = await init();
    await db.delete(_tbl, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<CoffeeShop>> allFavorites() async {
    final db = await init();
    final res = await db.query(_tbl);
    return res.map((e) => CoffeeShop.fromMap(e)).toList();
  }

  static Future<bool> isFavorite(String id) async {
    final db = await init();
    final res = await db.query(_tbl, where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty;
  }
}
