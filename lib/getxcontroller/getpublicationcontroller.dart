
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:tro/models/souscription.dart';
import 'package:tro/repositories/souscription_repository.dart';

import '../models/publication.dart';
import '../repositories/publication_repository.dart';

class PublicationGetController extends GetxController {

  //
  var publicationData = <Publication>[].obs;
  var souscriptionData = <Souscription>[].obs;
  final _publicationRepository = PublicationRepository();
  final _souscriptionRepository = SouscriptionRepository();


  @override
  void onInit() {
    findAll();
    super.onInit();
  }

  // Get Live ACHAT :
  Future<void> findAll() async {
    //List<Publication> lte = await _publicationRepository.findOngoingAll(DateTime.now().millisecondsSinceEpoch);
    List<Publication> lte = await _publicationRepository.findAll();
    // Pick All Subscription :
    List<int> pubids = lte.map((e) => e.id).toList();
    List<Souscription> sousList = await _souscriptionRepository.findAllByPublicationsIn(pubids);
    publicationData.addAll(lte);
    souscriptionData.addAll(sousList);
  }

  Future<List<Publication>> findAllPublication() async {
    List<Publication> lte = await _publicationRepository.findAll();
    return lte.where((pub) => pub.milliseconds >= DateTime.now().millisecondsSinceEpoch).toList();
  }

  Future<List<Publication>> findOldAll() async {
    return await _publicationRepository.findOldAll(DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Publication>> refreshAllPublicationsFromResumed() async {
    //List<Publication> lte = await _publicationRepository.findOngoingAll(DateTime.now().millisecondsSinceEpoch);
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
    Publication? pub = publicationData.where((p0) => p0.id == publication.id).firstOrNull;
    int maj = 0;
    if(pub != null) {
      int idx = publicationData.indexOf(pub);
      // Update
      publicationData[idx] = publication; // pub;

      maj = await _publicationRepository.update(publication);
      // Set timer to
      Future.delayed(const Duration(milliseconds: 800),
              () {
            update();
          }
      );
    }
    return maj;
  }

  // Find Publication :
  Future<Publication> refreshPublication(int idpub) async {
    // Add this one :
    Publication tampon = await _publicationRepository.findPublicationById(idpub);
    Publication? pub = publicationData.where((p0) => p0.id == tampon.id).firstOrNull;
    if(pub == null){
      // Add it :
      publicationData.add(tampon);
      update();
    }
    return await _publicationRepository.findPublicationById(idpub);
  }

  Future<Publication?> findOptionalPublicationById(int idpub) async {
    return await _publicationRepository.findOptionalPublicationById(idpub);
  }

  Future<int> deleteAllPublications() async {
    publicationData.clear();
    int ret = await _publicationRepository.deleteAllPublications();
    update();
    return ret;
  }

  List<Souscription> getAllSouscription() {
    return souscriptionData;
  }
}