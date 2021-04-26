import 'dart:convert';

import 'package:sqflite/sqflite.dart' as sql;

class Database {
  final sql.Database db;

  const Database._internal(this.db);

  Future<void> insert(Map<String, dynamic> data) async {
    var uuid = data.remove("uuid");
    await db.insert("Events", {"uuid": uuid, "data": jsonEncode(data)});
  }

  Future<void> update(Map<String, dynamic> data) async {
    var uuid = data.remove("uuid");
    await db.update(
      "Events",
      {"data": jsonEncode(data)},
      where: "uuid = ?",
      whereArgs: [uuid],
    );
  }

  Future<void> delete(String uuid) async {
    await db.delete("Events", where: "uuid = ?", whereArgs: [uuid]);
  }

  Future<Iterable<Map<String, dynamic>>> query() async {
    return await db.query("Events", columns: null).then(
          (value) => value.map((e) {
            Map<String, dynamic> data = jsonDecode(e["data"] as String);
            data["uuid"] = e["uuid"] as String;
            return data;
          }),
        );
  }
}

late final Database _database;
Database get database => _database;

Future<void> initDatabase() async {
  var db = await sql.openDatabase(
    'events.db',
    version: 2,
    onCreate: (sql.Database db, int newVersion) async {
      await db.transaction((txn) async {
        await txn.execute(
          "CREATE TABLE Events("
          "    uuid text NOT NULL PRIMARY KEY,"
          "    data text NOT NULL"
          ");",
        );
      });
    },
  );

  _database = Database._internal(db);
}
