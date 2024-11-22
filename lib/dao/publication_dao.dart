import 'dart:async';

import '../database/database.dart';
import '../models/publication.dart';

class PublicationDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records
  Future<int> insert(Publication data) async {
    final db = await dbProvider.database;
    var result = db.insert("publication", data.toDatabaseJson());
    return result;
  }

  Future<int> findSizeAll() async {
    final db = await dbProvider.database;
    var results = await db.rawQuery('SELECT * FROM publication');
    return results.length;
  }

  Future<Publication> findPublicationById(int id) async {
    final db = await dbProvider.database;
    var publications = await db.query('publication', where: 'id = ?', whereArgs: [id]);
    List<Publication> liste = publications.isNotEmpty
        ? publications.map((c) => Publication.fromDatabaseJson(c)).toList()
        : [];
    return liste.first;
  }

  Future<Publication?> findOptionalPublicationByStreamChannel(String iD) async {
    final db = await dbProvider.database;
    var publications = await db.query('publication', where: 'streamchannelid = ?', whereArgs: [iD]);
    List<Publication> liste = publications.isNotEmpty
        ? publications.map((c) => Publication.fromDatabaseJson(c)).toList()
        : [];
    return liste.isNotEmpty ? liste.first : null;
  }

  Future<List<Publication>> findAllWithStreamId() async {
    final db = await dbProvider.database;
    var publications = await db.query('publication', where: "streamchannelid <> ''");
    List<Publication> liste = publications.isNotEmpty
        ? publications.map((c) => Publication.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

  Future<Publication?> findOptionalPublicationById(int id) async {
    final db = await dbProvider.database;
    var publications = await db.query('publication', where: 'id = ?', whereArgs: [id]);
    List<Publication> liste = publications.isNotEmpty
        ? publications.map((c) => Publication.fromDatabaseJson(c)).toList()
        : [];
    return liste.isNotEmpty ? liste.first : null;
  }

  Future<List<Publication>> findAll() async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> publications = await db.query('publication');
    List<Publication> liste = publications.isNotEmpty
        ? publications.map((c) => Publication.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

  Future<List<Publication>> findOngoingAll(int milliseconds) async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> publications = await db.query('publication', where: 'milliseconds >= ?',
        whereArgs: [milliseconds]);
    List<Publication> liste = publications.isNotEmpty
        ? publications.map((c) => Publication.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

  Future<List<Publication>> findOldAll(int milliseconds) async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> publications = await db.query('publication', where: 'milliseconds < ?',
        whereArgs: [milliseconds]);
    List<Publication> liste = publications.isNotEmpty
        ? publications.map((c) => Publication.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

  //Update Todo record
  Future<int> update(Publication data) async {
    final db = await dbProvider.database;
    var result = await db.update("publication", data.toDatabaseJson(),
        where: "id = ?", whereArgs: [data.id]);
    return result;
  }

  //Delete Todo records
  Future<int> deleteById(int id) async {
    final db = await dbProvider.database;
    var result = await db.delete("publication", where: 'id = ?', whereArgs: [id]);
    return result;
  }

  //We are not going to use this in the demo
  Future<int> deleteAllPublications() async {
    final db = await dbProvider.database;
    var result = await db.delete(
      "publication",
    );
    return result;
  }
}