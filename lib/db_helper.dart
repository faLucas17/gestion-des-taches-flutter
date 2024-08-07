import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""
    CREATE TABLE DATA(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      title TEXT,
      desc TEXT,
      startDate TEXT,
      endDate TEXT,
      status TEXT,
      createAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """);
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase("database_name.db", version: 2,
        onCreate: (sql.Database database, int version) async {
          await createTables(database);
        });
  }

  static Future<int> createData(
      String title, String? desc, DateTime startDate, DateTime endDate, String status) async {
    final db = await SQLHelper.db();
    final data = {
      'title': title,
      'desc': desc,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
    };
    final id = await db.insert('DATA', data, conflictAlgorithm: sql.ConflictAlgorithm.ignore);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getAllData() async {
    final db = await SQLHelper.db();
    return db.query('DATA', orderBy: 'id');
  }

  static Future<List<Map<String, dynamic>>> getSingleData(int id) async {
    final db = await SQLHelper.db();
    return db.query('DATA', where: "id = ?", whereArgs: [id], limit: 1);
  }


  static Future<int> updateData(int id, String title, String? desc) async {
    final db = await SQLHelper.db();
    final data = {
      'title': title,
      'desc': desc,
      'createAt': DateTime.now().toIso8601String(),
    };
    final result = await db.update('DATA', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<void> deleteData(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete('DATA', where: "id = ?", whereArgs: [id]);
    } catch (e) {
      print("Error deleting data: $e");
    }
  }
}