
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:tro/repositories/chat_repository.dart';

import '../models/chat.dart';
import '../models/publication.dart';
import '../repositories/publication_repository.dart';

class NavChatGetController extends GetxController {

  //
  var tableau = <int>[].obs;
  // Exceptionnellement :
  final _chatRepository = ChatRepository();

  @override
  void onInit() {
    tableau.add(0);
    findAll();
    super.onInit();
  }

  Future<void> findAll() async {
    //List<Publication> lte = await _publicationRepository.findOngoingAll(DateTime.now().millisecondsSinceEpoch);
    List<Chat> lte = await _chatRepository.findAllChats();
    int taille = lte.where((chat) => chat.read ==0).toList().length;
    feed(taille);
  }

  // Feed array :
  void feed(int taille){
    tableau[0] = taille;
    update();
  }

  int getLength() {
    return tableau.length;
  }

}