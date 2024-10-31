import 'dart:async';

import 'package:tro/models/cible.dart';

import '../database/database.dart';

class CibleDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records

  Future<int> insert(Cible data) async {
    final db = await dbProvider.database;
    var result = db.insert("cible", data.toDatabaseJson());
    return result;
  }

  Future<int> update(Cible data) async {
    final db = await dbProvider.database;
    var result = await db.update("cible", data.toDatabaseJson(),
        where: "id = ?", whereArgs: [data.id]);
    return result;
  }

  Future<Cible> findById(int id) async {
    final db = await dbProvider.database;
    var data = await db.query('cible', where: 'id = ?', whereArgs: [id]);
    List<Cible> liste = data.isNotEmpty
        ? data.map((c) => Cible.fromDatabaseJson(c)).toList()
        : [];
    return liste.first;
  }

  Future<List<Cible>> findAll() async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> results = await db.query('cible');

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
      'id': id as int,
      'villedepartid': villedepartid as int,
      'paysdepartid': paysdepartid as int,
      'villedestid': villedestid as int,
      'paysdestid': paysdestid as int,
      'topic': topic as String,
      } in results)
        Cible(id: id, villedepartid: villedepartid, paysdepartid: paysdepartid, villedestid: villedestid, paysdestid: paysdestid,
            topic: topic)
    ];
  }

  Future<int> deleteAllCibles() async {
    final db = await dbProvider.database;
    var result = await db.delete(
      "cible",
    );
    return result;
  }
}