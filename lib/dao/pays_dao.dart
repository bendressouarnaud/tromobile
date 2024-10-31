import 'dart:async';

import '../database/database.dart';
import '../models/pays.dart';

class PaysDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records
  /*Future<int> insert(Pays ps) async {
    final db = await dbProvider.database;
    var result = db.rawInsert("""
    INSERT INTO pays (name, iso2, iso3, unicodeFlag) VALUES (?, ?, ?, ?)""",
        [ps.name, ps.iso2, ps.iso3, ps.unicodeFlag]);
    return result;
  }*/

  Future<int> insert(Pays ps) async {
    final db = await dbProvider.database;
    var result = db.insert("pays", ps.toDatabaseJson());
    return result;
  }

  Future<Pays> findPaysByIso(String iso2) async {
    final db = await dbProvider.database;
    var pays = await db.query('pays', where: 'iso2 = ?', whereArgs: [iso2]);
    List<Pays> liste = pays.isNotEmpty
        ? pays.map((c) => Pays.fromDatabaseJson(c)).toList()
        : [];
    return liste.first;
  }

  Future<Pays> findPaysById(int id) async {
    final db = await dbProvider.database;
    var pays = await db.query('pays', where: 'id = ?', whereArgs: [id]);
    List<Pays> liste = pays.isNotEmpty
        ? pays.map((c) => Pays.fromDatabaseJson(c)).toList()
        : [];
    return liste.first;
  }

  Future<List<Pays>> findAll() async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> results = await db.query('pays');
    //final List<Map<String, Object?>> results = await db.query('pays', orderBy: "name ASC");

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
      'id': id as int,
      'name': name as String,
      'iso2': iso2 as String,
      'iso3': iso3 as String,
      'unicodeFlag': unicodeFlag as String,
      } in results)
        Pays(id: id, name: name, iso2: iso2, iso3: iso3, unicodeFlag: unicodeFlag)
    ];
  }
}