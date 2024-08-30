
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/cible.dart';
import '../models/parameters.dart';
import '../repositories/parameters_repository.dart';

class ParametersGetController extends GetxController {

  // A t t r i b u t e s  :
  var data = <Parameters>[].obs;
  final _repository = ParametersRepository();


  // M E T H O D S :
  @override
  void onInit() {
    getData();
    super.onInit();
  }

  // Return current object :
  Parameters? getCurrent() {
    return data.isNotEmpty ? data.single : null;
  }

  Future<void> getData() async{
    Parameters? prm = await _repository.findById(1);
    if(prm!=null){
      data.add(prm);
    }
  }

  Future<Parameters?> refreshData() async{
    return await _repository.findById(1);
  }

  Future<void> updateData(Parameters params) async {
    //
    await _repository.update(params);
    if(data.isEmpty){
      data.add(params);
    }
    else {
      // Update
      data[0] = params;
    }
    // Set timer to
    Future.delayed(const Duration(milliseconds: 700),
            () {
          update();
        }
    );
  }

}