import 'dart:async';

import '../database/database.dart';
import '../models/pays.dart';
import '../models/ville.dart';

class VilleDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records
  Future<int> insert(Ville data) async {
    final db = await dbProvider.database;
    var result = db.rawInsert("""
    INSERT INTO ville (name, paysid) VALUES (?, ?)""",
        [data.name, data.paysid]);
    return result;
  }

  Future<List<Ville>> findAll() async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> results = await db.query('ville');

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
      'id': id as int,
      'name': name as String,
      'paysid': paysid as int
      } in results)
        Ville(id: id, name: name, paysid: paysid)
    ];
  }

  Future<List<Ville>> findAllByPaysId(int paysId) async {
    final db = await dbProvider.database;
    var villes = await db.query('ville', where: 'paysid = ?', whereArgs: [paysId]);
    List<Ville> liste = villes.isNotEmpty
        ? villes.map((c) => Ville.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

  Future<Ville> findById(int id) async {
    final db = await dbProvider.database;
    var ville = await db.query('ville', where: 'id = ?', whereArgs: [id]);
    List<Ville> liste = ville.isNotEmpty
        ? ville.map((c) => Ville.fromDatabaseJson(c)).toList()
        : [];
    return liste.first;
  }
}