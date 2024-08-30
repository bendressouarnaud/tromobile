import 'dart:async';

import 'package:tro/models/chat.dart';

import '../database/database.dart';

class ChatDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records

  /*Future<int> insert(Chat data) async {
    final db = await dbProvider.database;
    var result = db.insert("chat", data.toDatabaseJson());
    return result;
  }*/

  Future<int> insert(Chat data) async {
    final db = await dbProvider.database;
    var result = db.rawInsert("""
    INSERT INTO chat (idpub, milliseconds, sens, statut, contenu, identifiant, iduser, idlocaluser) VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
        [data.idpub, data.milliseconds, data.sens, data.statut, data.contenu, data.identifiant, data.iduser, data.idlocaluser]);
    return result;
  }

  Future<int> update(Chat data) async {
    final db = await dbProvider.database;
    var result = await db.update("chat", data.toDatabaseJson(),
        where: "id = ?", whereArgs: [data.id]);
    return result;
  }

  Future<Chat> findById(int id) async {
    final db = await dbProvider.database;
    var data = await db.query('chat', where: 'id = ?', whereArgs: [id]);
    List<Chat> liste = data.isNotEmpty
        ? data.map((c) => Chat.fromDatabaseJson(c)).toList()
        : [];
    return liste.first;
  }

  Future<Chat> findByIdentifiant(String id) async {
    final db = await dbProvider.database;
    var data = await db.query('chat', where: 'identifiant = ?', whereArgs: [id]);
    List<Chat> liste = data.isNotEmpty
        ? data.map((c) => Chat.fromDatabaseJson(c)).toList()
        : [];
    return liste.first;
  }

  Future<List<Chat>> findAllBy(int idpub) async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> results = await db.query('chat', where: 'idpub = ?', whereArgs: [idpub]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
      'id': id as int,
      'idpub': idpub as int,
      'milliseconds': milliseconds as int,
      'sens': sens as int,
      'statut': statut as int,
      'contenu': contenu as String,
      'identifiant': identifiant as String,
      'iduser': iduser as int,
      'idlocaluser': idlocaluser as int,
      } in results)
        Chat(id: id, idpub: idpub, milliseconds: milliseconds, sens: sens,statut: statut, contenu: contenu, identifiant: identifiant, iduser: iduser,
            idlocaluser: idlocaluser)
    ];
  }

  Future<List<Chat>> findAllByIdpubAndIduser(int idpub,int iduser, int idlocaluser) async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> results = await db.query('chat', where: 'idpub = ? and iduser = ? and idlocaluser = ?',
        whereArgs: [idpub, iduser, idlocaluser]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
      'id': id as int,
      'idpub': idpub as int,
      'milliseconds': milliseconds as int,
      'sens': sens as int,
      'statut': statut as int,
      'contenu': contenu as String,
      'identifiant': identifiant as String,
      'iduser': iduser as int,
      'idlocaluser': idlocaluser as int
      } in results)
        Chat(id: id, idpub: idpub, milliseconds: milliseconds, sens: sens,statut: statut, contenu: contenu,
            identifiant: identifiant, iduser: iduser, idlocaluser: idlocaluser)
    ];
  }

  Future<List<Chat>> findAllByStatut(int statut) async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> results = await db.query('chat', where: 'statut = ?', whereArgs: [statut]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
      'id': id as int,
      'idpub': idpub as int,
      'milliseconds': milliseconds as int,
      'sens': sens as int,
      'statut': statut as int,
      'contenu': contenu as String,
      'identifiant': identifiant as String,
      'iduser': iduser as int,
      'idlocaluser': idlocaluser as int
      } in results)
        Chat(id: id, idpub: idpub, milliseconds: milliseconds, sens: sens,statut: statut, contenu: contenu,
            identifiant: identifiant, iduser: iduser, idlocaluser: idlocaluser)
    ];
  }
}