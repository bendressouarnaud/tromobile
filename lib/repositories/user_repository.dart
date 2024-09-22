import '../dao/dao_user.dart';
import '../models/user.dart';

class UserRepository {
  final userDao = UserDao();

  Future<int> getTotalUser() => userDao.getTotalUser();
  Future<User?> findById(int id) => userDao.findById(id);
  Future<User?> getConnectedUser() => userDao.getConnectedUser();
  Future<List<User>> findAllByIdIn(List<int> ids) => userDao.findAllByIdIn(ids);
  Future<List<User>> findAllUsers() => userDao.findAllUsers();
  Future<User?> findConnectedUser() => userDao.findConnectedUser(["id"
    ,"nom"
    ,"prenom"
    ,"email"
    ,"numero"
    ,"adresse"
    ,"fcmtoken"
    ,"pwd"
    ,"codeinvitation"
  ]);

  Future getCurrentUser() => userDao.getCurrentUser(["id","nom","prenom"]);

  Future getAllUsers(String query) => userDao.getUsers(["id","nom","prenom"], query);

  Future<int> insertUser(User user) => userDao.createUser(user);

  Future updateUser(User user) => userDao.updateUser(user);

  Future<int> deleteUserById(int id) => userDao.deleteUserById(id);

  //We are not going to use this in the demo
  Future<int> deleteAllUsers() => userDao.deleteAllUsers();
}