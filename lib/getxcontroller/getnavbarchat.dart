
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/publication.dart';
import '../repositories/publication_repository.dart';

class NavChatGetController extends GetxController {

  //
  var tableau = <int>[].obs;

  @override
  void onInit() {
    tableau.add(0);
    super.onInit();
  }

  // Feed array :
  void feed(int taille){
    tableau[0] = taille;
    update();
  }

}