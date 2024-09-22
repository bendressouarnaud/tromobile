
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/cible.dart';
import '../repositories/cible_repsository.dart';

class CibleGetController extends GetxController {

  // A t t r i b u t e s  :
  var data = <Cible>[].obs;
  final _repository = CibleRepository();


  // M E T H O D S :
  @override
  void onInit() {
    getData();
    super.onInit();
  }

  Future<void> getData() async{
    data.addAll(await _repository.findAll());
  }

  void addData(Cible cible) async {
    await _repository.insert(cible);
    data.insert(0, cible);
    //update();

    // Set timer to
    Future.delayed(const Duration(milliseconds: 700),
            () {
          update();
        }
    );
  }

  void updateData(Cible cible) async {
    //
    await _repository.update(cible);
    Cible ce = data.where((p0) => p0.id == cible.id).first;
    int idx = data.indexOf(ce);
    // Update
    data[idx] = cible;
    // Set timer to
    Future.delayed(const Duration(milliseconds: 700),
            () {
          update();
        }
    );
  }

  void refreshMainInterface(){
    update();
  }

  Future<int> deleteAllCibles() async{
    return await _repository.deleteAllCibles();
  }

}