import 'dart:async';

import '../database/database.dart';
import '../models/user.dart';

class UserDao {
  final dbProvider = DatabaseHelper.instance;

  //Adds new Todo records
  Future<int> createUser(User user) async {
    final db = await dbProvider.database;
    var result = db.insert("user", user.toDatabaseJson());
    return result;
  }

  Future<int> getTotalUser() async {
    final db = await dbProvider.database;
    var results = await db.rawQuery('SELECT * FROM user');
    return results.length;
  }

  Future<User?> getConnectedUser() async {
    final db = await dbProvider.database;
    var results = await db.rawQuery('SELECT * FROM user where pwd = ?', ['']);

    if (results.isNotEmpty) {
      return User.fromDatabaseJson(results.first);
    }

    return null;
  }

  Future<User?> findById(int id) async {
    final db = await dbProvider.database;
    var data = await db.query('user', where: 'id = ?', whereArgs: [id]);
    List<User> liste = data.isNotEmpty
        ? data.map((c) => User.fromDatabaseJson(c)).toList()
        : [];
    return liste.isNotEmpty ? liste.first : null;
  }

  // GEt 'USERS'
  Future<List<User>> findAllByIdIn(List<int> ids) async {
    final db = await dbProvider.database;
    var data = await db.query('user', where: 'id in (${ids.join(', ')})');
    List<User> liste = data.isNotEmpty
        ? data.map((c) => User.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

  //
  Future<List<User>> findAllUsers() async {
    final db = await dbProvider.database;
    final List<Map<String, Object?>> results = await db.query('user');
    List<User> liste = results.isNotEmpty
        ? results.map((c) => User.fromDatabaseJson(c)).toList()
        : [];
    return liste;
  }

  Future<User?> findConnectedUser(List<String> columns) async {
    try {
      final db = await dbProvider.database;
      late List<Map<String, dynamic>> result;
      result = await db.query("user", columns: columns);

      User? user = result.isNotEmpty
          ? result
          .map((item) => User.fromDatabaseJson(item))
          .toList()
          .first
          : null;
      return user;
    } on Exception catch (e) {
    // Anything else that is an exception
    print('Unknown exception: $e');
    } catch (e) {
    // No specified type, handles all
    print('Something really unknown: $e');
    }
  }


  // Get ONE USER :
  Future<List<User>> getCurrentUser(List<String> columns) async{
    final db = await dbProvider.database;
    late List<Map<String, dynamic>> result;
    result = await db.query("user",
        columns: columns);
    List<User> users = result.isNotEmpty
        ? result.map((item) => User.fromDatabaseJson(item)).toList()
        : [];
    return users;
  }

  //Get All Todo items
  //Searches if query string was passed
  Future<List<User>> getUsers(List<String> columns, String query) async {
    final db = await dbProvider.database;
    late List<Map<String, dynamic>> result;
    if (query != null) {
      if (query.isNotEmpty) {
        result = await db.query("user",
            columns: columns,
            where: 'nom LIKE ?',
            whereArgs: ["%$query%"]);
      }
    } else {
      result = await db.query("user", columns: columns);
    }

    List<User> users = result.isNotEmpty
        ? result.map((item) => User.fromDatabaseJson(item)).toList()
        : [];
    return users;
  }

  //Update Todo record
  Future<int> updateUser(User todo) async {
    final db = await dbProvider.database;
    var result = await db.update("user", todo.toDatabaseJson(),
        where: "id = ?", whereArgs: [todo.id]);
    return result;
  }

  //Delete Todo records
  Future<int> deleteUserById(int id) async {
    final db = await dbProvider.database;
    var result = await db.delete("user", where: 'id = ?', whereArgs: [id]);
    return result;
  }

  //We are not going to use this in the demo
  Future<int> deleteAllUsers() async {
    final db = await dbProvider.database;
    var result = await db.delete(
      "user",
    );
    return result;
  }
}