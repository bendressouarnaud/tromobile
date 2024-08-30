

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserGetController extends GetxController {

  // A t t r i b u t e s  :
  var userData = <User>[].obs;
  final _userRepository = UserRepository();


  // M E T H O D S :
  @override
  void onInit() {
    findConnectedUser();
    super.onInit();
  }

  Future<User?> getData() {
    return _userRepository.findConnectedUser();
  }

  void findConnectedUser() {
    _userRepository.getConnectedUser().then((v) {
      if(v != null){
        userData.add(v);
      }
    });
  }

  void addData(User user) async {
    await _userRepository.insertUser(user);
    //userData.clear();
    userData.add(user);
    update();
  }

  void refreshMainInterface(){
    update();
  }

  Future<List<User>> findAllByIdIn(List<int> ids) async{
    return await _userRepository.findAllByIdIn(ids);
  }

  // Delete USER ACCOUNT :
  Future<int> deleteUser(int idcli) async{
    int ret = 0;
    await _userRepository.deleteUserById(idcli).then((value) => {
      ret = value
    });

    // Clean :
    userData.clear();
    update();

    return ret;
  }

  // Used temporarily to fix following below method :
  Future<User?> pickLocalUser() async{
    return await _userRepository.getConnectedUser();
  }

  User getLocalUser() {
    return userData.first;
  }

  Future<User?> findById(int id) async {
    return await _userRepository.findById(id);
  }

}