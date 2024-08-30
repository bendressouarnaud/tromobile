
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:http/http.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/getxcontroller/getsouscriptioncontroller.dart';
import 'package:tro/messagerie.dart';
import 'package:tro/models/souscription.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/reserverscreen.dart';
import 'package:tro/singletons/outil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'httpbeans/hubwaveresponse.dart';
import 'models/publication.dart';
import 'models/user.dart';
import 'models/ville.dart';

class HistoriqueAnnonce extends StatefulWidget {
  // Attribute
  int idart = 0;
  final Publication publication;
  final Ville ville;
  final Ville villeDepart;
  final int userOrSuscriber;

  HistoriqueAnnonce({Key? key, required this.publication, required this.ville, required this.villeDepart,
    required this.userOrSuscriber}) : super(key: key);
  //ArticleEcran.setId(this.idart, this.fromadapter, this.qte, this.client);

  @override
  State<HistoriqueAnnonce> createState() => _HAnnonce();
}

class _HAnnonce extends State<HistoriqueAnnonce> {
  // A T T R I B U T E S:
  final PublicationGetController _publicationController = Get.put(PublicationGetController());
  late Publication publication;
  late Ville ville;
  late Ville villeDepart;
  late int userOrSuscriber; // 0 : Suscriber, 1 : Owner
  final _userRepository = UserRepository();
  User? owner;
  late List<User> listeUser;
  late BuildContext dialogContextPaiement;
  int choixpaiement = 0;
  final typePaiement = ["CinetPAY", "WAVE"];
  String choixPaiement = 'CinetPAY';
  Outil outil = Outil();
  late String devise ;
  int resteReserve = 0;
  bool signalerLivraison = false;
  int indexSouscripteur = -1;


  // M E T H O D S
  String formatPrice(int price){
    if(price > 0) {
      MoneyFormatter fmf = MoneyFormatter(
          amount: price.toDouble()
      );
      return '${fmf.output.withoutFractionDigits} $devise';
    }
    else{
      return 'Gratuit';
    }
  }


  String pickDateTime(int choice, String datetime){
    return datetime.split("T")[choice];
  }

  @override
  void initState() {
    super.initState();

    publication = widget.publication;
    ville = widget.ville;
    villeDepart = widget.villeDepart;
    userOrSuscriber = widget.userOrSuscriber;
  }

  //
  String processInitial(String nom, String prenom){
    return '${nom.substring(0,1)}${prenom.substring(0,1)}';
  }

  // Charger les informations du OWNER si présent :
  Future<List<User>> loadOwner() async{

    // Refresh 'Publication' because the OBJECT has been given as 'Parameter' :
    publication = await outil.refreshPublication(publication.id);
    // Init this variable :
    resteReserve = publication.reserve;
    // Get Devise
    devise = outil.getDevises().where((dev) => dev.id == publication.devise).single.libelle;

    List<User> retour = [];
    if(userOrSuscriber ==0) {
      owner = await outil.findUserById(publication.souscripteur);
      if(owner != null){
        retour.add(owner!);
      }
    }
    else{
      // Load 'SUSCRIBERS' :
      List<Souscription> lesSouscriptions = await outil.getAllSouscriptionByIdpub(publication.id);
      if(lesSouscriptions.isNotEmpty){
        // Get User Ids list :
        List<int> userIds = lesSouscriptions.map((e) => e.iduser).toList();
        // Now get Users :
        List<User> liste = await outil.findAllUserByIdin(userIds);
        retour.addAll(liste);

        // Sum up reserve of SUSCRIBERs
        resteReserve = publication.reserve - lesSouscriptions.map((e) => e.reserve).reduce((a, b) => a + b);
      }
    }
    return retour;
  }


  // Call HUB API
  Future<void> callHubApi() async {
    final url = Uri.parse('http://192.168.24.64:8080/sendpayments');
    var response = await post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": 100,
          "currency": 'XOF',
          "error_url": 'https://example.com/error',
          "success_url": 'https://example.com/success',
          "canal_payment": 'WAVE'
        }));

    // Checks :
    if(response.statusCode == 200){
      //List<dynamic> body = jsonDecode(response.body);
      HubWaveResponse hubWaveResponse = HubWaveResponse.fromJson(json.decode(response.body));
      // Open link
      final Uri url = Uri.parse(hubWaveResponse.wave_launch_url);
      if (!await launchUrl(url)) {
        //throw Exception('Could not launch $_url');
      }
    }
  }


  // Display ALERTDialog :
  void displayPaymentChoice(){
    showDialog(
        //barrierDismissible: false,
        context: context,
        builder: (BuildContext ctP) {
          dialogContextPaiement = ctP;
          return AlertDialog(
              title: const Text('Mode de paiement',
                textAlign: TextAlign.center,
              ),
              content: Container(
                //height: 100,
                child: DropdownMenu<String>(
                    width: 230,
                    //menuHeight: 250,
                    initialSelection: typePaiement.first,
                    hintText: "Choix paiement",
                    requestFocusOnTap: false,
                    enableFilter: false,
                    label: const Text('Choix'),
                    // Initial Value
                    onSelected: (String? value) {
                      choixPaiement = value!;
                    },
                    dropdownMenuEntries:
                    typePaiement.map<DropdownMenuEntry<String>>((String menu) {
                      return DropdownMenuEntry<String>(
                          value: menu,
                          label: menu);
                    }).toList()
                )
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContextPaiement,'Cancel'),//Navigator.pop(context, 'Cancel'),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {

                    // Close the previous :
                    Navigator.pop(dialogContextPaiement, 'OK');
                    if(choixPaiement == 'CinetPAY'){
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context){
                                return ReservePaiement(publication: publication);
                              }
                          )
                      );
                    }
                    else{
                      // WAVE : call API
                      callHubApi();
                    }
                  },
                  child: const Text('OK'),
                ),
              ]
          );
        }
    );
  }


  // Display OWNER or
  Widget displayOwnerOrReserverButton(){
    return GetBuilder<PublicationGetController>(builder: (_) {
      return outil.getPublicationOwner() == null  ?
      Container(
        alignment: Alignment.topRight,
        margin: const EdgeInsets.only(left: 10, top: 30, right: 10),
        child: ElevatedButton.icon(
          style: ButtonStyle(
              backgroundColor: MaterialStateColor.resolveWith((states) => Colors.blue)
          ),
          label: const Text("Réserver",
              style: TextStyle(
                  color: Colors.white
              )),
          onPressed: () {
            displayPaymentChoice();
            /*Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context){
                      return ReservePaiement(publication: publication);
                    }
                )
            );*/
          },
          icon: const Icon(
            Icons.money,
            size: 20,
            color: Colors.white,
          ),
        ),
      )
      :
      Container(
        margin: const EdgeInsets.only(top: 50, left: 10, right: 10),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Emetteur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const Divider(
              height: 3,
              color: Colors.black,
            ),
            GestureDetector(
              onTap: () {
                // Display DIALOG
                Navigator.push(context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Messagerie(idpub: publication.id, owner: ('${outil.getPublicationOwner()!.nom} ${outil.getPublicationOwner()!.prenom}'),
                        idSuscriber: 0,);
                    }
                  )
                );
              },
              child: Container(
                  //margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  width: MediaQuery.of(context).size.width,
                  //color: Colors.brown[100],
                  child: Card(
                    child: ListTile(
                      leading: ElevatedButton(
                          onPressed: (){},
                          style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              backgroundColor: Colors.blue[50]
                          ),
                          child: Text(processInitial(outil.getPublicationOwner()!.nom, outil.getPublicationOwner()!.prenom))
                      ),
                      title: Text('${outil.getPublicationOwner()!.nom} ${outil.getPublicationOwner()!.prenom}'),
                      subtitle: Text(outil.getPublicationOwner()!.adresse),
                      trailing: Icon(Icons.arrow_circle_right_outlined),
                    ),
                  )
              ),
            )
          ],
        ),
      );
    });
  }

  Future<bool> _onBackPressed() async {
     bool retour = signalerLivraison ? false : true;
     if(!retour){
       setState(() {
         indexSouscripteur - 1;
         signalerLivraison = false;
       });
     }
     return retour;
  }


  // Display ACTION BUTTON for 'CONFIRMER LA LIVRAISON'
  Widget displayActionButton () {
    return signalerLivraison ?
    IconButton(
        onPressed: () {
          // Send DATA to server :
        },
        icon: const Icon(Icons.offline_pin, color: Color(0xFF884106)))
    :
    const SizedBox(
      width: 1,
      height: 1
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text( !signalerLivraison ? publication.identifiant : 'Confirmer la livraison',
                textAlign: TextAlign.start,
              ),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )),
              actions: [
                displayActionButton ()
              ]
          ),
          body: FutureBuilder(
              future: Future.wait([loadOwner()]),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  //
                  listeUser = snapshot.data[0];

                  return GetBuilder<PublicationGetController>(
                      builder: (PublicationGetController controller){
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(left: 10, top: 20, right: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text('Départ : ',
                                        style: TextStyle(
                                            fontSize: 17
                                        )
                                    ),
                                    Text(
                                      villeDepart.name,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 10, top: 10, right: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Date : ${publication.datevoyage.split("T")[0]}',
                                        style: TextStyle(
                                            fontSize: 17
                                        )
                                    ),
                                    Text(
                                      'Heure : ${publication.datevoyage.split("T")[1]}',
                                      style: const TextStyle(
                                          fontSize: 17
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                alignment: Alignment.topLeft,
                                margin: const EdgeInsets.only(left: 10, top: 20, right: 10),
                                child: Text('Réserve (Kg)'),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 10, top: 3, right: 10),
                                child: Divider(
                                  color: Colors.black,
                                  height: 5,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 10, top: 10, right: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Initial : '),
                                        Text('${publication.reserve} Kg',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('Reste : '),
                                        Text(userOrSuscriber == 0 ? '${publication.reservereelle} Kg' : '$resteReserve Kg',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue
                                            )
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 10, top: 30, right: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text('Destination : ',
                                        style: TextStyle(
                                            fontSize: 17
                                        )
                                    ),
                                    Text(
                                      ville.name,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 10, top: 15, right: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text('Prix (Kg) : ',
                                        style: TextStyle(
                                            fontSize: 17
                                        )
                                    ),
                                    Text(
                                      formatPrice(publication.prix),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              userOrSuscriber == 0 ?
                              displayOwnerOrReserverButton() :
                              GetBuilder<SouscriptionGetController>(
                                builder: (SouscriptionGetController controller) {
                                  return Column(
                                    children: [
                                      Container(
                                        alignment: Alignment.topLeft,
                                        margin: const EdgeInsets.only(left: 10, top: 30, right: 10),
                                        child: Text(listeUser.length == 1 ? 'Souscripteur' : 'Souscripteurs',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(left: 10, top: 3, right: 10),
                                        child: const Divider(
                                          color: Colors.black,
                                          height: 5,
                                        ),
                                      ),
                                      listeUser.isEmpty ?
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        margin: const EdgeInsets.only(left: 10, top: 3, right: 10),
                                        child: const Text('Aucun souscripteur',
                                            style: TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            )
                                        ),
                                      ) :
                                      ListView.builder(
                                          physics: const NeverScrollableScrollPhysics(),
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemCount: listeUser.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            return GestureDetector(
                                              onLongPress: (){
                                                setState(() {
                                                  indexSouscripteur = index;
                                                  signalerLivraison = true;
                                                });
                                              },
                                              onTap: () {
                                                // Display DIALOG
                                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (context) {
                                                          return Messagerie(idpub: publication.id, owner: ('${listeUser[index].nom} ${listeUser[index].prenom}'),
                                                              idSuscriber: listeUser[index].id);
                                                        }
                                                    )
                                                );
                                              },
                                              child: Container(
                                                //margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                                                  width: MediaQuery.of(context).size.width,
                                                  //color: Colors.brown[100],   0xFFE0DDDC
                                                  child: Card(
                                                    color: (signalerLivraison && (indexSouscripteur==index)) ?
                                                    Color(0xFFD1EAD7) :
                                                    Color(0xFFEFEFEB),
                                                    child: ListTile(
                                                      leading: ElevatedButton(
                                                          onPressed: (){},
                                                          style: ElevatedButton.styleFrom(
                                                              shape: CircleBorder(),
                                                              backgroundColor: Colors.blue[50]
                                                          ),
                                                          child: Text(processInitial(listeUser[index].nom, listeUser[index].prenom))
                                                      ),
                                                      title: Text('${listeUser[index].nom} ${listeUser[index].prenom}'),
                                                      subtitle: Text('${listeUser[index].adresse}'),
                                                      trailing: Icon(Icons.arrow_circle_right_outlined),
                                                    ),
                                                  )
                                              ),
                                            );
                                          }
                                      )
                                    ],
                                  );
                                },
                              )
                              /*Container(
              margin: const EdgeInsets.only(left: 10, top: 3, right: 10),
              child: Divider(
                color: Colors.black,
                height: 5,
              ),
            )*/
                            ],
                          ),
                        );
                      }
                  );
                }
                else {
                  return const Center(
                    child: Text
                      ('Chargement ...'),
                  );
                }
              }
          )
      )
    );
  }
}