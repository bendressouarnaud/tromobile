import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:tro/getxcontroller/getchatcontroller.dart';
import 'package:tro/models/chat.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/publication_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';
import 'package:tro/screens/listannonce.dart';

import 'main.dart';
import 'messagerie.dart';
import 'models/pays.dart';
import 'models/publication.dart';
import 'models/user.dart';
import 'models/ville.dart';

class ChatManagement extends StatefulWidget {
  final Client client;
  const ChatManagement({Key? key, required this.client}) : super(key: key);

  @override
  State<ChatManagement> createState() => _ChatManagementState();
}

class _ChatManagementState extends State<ChatManagement> {
  // O B J E C T S :
  final _paysRepository = PaysRepository();
  final _publicationRepository = PublicationRepository();
  final _userRepository = UserRepository();
  final _villeRepository = VilleRepository();
  List<Pays> listePays = [];
  List<Ville> listeVille = [];
  User? localUser;

  final lesCouleurs = [Colors.black12, Colors.blue[100], Colors.blueGrey[100], Colors.red[100], Colors.orange[100], Colors.yellow[100],
    Colors.green[100], Colors.purple[100], Colors.brown[100], Colors.white70, Colors.pink[100]];
  int cptCouleur = 0;
  late List<User> ownersChat;
  late List<Publication> lesPublications;
  late List<int> feedPublications;
  late User tUser;
  late String leMessage;



  // M E T H O D S :
  @override
  void initState() {
    // Call first :

    // Init FireBase :
    super.initState();
  }

  Future<List<User>> getUsersList() async{
    await outil.findAllChats();
    ownersChat = await _userRepository.findAllUsers();
    lesPublications = await _publicationRepository.findAll();
    return ownersChat;
  }

  Color markChatAsNotRead(Chat chat){
    return chat.read == 0 ? const Color(0xFFECECF1) :
    const Color(0xFFFFFFFF);
  }

  Color? processButtonColor(){
    if(cptCouleur==11) cptCouleur = 0;
    return lesCouleurs[cptCouleur++];
  }

  String generateRaccourci(int iduser){
    User currentUser = ownersChat.where((element) => element.id == iduser).first;
    return '${currentUser.nom.substring(0,1)}${currentUser.prenom.substring(0,1)}';
  }

  String getPublicationIdentifiant(int idpub) {
    return lesPublications.where((element) => element.id == idpub).first.identifiant;
  }

  String processChat(Chat chat) {
    /*if(feedPublications.where((pub) => pub == chat.idpub).isEmpty){
      // Do the necessary :
      feedPublications.add(chat.idpub);
      // Find PEPOLE name :
      User tUser = ownersChat.where((user) => user.id == chat.iduser).first;
      // Display message :
      String leMessage = chat.contenu;
    }*/

    // Find PEPOLE name :
    tUser = ownersChat.where((user) => user.id == chat.iduser).first;
    // Display message :
    return '${tUser.nom} ${tUser.prenom}';
  }

  List<Chat> filterChatList(List<Chat> readList) {
    List<Chat> tampon = [];
    for(Chat mChat in readList){
      if(tampon.where((chat) => chat.idpub == mChat.idpub).isEmpty){
        tampon.add(mChat);
      }
    }
    return tampon;
  }

  String processDate(int millisecondes){
    var temps = DateTime.fromMillisecondsSinceEpoch(millisecondes);
    var now = DateTime.now();
    if((temps.year == now.year) && (temps.month  == now.month) && (temps.day  == now.day)){
      return '${temps.hour.toString()}:${temps.minute.toString()}';
    }
    String tpDay = temps.day < 10 ? '0${temps.day}' : temps.day.toString();
    String tpMois = temps.month < 10 ? '0${temps.month}' : temps.month.toString();
    return '$tpDay/$tpMois/${temps.year.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: Future.wait([getUsersList()]),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              //listePublication = snapshot.data[0];
              return GetBuilder<ChatGetController>(
                  builder: (controller) {
                    controller.data.sort((a,b) =>
                        b.id.compareTo(a.id));
                    var liste = filterChatList(controller.data);

                    return controller.data.isEmpty ?
                    const Center(
                        child: Text(
                          'Aucun Message',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17
                          ),
                        )
                    )
                        :
                    SingleChildScrollView(
                        child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: liste.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      //
                                      Navigator.push(context,
                                        MaterialPageRoute(
                                            builder: (context) {
                                              return Messagerie(idpub: liste[index].idpub,
                                                  owner: processChat(liste[index]),
                                                  idSuscriber: 0, client: widget.client);
                                            }
                                        )
                                      );
                                    },
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: markChatAsNotRead(liste[index]),
                                            borderRadius: BorderRadius.circular(8.0)
                                        ),
                                        margin: const EdgeInsets.only(left: 7,right: 7, bottom: 15),
                                        width: MediaQuery.of(context).size.width,
                                        height: 80,
                                        child: Row(
                                          children: [
                                            ElevatedButton(
                                                onPressed: (){},
                                                style: ElevatedButton.styleFrom(
                                                    shape: const CircleBorder(),
                                                    backgroundColor: processButtonColor()
                                                ),
                                                child: Text(generateRaccourci(liste[index].iduser),
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black
                                                    )
                                                )
                                            ),
                                            Expanded(
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.only(right: 10),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(getPublicationIdentifiant(liste[index].idpub)),
                                                          Text(processDate(liste[index].milliseconds),
                                                              style: const TextStyle(
                                                                  color: Colors.black87
                                                              ))
                                                        ],
                                                      )
                                                    ),
                                                    Container(
                                                      alignment: Alignment.topLeft,
                                                      margin: const EdgeInsets.only(right: 10),
                                                      child: Text(processChat(liste[index]),
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black87
                                                          )
                                                      )
                                                    ),
                                                    Container(
                                                        alignment: Alignment.topLeft,
                                                        margin: const EdgeInsets.only(right: 10),
                                                        child: Text(
                                                            liste[index].contenu.length > 30 ?
                                                            '${liste[index].contenu.substring(0,26)} ...' :
                                                            liste[index].contenu,
                                                            style: const TextStyle(
                                                                color: Colors.black87
                                                            )
                                                        )
                                                    )
                                                  ],
                                                )
                                            )
                                          ],
                                        )
                                    ),
                                  )
                                ],
                              );
                            }
                        )
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



    );
  }
}