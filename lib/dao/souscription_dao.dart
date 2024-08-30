import 'dart:async';

import '../database/database.dart';
import '../models/souscription.dart';

class SouscriptionDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records
  Future<int> insert(Souscription data) async {
    final db = await dbProvider.database;
    var result = db.rawInsert("""
    INSERT INTO souscription (idpub, iduser, millisecondes, reserve) VALUES (?, ?, ?, ?)""",
        [data.idpub, data.iduser, data.millisecondes, data.reserve]);
    return result;
  }

  Future<int> update(Souscription data) async {
    final db = await dbProvider.database;
    var result = await db.update("souscription", data.toDatabaseJson(),
        where: "id = ?", whereArgs: [data.id]);
    return result;
  }

  Future<List<Souscription>> findAllByIdpub(int idpub) async {
    final db = await dbProvider.database;
    var data = await db.query('souscription', where: 'idpub = ?', whereArgs: [idpub]);
    List<Souscription> liste = data.isNotEmpty
        ? data.map((c) => Souscription.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

}