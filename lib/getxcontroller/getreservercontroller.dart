
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ReserverGetController extends GetxController {

  // A t t r i b u t e s  :
  var data = <String>[].obs;

  // M E T H O D S :
  @override
  void onInit() {
    super.onInit();
  }

  void addData(String reserve){
    if(data.length == 0){
      data.add(reserve);
    }
    else{
      data[0] = reserve;
    }
    //
    update();
  }

  void clear() {
    data.clear();
  }
}