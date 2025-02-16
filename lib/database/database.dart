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
  static final _databaseVersion = 2;


  // Make this a singleton class.
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database? _database;

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
      onCreate: _onCreate,
      onUpgrade: _onUpgrade
    );
  }

  Future _onCreate(Database db, int newVersion) async {
    for (int version = 0; version < newVersion; version++) {
      await _performDbOperationsVersionWise(db, version + 1);
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion; version < newVersion; version++) {
      await _performDbOperationsVersionWise(db, version + 1);
    }
  }

  _performDbOperationsVersionWise(Database db, int version) async {
    switch (version) {
      case 1:
        await _createDatabase(db);
        break;
      case 2:
        await _addColumnToalertUser(db);
        break;
      /*case 3:
        await _addStreamChatObject(db);
        break;*/
    }
  }

  Future _createDatabase(Database db) async {
    await db.execute(
        'CREATE TABLE user (id INTEGER PRIMARY KEY,typepieceidentite TEXT,numeropieceidentite TEXT,'
            'nom TEXT, prenom TEXT, email TEXT,numero TEXT,adresse TEXT,fcmtoken TEXT,pwd TEXT, codeinvitation TEXT,'
            'nationnalite TEXT, villeresidence INTEGER, streamtoken TEXT, streamid TEXT)');
    await db.execute(
        'CREATE TABLE pays (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT,iso2 TEXT,iso3 TEXT,unicodeFlag TEXT)');

    await db.execute(
        'CREATE TABLE publication (id INTEGER PRIMARY KEY,userid INTEGER,villedepart INTEGER,'
            'villedestination INTEGER, datevoyage TEXT, datepublication TEXT,reserve INTEGER,active INTEGER,reservereelle INTEGER,souscripteur INTEGER,'
            'milliseconds INTEGER, identifiant TEXT, devise INTEGER, prix INTEGER, read INTEGER, streamchannelid TEXT)');

    await db.execute(
        'CREATE TABLE ville (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT,paysid INTEGER)');
    await db.execute(
        'CREATE TABLE cible (id INTEGER PRIMARY KEY ,villedepartid INTEGER,paysdepartid INTEGER,'
            'villedestid INTEGER,paysdestid INTEGER, topic TEXT)');
    await db.execute(
        'CREATE TABLE chat (id INTEGER PRIMARY KEY AUTOINCREMENT,idpub INTEGER,milliseconds INTEGER,'
            'sens INTEGER,statut INTEGER, contenu TEXT, identifiant TEXT, iduser INTEGER, idlocaluser INTEGER, read INTEGER)');

    await db.execute(
        'CREATE TABLE souscription (id INTEGER PRIMARY KEY AUTOINCREMENT,idpub INTEGER,iduser INTEGER,'
            'millisecondes INTEGER, reserve INTEGER, statut INTEGER, streamchannelid TEXT)');

    await db.execute(
        'CREATE TABLE parameters (id INTEGER PRIMARY KEY,state TEXT,travellocal INTEGER,'
            'travelabroad INTEGER, notification INTEGER, epochdebut INTEGER, epochfin INTEGER, comptevalide INTEGER'
            ', deviceregistered INTEGER, privacypolicy INTEGER)');

    await db.execute(
        'CREATE TABLE filiation (id INTEGER PRIMARY KEY,code TEXT,bonus REAL)');

    // Init values :
    _createCountry(db);
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

    await database.insert('ville', Ville(id: 6, name: 'Toulouse', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 7, name: 'Nice', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 8, name: 'Montpellier', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 9, name: 'Bordeaux', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 10, name: 'Lille', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 11, name: 'Rennes', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 12, name: 'Toulon', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 13, name: 'Reims', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 14, name: 'Saint-Étienne', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 15, name: 'Le Havre', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 16, name: 'Montélimar', paysid: 1).toDatabaseJson());
    await database.insert('ville', Ville(id: 17, name: 'Blain', paysid: 1).toDatabaseJson());

    // Ville Côte d\'Ivoire
    await database.insert('ville', Ville(id: 18, name: 'Abengourou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 19, name: 'Abobo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 20, name: 'Aboisso', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 21, name: 'Adiaké', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 22, name: 'Adjamé', paysid: 2).toDatabaseJson());

    await database.insert('ville', Ville(id: 23, name: 'Adzopé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 24, name: 'Afféry', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 25, name: 'Agboville', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 26, name: 'Agnibilékrou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 27, name: 'Agou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 28, name: 'Akoupé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 29, name: 'Alépé', paysid: 2).toDatabaseJson());

    await database.insert('ville', Ville(id: 30, name: 'Anoumaba', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 31, name: 'Anyama', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 32, name: 'Arrah', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 33, name: 'Assinie', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 34, name: 'Assuéffry', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 35, name: 'Attécoubé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 36, name: 'Attiegouakro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 37, name: 'Ayamé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 38, name: 'Azaguié', paysid: 2).toDatabaseJson());

    await database.insert('ville', Ville(id: 39, name: 'Bangolo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 40, name: 'Bassawa', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 41, name: 'Bédiala', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 42, name: 'Béoumi', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 43, name: 'Bendressou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 44, name: 'Béttié', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 45, name: 'Biankouma', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 46, name: 'Bingerville', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 47, name: 'Bloléquin', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 48, name: 'Bocanda', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 49, name: 'Bodokro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 50, name: 'Bondoukou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 51, name: 'Bongouanou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 52, name: 'Bonon', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 53, name: 'Bonoua', paysid: 2).toDatabaseJson());

    await database.insert('ville', Ville(id: 54, name: 'Bouaflé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 55, name: 'Bouaké', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 56, name: 'Bouna', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 57, name: 'Boundiali', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 58, name: 'Brobo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 59, name: 'Buyo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 60, name: 'Cocody', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 61, name: 'Dabakala', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 62, name: 'Dabou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 63, name: 'Daloa', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 64, name: 'Danané', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 65, name: 'Daoukro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 66, name: 'Didiévi', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 67, name: 'Divo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 68, name: 'Djebonoua', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 69, name: 'Djèkanou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 70, name: 'Doropo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 71, name: 'Duékoué', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 72, name: 'Facobly', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 73, name: 'Ferkessédougou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 74, name: 'Fresco', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 75, name: 'Gagnoa', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 76, name: 'Gohitafla', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 77, name: 'Grabo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 78, name: 'Grand-Bassam', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 79, name: 'Grand-Béréby', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 80, name: 'Grand-Lahou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 81, name: 'Grand-Zattry', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 82, name: 'Guibéroua', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 83, name: 'Guiembé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 84, name: 'Guiglo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 85, name: 'Guitry', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 86, name: 'Hiré', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 87, name: 'Issia', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 88, name: 'Jacqueville', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 89, name: 'Kani', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 90, name: 'Katiola', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 91, name: 'Kokoumbo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 92, name: 'Kong', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 93, name: 'Kongasso', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 94, name: 'Korhogo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 95, name: 'Kouassi-Datékro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 96, name: 'Kouassi-Kouassikro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 97, name: 'Kouibly', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 98, name: 'Koumassi', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 99, name: 'Koun-Fao', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 100, name: 'Kounahiri', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 101, name: 'Kouto', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 102, name: 'Lakota', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 103, name: 'Logoualé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 104, name: 'M’bahiakro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 105, name: 'M’batto', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 106, name: 'M’bengué', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 107, name: 'Madinani', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 108, name: 'Maféré', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 109, name: 'Man', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 110, name: 'Mankono', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 111, name: 'Marcory', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 112, name: 'Méagui', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 113, name: 'Minignan', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 114, name: 'Morondo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 115, name: 'N’douci', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 116, name: 'Napié', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 117, name: 'Nassian', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 118, name: 'Niablé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 119, name: 'Niakaramandougou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 120, name: 'Niéllé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 121, name: 'Niofoin', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 122, name: 'Odienné', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 123, name: 'Ouangolodougou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 124, name: 'Ouaninou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 125, name: 'Ouellé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 126, name: 'Oumé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 127, name: 'Ouragahio', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 128, name: 'Plateau', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 129, name: 'Port-bouët', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 130, name: 'Prikro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 131, name: 'Rubino', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 132, name: 'Saïoua', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 133, name: 'Sakassou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 134, name: 'Samatiguila', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 135, name: 'San Pedro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 136, name: 'Sandégué', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 137, name: 'Sangouiné', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 138, name: 'Sarhala', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 139, name: 'Sassandra', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 140, name: 'Satama-Sokoro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 141, name: 'Satama-Sokoura', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 142, name: 'Séguéla', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 143, name: 'Séguelon', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 144, name: 'Sikensi', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 145, name: 'Sinématiali', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 146, name: 'Sinfra', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 147, name: 'Sipilou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 148, name: 'Sirasso', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 149, name: 'Songon', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 150, name: 'Soubré', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 151, name: 'Taabo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 152, name: 'Tabou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 153, name: 'Tafiré', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 154, name: 'Taï', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 155, name: 'Tanda', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 156, name: 'Téhini', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 157, name: 'Tengréla', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 158, name: 'Tiapoum', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 159, name: 'Tiassalé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 160, name: 'Tie-n’diekro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 161, name: 'Tiébissou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 162, name: 'Tiémé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 163, name: 'Tiémélékro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 164, name: 'Tortiya', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 165, name: 'Touba', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 166, name: 'Toulépleu', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 167, name: 'Toumodi', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 168, name: 'Transua', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 169, name: 'Treichville', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 170, name: 'Vavoua', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 171, name: 'Worofla', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 172, name: 'Yakassé-Attobrou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 173, name: 'Yamoussoukro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 174, name: 'Yopougon', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 175, name: 'Zikisso', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 176, name: 'Zouan-Hounien', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 177, name: 'Zoukougbeu', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 178, name: 'Zuénoula', paysid: 2).toDatabaseJson());

    // Add parameters :
    await database.insert('parameters', Parameters(id: 1, state: 'resumed', travellocal: 500, travelabroad: 5000
        , notification: 0, epochdebut: 0, epochfin: 0, comptevalide: 0, deviceregistered: 0,
        privacypolicy: 0, appmigration: 0).toDatabaseJson());
  }

  // Add new column :
  Future _addColumnToalertUser(Database db) async {
    await db.execute('ALTER TABLE parameters ADD COLUMN appmigration INTEGER');
    // Init that :
    await db.execute('UPDATE parameters SET appmigration = 0');
  }

  /*Future<void> _addTownsFirstBatch(Database database) async {
    // Ville Côte dIvoire
    await database.insert('ville', Ville(id: 11, name: 'Korhogo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 12, name: 'San-Pédro', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 13, name: 'Anyama', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 14, name: 'Divo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 15, name: 'Soubré', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 16, name: 'Duékoué', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 17, name: 'Bouaflé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 18, name: 'Bingerville', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 19, name: 'Guiglo', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 20, name: 'Lakota', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 21, name: 'Abengourou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 22, name: 'Ferké', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 23, name: 'Adzopé', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 24, name: 'Méagui', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 25, name: 'Bondoukou', paysid: 2).toDatabaseJson());
    await database.insert('ville', Ville(id: 26, name: 'Dabou', paysid: 2).toDatabaseJson());
  }

  // add  streamchannelid
  Future _addStreamChatObject(Database db) async {
    await db.execute('ALTER TABLE publication ADD COLUMN streamchannelid text');
    await db.execute('ALTER TABLE souscription ADD COLUMN streamchannelid text');
    await db.execute('ALTER TABLE parameters ADD COLUMN comptevalide INTEGER');
    await db.execute('UPDATE parameters SET comptevalide = 0');
  }*/
}