import 'dart:async';
import 'package:tro/models/filiation.dart';
import 'package:tro/models/parameters.dart';

import '../database/database.dart';

class FiliationDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records
  Future<int> save(Filiation data) async {
    final db = await dbProvider.database;
    var result = db.insert("filiation", data.toDatabaseJson());
    return result;
  }

  Future<Filiation?> findById(int id) async {
    final db = await dbProvider.database;
    var data = await db.query('filiation', where: 'id = ?', whereArgs: [id]);
    List<Filiation> liste = data.isNotEmpty
        ? data.map((c) => Filiation.fromDatabaseJson(c)).toList()
        : [];
    return liste.isEmpty ? null : liste.first;
  }

  Future<int> update(Filiation data) async {
    final db = await dbProvider.database;
    var result = await db.update("filiation", data.toDatabaseJson(),
        where: "id = ?", whereArgs: [data.id]);
    return result;
  }

  Future<int> deleteAllFiliations() async {
    final db = await dbProvider.database;
    var result = await db.delete(
      "filiation",
    );
    return result;
  }
}