
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/publication.dart';
import '../repositories/publication_repository.dart';

class PublicationGetController extends GetxController {

  //
  var publicationData = <Publication>[].obs;
  final _publicationRepository = PublicationRepository();


  @override
  void onInit() {
    findAll();
    super.onInit();
  }

  // Get Live ACHAT :
  Future<void> findAll() async {
    /*await _publicationRepository.findAll().then((value) => {
      publicationData.addAll(value)
    });*/
    List<Publication> lte = await _publicationRepository.findAll();
    publicationData.addAll(lte);
  }

  Future<List<Publication>> findAllPublication() async {
    return await _publicationRepository.findAll();
  }

  Future<List<Publication>> refreshAllPublicationsFromResumed() async {
    List<Publication> lte = await _publicationRepository.findAll();
    publicationData.clear();
    publicationData.addAll(lte);
    update(); // force
    return lte;
  }

  void addData(Publication data) async {
    publicationData.add(data);
    // Persist DATA :
    await _publicationRepository.insert(data);
    // Set timer to
    Future.delayed(const Duration(milliseconds: 800),
            () {
          update();
        }
    );
  }

  Future<int> updateData(Publication publication) async{
    Publication pub = publicationData.where((p0) => p0.id == publication.id).first;
    int idx = publicationData.indexOf(pub);
    // Update
    publicationData[idx] = publication; // pub;

    int maj = await _publicationRepository.update(publication);
    // Set timer to
    Future.delayed(const Duration(milliseconds: 800),
            () {
          update();
        }
    );
    return maj;
  }

  // Find Publication :
  Future<Publication> refreshPublication(int idpub) async {
    return await _publicationRepository.findPublicationById(idpub);
  }
}