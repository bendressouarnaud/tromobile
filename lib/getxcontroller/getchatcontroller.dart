
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:tro/models/chat.dart';

import '../repositories/chat_repository.dart';

class ChatGetController extends GetxController {

  // A t t r i b u t e s  :
  var data = <Chat>[].obs;
  final _repository = ChatRepository();


  // M E T H O D S :
  @override
  void onInit() {
    super.onInit();
  }

  Future<List<Chat>> getData(int idpub) async{
    // First Clean :
    data.clear();
    data.addAll(await _repository.findAll(idpub));
    return data;
  }

  Future<List<Chat>> getDataByIdpubAndIduser(int idpub, int iduser, int idlocaluser) async{
    // First Clean :
    data.clear();
    data.addAll(await _repository.findAllByIdpubAndIduser(idpub, iduser, idlocaluser));
    return data;
  }

  Future<void> addData(Chat chat) async {
    await _repository.insert(chat);
    data.add(chat);

    // Set timer to
    Future.delayed(const Duration(milliseconds: 600),
            () {
          update();
        }
    );
  }

  Future<void> addDataFromBackgroundHandler(Chat chat) async {
    await _repository.insert(chat);
    data.add(chat);
  }

  // Get CHAT to send :
  Future<List<Chat>> getChatToSend(int statut) async{
    data.clear();
    data.addAll(await _repository.findAllByStatut(statut));
    return data;
    //return await _repository.findAllByStatut(statut);
  }

  // Get CHAT to send :
  Future<List<Chat>> findAllChats() async{
    data.clear();
    data.addAll(await _repository.findAllChats());
    return data;
  }

  // Get CHAT to send :
  /*Future<Chat> findByIdentifiant(String ids) async{
    data.clear();
    data.addAll(await _repository.findAllByStatut(statut));
    return data;
    //return await _repository.findAllByStatut(statut);
  }*/

  Future<int> updateData(Chat chat) async {
    // Delete :
    Chat ce = data.where((p0) => p0.identifiant == chat.identifiant).first;
    int idx = data.indexOf(ce);
    // Update
    data[idx] = chat;
    update();
    return await _repository.update(chat);
  }

  // Update this from MESSAGERIE interface to mark this CHAT as read :
  Future<int> updateChatWithoutNotif(Chat chat) async {
    return await _repository.update(chat);
  }

  // Look for CHAT with status = 0
  List<Chat> lookForChatToSend(int statut){
    return data.where((chat) => (chat.statut == statut && chat.id == 0)).toList();
  }

}