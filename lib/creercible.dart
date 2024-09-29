

import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:http/http.dart';
import 'package:tro/getxcontroller/getciblecontroller.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/main.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import 'constants.dart';
import 'httpbeans/cibleresponse.dart';
import 'models/cible.dart';
import 'models/pays.dart';
import 'models/publication.dart';
import 'models/user.dart';
import 'models/ville.dart';

class CreerCible extends StatefulWidget {
  // Attributes
  final int idpaysdep;
  final int idpaysdest;
  final int idvilledep;
  final int idvilledest;
  final int idCible;
  final Client client;

  CreerCible({Key? key, required this.idpaysdep, required this.idpaysdest, required this.idvilledep,
    required this.idvilledest, required this.idCible, required this.client}) : super(key: key);

  @override
  State<CreerCible> createState() => _creerCible();
}

class _creerCible extends State<CreerCible> {
  // A T T R I B U T E S:
  final CibleGetController _cibleController = Get.put(CibleGetController());
  late User mUser;
  List<Pays> listePays = [];
  List<Ville> listeVille = [];
  List<Ville> listeVilleDestination = [];
  List<Cible> listeCible = [];
  final _paysRepository = PaysRepository();
  final _villeRepository = VilleRepository();
  final _userRepository = UserRepository();
  //
  late int idpaysdep;
  late int idpaysdest;
  late int idvilledep;
  late int idvilledest;
  late int idCible;
  //
  TextEditingController paysDepartController = TextEditingController();
  TextEditingController paysDestinationController = TextEditingController();
  TextEditingController villeDepartController = TextEditingController();
  TextEditingController villeDestinationController = TextEditingController();
  Pays? paysDepart;
  Pays? paysDestination;
  Ville? villeDestination;
  Ville? villeDepart;
  int init = 0;
  late BuildContext dialogContext;
  bool flagSendData = false;
  bool closeAlertDialog = false;
  String topic = "";



  // M E T H O D S
  @override
  void initState() {
    super.initState();

    idpaysdep = widget.idpaysdep;
    idpaysdest = widget.idpaysdest;
    idvilledep = widget.idvilledep;
    idvilledest = widget.idvilledest;
    idCible = widget.idCible;

    //
    //getData();
  }

  Future<int>  getData() async{
    if(init ==0) {
      mUser = (await _userRepository.getConnectedUser())!;
      listePays = await _paysRepository.findAll();
      paysDepart = idpaysdep != 0 ? listePays.where((pays) => pays.id == idpaysdep).first : listePays.first;
      paysDestination = idpaysdest != 0 ? listePays.where((pays) => pays.id == idpaysdest).first : listePays.first;
      // Pick 'Villes' related to the 'pays'
      listeVille = await _villeRepository.findAllByPaysId(paysDepart!.id);
      listeVille.sort((a,b) => a.name.compareTo(b.name));
      listeVilleDestination = await _villeRepository.findAllByPaysId(paysDestination!.id);
      listeVilleDestination.sort((a,b) => a.name.compareTo(b.name));
      villeDepart = idvilledep != 0 ? listeVille.where((ville) => ville.id == idvilledep).first : listeVille.first;
      villeDestination = idvilledest != 0 ? listeVilleDestination.where((ville) => ville.id == idvilledest).first : listeVilleDestination.first;
    }

    return 0;
  }

  // refresh Ville
  void refreshVille(List<Ville> villes, int choix){
    // Update the list :
    setState(() {
      if(choix == 0) {
        listeVille = villes;
        listeVille.sort((a,b) => a.name.compareTo(b.name));
        villeDepart = listeVille.first;
      }
      else{
        listeVilleDestination = villes;
        listeVilleDestination.sort((a,b) => a.name.compareTo(b.name));
        villeDestination = listeVilleDestination.first;
      }
    }
    );
  }

  // Get Country
  String getCountryName(int idPays){
    return listePays.where((pays) => pays.id == idPays).single.name;
  }

  String getTownName(int idVille){
    Ville? mVille = listeVille.where((ville) => ville.id == idVille).firstOrNull;
    return mVille != null ? mVille.name : "...";
  }

  void generateTopic() async {
   //topic = "tro${villeDepart!.id}${villeDestination!.id}";
   //await FirebaseMessaging.instance.subscribeToTopic(topic);
    topic = '';
    sendCibleRequest();
  }

  // Send Account DATA :
  Future<void> sendCibleRequest() async {
    final url = Uri.parse('${dotenv.env['URL']}managecible');
    var response = await widget.client.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": idCible,
          "iduser": mUser.id,
          "idpaysdep": paysDepart!.id,
          "paysdeplib": paysDepart!.name,
          "paysdepabrev": paysDepart!.iso2,
          "idvilledep": villeDepart!.id,
          "villedeplib": villeDepart!.name,
          "idpaysdest": paysDestination!.id,
          "paysdestlib": paysDestination!.name,
          "paysdestabrev": paysDestination!.iso2,
          "idvilledest": villeDestination!.id,
          "villedestlib": villeDestination!.name,
          "topic": topic,
        })).timeout(const Duration(seconds: timeOutValue));

    // Checks :
    if(response.statusCode == 200){
      // Add default CIBLE :
      CibleResponse ce =  CibleResponse.fromJson(json.decode(response.body));

      Cible cible = Cible(
          id: ce.idcible,
          villedepartid: villeDepart!.id,
          paysdepartid: paysDepart!.id, villedestid: villeDestination!.id, paysdestid: paysDestination!.id, topic: topic);
      if(idCible == 0){
        // INSERT :
        _cibleController.addData(cible);
      }
      else{
        // UPDATE :
        _cibleController.updateData(cible);
      }

      // Persist PUBLICATION
      for(Publication publication in ce.publications){
        // First SPLIT :
        List<String> tamponDateTime = publication.datevoyage.split("T");
        var dateVoyageFinal = DateTime.parse('${tamponDateTime[0]} ${tamponDateTime[1]}Z');
        Publication pub = Publication(
            id: publication.id,
            userid: publication.userid,
            villedepart: publication.villedepart,
            villedestination: publication.villedestination,
            datevoyage: publication.datevoyage,
            datepublication: publication.datepublication,
            reserve: publication.reserve,
            active: 1,
            reservereelle: publication.reserve,
            souscripteur: publication.souscripteur, // Use OWNER Id
            milliseconds: dateVoyageFinal.millisecondsSinceEpoch, // publication.milliseconds,
            identifiant: publication.identifiant,
            devise: publication.devise,
            prix: publication.prix,
            read: 1
        );
        outil.addPublication(pub);
      }

      // Set FLAG :
      closeAlertDialog = false;
    }
    else {
      displayToast("Erreur apparue");
    }
    flagSendData = false;
  }

  // Our TOAST :
  void displayToast(String message){
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              idCible == 0 ? 'Nouvelle cible' : 'Modification cible',
              textAlign: TextAlign.start,
            ),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                )
            ),
        ),
        body: FutureBuilder(
          future: Future.wait([getData()]),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: const Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Départ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(
                            color: Colors.black,
                            height: 5,
                          )
                        ],
                      ),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                        child: DropdownMenu<Pays>(
                            width: MediaQuery.of(context).size.width - 20,
                            menuHeight: 250,
                            initialSelection: paysDepart,
                            controller: paysDepartController,
                            hintText: "Pays de départ",
                            requestFocusOnTap: false,
                            enableFilter: false,
                            label: const Text('Sélectionner le pays de départ'),
                            // Initial Value
                            onSelected: (Pays? value) {
                              paysDepart = value!;
                              init++;
                              // Update the list :
                              _villeRepository.findAllByPaysId(paysDepart!.id).then((value) => refreshVille(value, 0));
                            },
                            dropdownMenuEntries:
                            listePays.map<DropdownMenuEntry<Pays>>((Pays menu) {
                              return DropdownMenuEntry<Pays>(
                                  value: menu,
                                  label: menu.name,
                                  leadingIcon: Icon(Icons.map));
                            }).toList()
                        )
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                        child: DropdownMenu<Ville>(
                            width: MediaQuery.of(context).size.width - 20,
                            menuHeight: 250,
                            initialSelection: villeDepart,
                            controller: villeDepartController,
                            hintText: "Ville de départ",
                            requestFocusOnTap: false,
                            enableFilter: false,
                            label: const Text('Sélectionner la ville de départ'),
                            // Initial Value
                            onSelected: (Ville? value) {
                              villeDepart = value!;
                            },
                            dropdownMenuEntries:
                            listeVille.map<DropdownMenuEntry<Ville>>((Ville menu) {
                              return DropdownMenuEntry<Ville>(
                                  value: menu,
                                  label: menu.name,
                                  leadingIcon: Icon(Icons.map));
                            }).toList()
                        )
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: EdgeInsets.only(top: 15),
                      child: const Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Destination",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(
                            color: Colors.black,
                            height: 5,
                          )
                        ],
                      ),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                        child: DropdownMenu<Pays>(
                            width: MediaQuery.of(context).size.width - 20,
                            menuHeight: 250,
                            initialSelection: paysDestination,
                            controller: paysDestinationController,
                            hintText: "Pays de destination",
                            requestFocusOnTap: false,
                            enableFilter: false,
                            label: const Text('Sélectionner le pays de destination'),
                            // Initial Value
                            onSelected: (Pays? value) {
                              paysDestination = value!;
                              init++;
                              // Update the list :
                              _villeRepository.findAllByPaysId(value.id).then((value) => refreshVille(value, 1));
                            },
                            dropdownMenuEntries:
                            listePays.map<DropdownMenuEntry<Pays>>((Pays menu) {
                              return DropdownMenuEntry<Pays>(
                                  value: menu,
                                  label: menu.name,
                                  leadingIcon: Icon(Icons.map));
                            }).toList()
                        )
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                        child: DropdownMenu<Ville>(
                            width: MediaQuery.of(context).size.width - 20,
                            menuHeight: 250,
                            initialSelection: villeDestination,
                            controller: villeDestinationController,
                            hintText: "Ville de destination",
                            requestFocusOnTap: false,
                            enableFilter: false,
                            label: const Text('Sélectionner la ville de destination'),
                            // Initial Value
                            onSelected: (Ville? value) {
                              villeDestination = value!;
                            },
                            dropdownMenuEntries:
                            listeVilleDestination.map<DropdownMenuEntry<Ville>>((Ville menu) {
                              return DropdownMenuEntry<Ville>(
                                  value: menu,
                                  label: menu.name,
                                  leadingIcon: Icon(Icons.map));
                            }).toList()
                        )
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 160,
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
                      child: ElevatedButton.icon(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith((states) => Colors.brown)
                        ),
                        label: const Text("Enregistrer",
                            style: TextStyle(
                                color: Colors.white
                            )
                        ),
                        onPressed: () {

                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                dialogContext = context;
                                return const AlertDialog(
                                  title: Text('Information'),
                                  content: Text("Veuillez patienter ..."),
                                );
                              }
                          );

                          // Send DATA :
                          flagSendData = true;
                          closeAlertDialog = true;
                          generateTopic();

                          // Run TIMER :
                          Timer.periodic(
                            const Duration(seconds: 1),
                                (timer) {
                              // Update user about remaining time
                              if(!flagSendData){
                                Navigator.pop(dialogContext);
                                timer.cancel();

                                if(!closeAlertDialog) {
                                  // Kill ACTIVITY :
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                }
                              }
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.save,
                          size: 20,
                          color: Colors.white,
                        ),
                      )
                    )
                  ],
                ),
              );
            }
            else{
              return const Center(
                child: Text('Chargement ...'),
              );
            }
          }
        )



    );
  }
}