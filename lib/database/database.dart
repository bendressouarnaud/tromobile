import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tro/models/parameters.dart';

import '../models/pays.dart';
import '../models/ville.dart';


class DatabaseHelper {

  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "fluttercommerce.db";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 1;


  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database? _database ;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE user (id INTEGER PRIMARY KEY,typepieceidentite TEXT,numeropieceidentite TEXT,'
        'nom TEXT, prenom TEXT, email TEXT,numero TEXT,adresse TEXT,fcmtoken TEXT,pwd TEXT, codeinvitation TEXT,'
        'nationnalite TEXT)');
    await db.execute('CREATE TABLE pays (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT,iso2 TEXT,iso3 TEXT,unicodeFlag TEXT)');

    await db.execute('CREATE TABLE publication (id INTEGER PRIMARY KEY,userid INTEGER,villedepart INTEGER,'
        'villedestination INTEGER, datevoyage TEXT, datepublication TEXT,reserve INTEGER,active INTEGER,reservereelle INTEGER,souscripteur INTEGER,'
        'milliseconds INTEGER, identifiant TEXT, devise INTEGER, prix INTEGER)');

    await db.execute('CREATE TABLE ville (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT,paysid INTEGER)');
    await db.execute('CREATE TABLE cible (id INTEGER PRIMARY KEY ,villedepartid INTEGER,paysdepartid INTEGER,'
        'villedestid INTEGER,paysdestid INTEGER, topic TEXT)');
    await db.execute('CREATE TABLE chat (id INTEGER PRIMARY KEY AUTOINCREMENT,idpub INTEGER,milliseconds INTEGER,'
        'sens INTEGER,statut INTEGER, contenu TEXT, identifiant TEXT, iduser INTEGER, idlocaluser INTEGER)');

    await db.execute('CREATE TABLE souscription (id INTEGER PRIMARY KEY AUTOINCREMENT,idpub INTEGER,iduser INTEGER,'
        'millisecondes INTEGER, reserve INTEGER)');

    await db.execute('CREATE TABLE parameters (id INTEGER PRIMARY KEY,state TEXT,travellocal INTEGER,'
        'travelabroad INTEGER)');

    // Init values :
    _createCountry(db);

    /*await db.execute('CREATE TABLE article (idart INTEGER PRIMARY KEY,iddet INTEGER,prix INTEGER, reduction INTEGER, note INTEGER, articlerestant INTEGER, libelle TEXT, lienweb TEXT)');*/
    //await db.execute('CREATE TABLE user (id INTEGER PRIMARY KEY,name TEXT NOT NULL,pwd TEXT NOT NULL)');
  }

  Future<void> _createCountry(Database database) async {
    await database.insert('pays',
        Pays(id: 1, name: 'France', iso2: 'FR', iso3: 'FRA', unicodeFlag: '🇫🇷').toDatabaseJson());
    await database.insert('pays',
        Pays(id: 2, name: 'Côte d\'Ivoire', iso2: 'CV', iso3: 'CIV', unicodeFlag: '🇨🇮').toDatabaseJson());
    // Ville Côte d\'Ivoire
    await database.insert('ville', Ville(id: 1, name: 'Paris', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 2, name: 'Lyon', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 3, name: 'Marseille', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 4, name: 'Nantes', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 5, name: 'Strasbourg', paysid: 1).toDatabaseJson());
    // Ville Côte d\'Ivoire
    await database.insert('ville', Ville(id: 6, name: 'Abidjan', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 7, name: 'Bouaké', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 8, name: 'Yamoussoukro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 9, name: 'Daloa', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 10, name: 'Gagnoa', paysid: 2).toDatabaseJson());
    // Add parameters :
    await database.insert('parameters', Parameters(id: 1, state: 'resumed', travellocal: 500, travelabroad: 5000).toDatabaseJson());
  }

  // Database helper methods:
  /*Future<int> insert(User user) async {
    Database db = await database;
    int id = await db.insert('user', user.toMap());
    return id;
  }

  Future<User?> queryWord(int id) async {
    Database db = await database;
    List<Map> maps = await db.query('user',
        columns: ['id', 'name', 'pwd'],
        where: 'id = ?',
        whereArgs: [id]);
    // Browse :
    if (maps.length > 0) {
      //return User.fromMap(maps.first);
      return User(
          id: maps[0]['id'],
          name: maps[0]['name'],
          pwd: maps[0]['pwd']
      );
    }
    return null;
  }

  // Look for specific user  :
  Future<User?> authenticateUser(String id, String pwd) async {
    Database db = await database;
    List<Map> maps = await db.query('user',
        columns: ['id', 'name', 'pwd'],
        where: 'name = ? and pwd = ?',
        whereArgs: [id, pwd]);
    // Browse :
    if (maps.isNotEmpty) {
      //return User.fromMap(maps.first);
      return User(
          id: maps[0]['id'],
          name: maps[0]['name'],
          pwd: maps[0]['pwd']
      );
    }
    return null;
  }

  // Look for specific user  :
  Future<User?> getLocalUser() async {
    Database db = await database;
    List<Map> maps = await db.query('user',
        columns: ['id', 'name', 'pwd']);
    // Browse :
    if (maps.isNotEmpty) {
      //return User.fromMap(maps.first);
      return User(
          id: maps[0]['id'],
          name: maps[0]['name'],
          pwd: maps[0]['pwd']
      );
    }
    return null;
  }*/

// TODO: queryAllWords()
// TODO: delete(int id)
// TODO: update(Word word)
}