import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:tro/repositories/chat_repository.dart';
import 'package:tro/singletons/outil.dart';

import 'getxcontroller/getchatcontroller.dart';
import 'models/chat.dart';
import 'models/user.dart';

class Messagerie extends StatefulWidget {
  // Attributes
  final int idpub;
  final int idSuscriber;
  final String owner;
  final Client client;

  Messagerie({Key? key, required this.idpub, required this.owner, required this.idSuscriber, required this.client}) : super(key: key);

  @override
  State<Messagerie> createState() => _HMessagerie();
}

class _HMessagerie extends State<Messagerie> {
  // A T T R I B U T E S:
  late int idpub;
  late int idSuscriber;
  late String owner;
  //final ChatGetController _chatController = Get.put(ChatGetController());
  TextEditingController messageController = TextEditingController();
  String date = '';
  Outil outil = Outil();
  late StreamSubscription<ConnectivityResult> _subscription;
  bool checkNetworkConnected = false;
  final _chatRepository = ChatRepository();
  //
  late User localUser;
  final ScrollController _controller = ScrollController();
  //late final AppLifecycleListener _listener;
  List<Chat> listeChat = [];
  bool canFlagStraight = false;



  // M E T H O D S
  @override
  void initState() {
    super.initState();

    idpub = widget.idpub;
    idSuscriber = widget.idSuscriber;
    owner = widget.owner;

    _subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // Handle the new connectivity status!
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        checkNetworkConnected = true;
      }
      else{
        checkNetworkConnected = false;
      }
    });
  }


  @override
  void dispose() async{
    _subscription.cancel();
    _controller.dispose();
    //_listener.dispose();

    // Update
    super.dispose();
  }

  // Load Messages from DATA BASE
  Future<List<Chat>> loadingChat() async{
    // Get Local User :
    localUser = outil.getLocalUser();

    /*List<Chat> tamponListe = idSuscriber == 0 ? await outil.getChatByIdpub(idpub) :
    await outil.getChatByIdpubAndIduser(idpub, idSuscriber, localUser.id);*/

    List<Chat> tamponListe = await outil.getChatByIdpubAndIduser(idpub, idSuscriber, localUser.id);

    // Mark CHAT as read
    /*for(Chat cChat in tamponListe){
      if(cChat.read == 0){
        Chat nChat = Chat(
            id: cChat.id,
            idpub: cChat.idpub,
            milliseconds: cChat.milliseconds,
            sens: cChat.sens,
            contenu: cChat.contenu,
            statut: cChat.statut,
            identifiant: cChat.identifiant,
            iduser: cChat.iduser,
            idlocaluser: cChat.idlocaluser,
            read: 1
        );
        await outil.updateData(nChat);
      }
    }*/

    if(tamponListe.isNotEmpty){
      Future.delayed(const Duration(milliseconds: 300),
              () {
            _controller.jumpTo(_controller.position.maxScrollExtent);
          }
      );
    }
    return tamponListe;
  }

  // Persist Message :
  void persistMessage() async{
    int time = DateTime.now().millisecondsSinceEpoch;
    var dateTime = DateTime.now();
    String messageId = '${outil.getLocalUser().id}${dateTime.millisecondsSinceEpoch}';
    Chat newChat = Chat(id: 0, idpub: idpub, milliseconds: time, sens: 0, contenu: messageController.text, statut: 0,
        identifiant: messageId, iduser: idSuscriber, idlocaluser: localUser.id,
    read: 1);
    await outil.insertChat(newChat);

    // Try to clear :
    //_controller.jumpTo(_controller.position.maxScrollExtent);
    var contenuMessage = messageController.text;
    messageController.clear();

    Future.delayed(const Duration(milliseconds: 500),
            () {
          _controller.jumpTo(_controller.position.maxScrollExtent);
        }
    );

    // Generate ID :
    if(checkNetworkConnected) {
      final url = Uri.parse('${dotenv.env['URL']}sendmessage');
      try {
        var response = await widget.client.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "iduser": outil.getLocalUser().id,
              "idpub": idpub,
              "message": contenuMessage,
              "messageid": messageId,
              "idsouscripteur": idSuscriber,
            })).timeout(const Duration(seconds: 7));
        if (response.statusCode == 200) {
          // Find 'CHAT'
          Chat updateChat = await _chatRepository.findByIdentifiant(messageId);
          // Notify :
          Chat nChat = Chat(
            id: updateChat.id,
            idpub: updateChat.idpub,
            milliseconds: updateChat.milliseconds,
            sens: updateChat.sens,
            contenu: updateChat.contenu,
            statut: 1,
            identifiant: updateChat.identifiant,
            iduser: idSuscriber,
            idlocaluser: localUser.id,
              read: 1
          );
          await outil.updateData(nChat);
        }
      } on TimeoutException catch (e) {
        // handle timeout
      }
    }
  }

  // Process TIME
  String processDateTime(int millisecond){
    return DateFormat('hh:mm').format(DateTime.fromMillisecondsSinceEpoch(millisecond));
  }

  Widget displayDate(int millisecond){
    var dateTime = DateTime.fromMillisecondsSinceEpoch(millisecond);
    var mois = dateTime.month.toString().length == 1 ? '0${dateTime.month}' : dateTime.month.toString();
    var jour = dateTime.day.toString().length == 1 ? '0${dateTime.day}' : dateTime.day.toString();
    var localDate = "$jour/$mois/${dateTime.year}";
    if(localDate != date){
      date = localDate;
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 15),
            alignment: Alignment.center,
            child: Text(localDate,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold
              ),
            )
          ),
          Container(
            margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child: const Divider(
              height: 5,
              color: Colors.black,
            )
          )
        ],
      );
    }
    else{
      return const SizedBox(
        height: 5,
      );
    }
  }

  void trackChat(Chat cChat) {
    if(cChat.read == 0) {
      listeChat.add(cChat);
    }
  }

  //
  void flagChat(Chat cChat) async{
    if(cChat.read == 0){
      //
      canFlagStraight = true;
      // Flag it :
      Chat nChat = Chat(
          id: cChat.id,
          idpub: cChat.idpub,
          milliseconds: cChat.milliseconds,
          sens: cChat.sens,
          contenu: cChat.contenu,
          statut: cChat.statut,
          identifiant: cChat.identifiant,
          iduser: cChat.iduser,
          idlocaluser: cChat.idlocaluser,
          read: 1
      );
      await outil.updateChatWithoutNotifFromMessagerie(nChat); // updateChatWithoutNotifFromMessagerie   updateChatWithoutNotif
    }
  }


  void _backPressed() {
    Navigator.pop(context, canFlagStraight ? '1' : '0');
  }

  Widget displayChat (Chat chat) {
    // Flag CHAT if needed :
    flagChat(chat);

    return Column(
      children: [
        displayDate(chat.milliseconds),
        Container(
            alignment: chat.sens == 0 ? Alignment.topRight : Alignment.topLeft,
            child: Container(
              //alignment: listeChat[index].sens == 0 ? Alignment.topRight : Alignment.topLeft,
              margin: chat.sens == 0 ? const EdgeInsets.only(right: 10, top: 7) :
              const EdgeInsets.only(left: 10, top: 7),
              padding: const EdgeInsets.all(10),
              width: chat.contenu.length > 50 ? 300 : 175,
              decoration: BoxDecoration(
                  color: chat.sens == 0 ? Colors.orange[100] : Colors.green[200],
                  borderRadius: const BorderRadius.all(Radius.circular(25))
              ),
              child: Column(
                children: [
                  Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                          chat.contenu
                      )
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          processDateTime(chat.milliseconds),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        chat.statut == 0 ?
                        const SizedBox(
                            height: 10.0,
                            width: 10.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              strokeWidth: 0.8, // Width of the circular line
                            )
                        ) :
                        chat.statut == 3 ?
                        const Row(
                          children: [
                            SizedBox(
                              child: Icon(
                                  size: 15,
                                  Icons.check_circle
                              ),
                            ),
                            SizedBox(
                              child: Icon(
                                  size: 15,
                                  Icons.check_circle
                              ),
                            )
                          ],
                        )
                            :
                        const SizedBox(
                          child: Icon(
                              size: 15,
                              Icons.check_circle
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
        )
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          _backPressed();
          return Future.value(false);
        },
        child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                owner,
                textAlign: TextAlign.start,
              ),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )
              ),
              /*actions: [
            ],*/
            ),
            //bottomNavigationBar: BottomSection(),
            body: FutureBuilder(
                future: Future.wait([loadingChat()]),
                builder: (BuildContext contextMain, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                    // Get DATA :
                    List<Chat> listeChat =  snapshot.data[0];

                    return GetBuilder<ChatGetController>(
                        builder: (controller){

                          var listeCourante = controller.data.where((chat) => (widget.idpub == chat.idpub) &&
                              (widget.idSuscriber == chat.iduser)).toList();
                          listeCourante.sort((a,b) => a.id.compareTo(b.id));

                          return Stack(
                              children: [
                                Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: 70,
                                    child: Container(
                                      //color: Colors.blue[100],
                                      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                                      decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(40),
                                              topLeft: Radius.circular(40),
                                              bottomLeft: Radius.circular(40),
                                              bottomRight: Radius.circular(40)
                                          )
                                      ),
                                      child: TextField(
                                        onTap: () {
                                          // Do it TWICE because of KEYBORD apparition :
                                          Future.delayed(const Duration(milliseconds: 500),
                                                  () {
                                                _controller.jumpTo(_controller.position.maxScrollExtent);
                                              }
                                          );
                                        },
                                        maxLines: 7,
                                        controller: messageController,
                                        decoration: InputDecoration(
                                          border: const UnderlineInputBorder(),
                                          hintText: "Votre message",
                                          //labelText: "Email",
                                          prefixIcon:
                                          IconButton(
                                              onPressed: () async{
                                                // Send that message :
                                                /*print('startService ------- --------------------------------');
                                      final service = FlutterBackgroundService();
                                      await service.startService();*/
                                              },
                                              icon: const Icon(Icons.email_rounded)
                                          ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.send),
                                            onPressed: (){
                                              if(checkNetworkConnected) {
                                                persistMessage();
                                              }
                                              else{
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                      duration: Duration(seconds: 3),
                                                      content: Text("Le terminal n'est pas connecté !")
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        textInputAction: TextInputAction.newline,
                                      ),
                                    )
                                ),
                                Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    bottom: 70,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 7),
                                      decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(40)
                                          )
                                      ),
                                      child: SingleChildScrollView(
                                          controller: _controller,
                                          scrollDirection: Axis.vertical,
                                          physics: const ScrollPhysics(),
                                          child: ListView.builder(
                                            //controller: _controller,
                                              physics: const NeverScrollableScrollPhysics(),
                                              scrollDirection: Axis.vertical,
                                              shrinkWrap: true,
                                              itemCount: listeCourante.length, //listeChat.length,
                                              itemBuilder: (BuildContext context, int index) {

                                                return ((widget.idpub == listeCourante[index].idpub) &&
                                                    (widget.idSuscriber == listeCourante[index].iduser)) ?
                                                    displayChat(listeCourante[index]) :
                                                    Container();
                                              }
                                          )
                                      ),
                                    )
                                )
                              ]
                          );
                        }
                    );
                  }
                  else {
                    return const Center(
                      child: Text('Chargement ...'),
                    );
                  }
                }
            )
        )
    );
  }
}

/*class BottomSection extends StatelessWidget{
  const BottomSection({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 10,
      child: Container(
        color: Colors.blue,
        //padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Container(
                //color: Colors.green,
                height: 45,
                child: TextField(

                ),
              )
            ),
            Container(
              height: 45,
              width: 45,
              color: Colors.brown,
            )
          ],
        ),
      ),
    );
  }
}*/