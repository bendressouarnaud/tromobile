
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/souscription.dart';
import '../repositories/souscription_repository.dart';

class SouscriptionGetController extends GetxController {

  // A t t r i b u t e s  :
  var data = <Souscription>[].obs;
  final _repository = SouscriptionRepository();


  // M E T H O D S :
  @override
  void onInit() {
    super.onInit();
  }

  Future<List<Souscription>> getData(int idpub) async{
    data.clear();
    data.addAll(await _repository.findAllByIdpub(idpub));
    return data;
  }

  Future<void> addData(Souscription souscription) async {
    await _repository.insert(souscription);
    data.add(souscription);

    // Set timer to
    Future.delayed(const Duration(milliseconds: 600),
            () {
          update();
        }
    );
  }

}