import 'dart:async';

import '../database/database.dart';
import '../models/souscription.dart';

class SouscriptionDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records
  Future<int> insert(Souscription data) async {
    final db = await dbProvider.database;
    var result = db.rawInsert("""
    INSERT INTO souscription (idpub, iduser, millisecondes, reserve, statut, streamchannelid) VALUES (?, ?, ?, ?, ?, ?)""",
        [data.idpub, data.iduser, data.millisecondes, data.reserve, data.statut, data.streamchannelid]);
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

  Future<Souscription?> findOptionalByStreamChannel(String iD) async {
    final db = await dbProvider.database;
    var souscriptions = await db.query('souscription', where: 'streamchannelid = ?', whereArgs: [iD]);
    List<Souscription> liste = souscriptions.isNotEmpty
        ? souscriptions.map((c) => Souscription.fromDatabaseJson(c)).toList()
        : [];
    return liste.isNotEmpty ? liste.first : null;
  }

  Future<List<Souscription>> findAllWithStreamId() async {
    final db = await dbProvider.database;
    var souscriptions = await db.query('souscription', where: "streamchannelid <> ''");
    List<Souscription> liste = souscriptions.isNotEmpty
        ? souscriptions.map((c) => Souscription.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

  Future<Souscription> findByIdpubAndIduser(int idpub, int iduser) async {
    final db = await dbProvider.database;
    var data = await db.query('souscription', where: 'idpub = ? and iduser = ?', whereArgs: [idpub, iduser]);
    List<Souscription> liste = data.isNotEmpty
        ? data.map((c) => Souscription.fromDatabaseJson(c)).toList()
        : [];
    return liste.single;
  }

  Future<int> deleteAllSouscriptions() async {
    final db = await dbProvider.database;
    var result = await db.delete(
      "souscription",
    );
    return result;
  }
}