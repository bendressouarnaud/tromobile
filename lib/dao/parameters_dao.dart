import 'dart:async';
import 'package:tro/models/parameters.dart';

import '../database/database.dart';

class ParametersDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records
  Future<Parameters?> findById(int id) async {
    final db = await dbProvider.database;
    var data = await db.query('parameters', where: 'id = ?', whereArgs: [id]);
    List<Parameters> liste = data.isNotEmpty
        ? data.map((c) => Parameters.fromDatabaseJson(c)).toList()
        : [];
    return liste.isEmpty ? null : liste.first;
  }

  Future<int> update(Parameters data) async {
    final db = await dbProvider.database;
    var result = await db.update("parameters", data.toDatabaseJson(),
        where: "id = ?", whereArgs: [data.id]);
    return result;
  }
}