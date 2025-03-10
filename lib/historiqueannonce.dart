
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:http/http.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/getxcontroller/getsouscriptioncontroller.dart';
import 'package:tro/messagerie.dart';
import 'package:tro/models/souscription.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/reserverscreen.dart';
import 'package:tro/singletons/outil.dart';
import 'package:tro/streamchat.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stream_chat/src/core/models/user.dart' as streamuser;

import 'constants.dart';
import 'httpbeans/hubwaveresponse.dart';
import 'main.dart';
import 'managedeparture.dart';
import 'models/pays.dart';
import 'models/publication.dart';
import 'models/user.dart' as databaseuser;
import 'models/ville.dart';

class HistoriqueAnnonce extends StatefulWidget {
  // Attribute
  int idart = 0;
  final Publication publication;
  final Ville ville;
  final Ville villeDepart;
  final int userOrSuscriber;
  final bool historique;
  final Client client;
  final StreamChatClient streamclient;

  HistoriqueAnnonce({Key? key, required this.publication, required this.ville, required this.villeDepart,
    required this.userOrSuscriber, required this.historique, required this.client, required this.streamclient}) : super(key: key);
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
  final _paysRepository = PaysRepository();
  databaseuser.User? owner;
  databaseuser.User? cUser;
  late List<databaseuser.User> listeUser;
  late BuildContext dialogContextPaiement;
  int choixpaiement = 0;
  final typePaiement = ["CinetPAY", "WAVE"];
  String choixPaiement = 'CinetPAY';
  //Outil outil = Outil();
  late String devise ;
  // User for PROFILE EMETTEUR
  int resteReserve = 0;
  bool signalerLivraison = false;
  bool signalerReception = false;
  int indexSouscripteur = -1;
  late BuildContext dialogContext;
  late int iduser;
  late bool flagSendData;
  late bool closeAlertDialog;
  late bool flagDeletionData;
  late bool publicationDeletionDone;
  late bool historique;
  //
  Pays? paysDepart;
  Pays? paysDestination;
  late List<Souscription> lesSouscriptions;
  late Souscription suscriberSouscription;


  // M E T H O D S
  void openStramChat(StreamChatClient clt, Channel cnl) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context){
              return StreamChatApp(channel: cnl);
            }
        )
    );
  }

  String processTime(String time) {
    return userOrSuscriber == 0 ?
    '${time.substring(0,5)} GMT' :
    time.substring(0,5);
  }

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

  void openTravelForUpdate() async{
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context){
              return ManageDeparture(id: cUser!.id, listeCountry: [paysDepart!, paysDestination!],
                  nationalite: cUser!.nationnalite, idpub: publication.id,
                  client: widget.client);
            }
        )
    );

    // Close the DOORS :
    if (result != null) {
      // Request for Permission :
      forceLeave();
    }
  }

  // Leave :
  void forceLeave(){
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    publication = widget.publication;
    ville = widget.ville;
    villeDepart = widget.villeDepart;
    userOrSuscriber = widget.userOrSuscriber;
    historique = widget.historique;

    if( userOrSuscriber == 0 ) {
      // Feed iduser :
      outil.pickLocalUser().then((value) => {
        initIduserIfNecessary(value!.id)
      });
    }

    // Try to UPDATE :
    if(publication.read == 0) {
      Future.delayed(const Duration(milliseconds: 600),
              () {
            updatePublication();
          }
      );
    }
  }

  // Init
  void initIduserIfNecessary(int id) {
    iduser = id;
    //print('Id utilisateur LOCAL : $iduser');
  }

  // Update PUBLICATION if needed :
  void updatePublication() async{
    Publication pub = Publication(
        id: publication.id,
        userid: publication.userid,
        villedepart: publication.villedepart,
        villedestination: publication.villedestination,
        datevoyage: publication.datevoyage,
        datepublication: publication.datepublication,
        reserve: publication.reserve,
        active: publication.active,
        reservereelle: publication.reservereelle,
        souscripteur: publication.souscripteur, // Use OWNER Id
        milliseconds: publication.milliseconds,
        identifiant: publication.identifiant,
        devise: publication.devise,
        prix: publication.prix,
        read: 1,
        streamchannelid: publication.streamchannelid
    );
    await outil.updatePublication(pub);
  }

  //
  String processInitial(String nom, String prenom){
    return '${nom.substring(0,1)}${prenom.substring(0,1)}';
  }

  // Charger les informations du OWNER si présent :
  Future<List<databaseuser.User>> loadOwner() async{

    // Set this to null
    outil.setPublicationSuscribed();

    // Refresh 'Publication' because the OBJECT has been given as 'Parameter' :
    publication = await outil.refreshPublication(publication.id);
    // Init this variable :
    resteReserve = publication.reserve;
    // Get Devise
    devise = outil.getDevises().where((dev) => dev.id == publication.devise).single.libelle;

    List<databaseuser.User> retour = [];
    if(userOrSuscriber ==0) {
      owner = await outil.findUserById(publication.souscripteur);
      if(owner != null){
        retour.add(owner!);
      }
    }
    else{
      // Load 'SUSCRIBERS' :
      var tampon = await outil.getAllSouscriptionByIdpub(publication.id);
      // Eliminate SOUSCRIPTION CANCELLED :
      lesSouscriptions = tampon.where((souscrip) => souscrip.statut != 2).toList();
      if(lesSouscriptions.isNotEmpty){
        // Get User Ids list :
        List<int> userIds = lesSouscriptions.map((e) => e.iduser).toList();
        // Now get Users :
        List<databaseuser.User> liste = await outil.findAllUserByIdin(userIds);
        retour.addAll(liste);

        // Sum up reserve of SUSCRIBERs
        resteReserve = publication.reserve - lesSouscriptions.map((e) => e.reserve).reduce((a, b) => a + b);
      }
    }
    return retour;
  }

  // Update this :
  int updateReserveBagage(List<Publication> listePub) {
    return (listePub.where((pub) => pub.id == publication.id).first.reserve -
        (lesSouscriptions.isNotEmpty ? lesSouscriptions.map((e) => e.reserve).reduce((a, b) => a + b) : 0));
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
                                return ReservePaiement(publication: publication, client: widget.client);
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
              backgroundColor: MaterialStateColor.resolveWith((states) => historique ? Colors.grey : Colors.blue)
          ),
          label: const Text("Réserver",
              style: TextStyle(
                  color: Colors.white
              )),
          onPressed: () {
            //displayPaymentChoice();
            if(!historique){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context){
                        return ReservePaiement(publication: publication, client: widget.client,);
                      }
                  )
              );
            }
            else{
              // Display SNACKBAR :
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    duration: Duration(seconds: 3),
                    content: Text("La date est échue !")
                ),
              );
            }
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
        margin: const EdgeInsets.only(top: 40, left: 10, right: 10),
        child: Column(
          children: [
            Visibility(
              visible: (!historique && (publication.active < 2)),
              child: ElevatedButton.icon(
                style: ButtonStyle(
                    backgroundColor: MaterialStateColor.resolveWith((states) => const Color(
                        0xFFCB7228))
                ),
                label: const Text("Annuler",
                    style: TextStyle(
                        color: Colors.white
                    )),
                onPressed: () {
                  // Delete the 'PUBLICATION' :
                  dialogForPublicationDeletion(context);
                },
                icon: const Icon(
                  Icons.cancel,
                  size: 20,
                  color: Colors.white,
                ),
              )
            ),
            const SizedBox(
              height: 20,
            ),
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
              onLongPress: () async{
                if(!signalerReception) {
                  if (publication.active == 1) {
                    displayFloat(
                        'Le colis n\'a pas encore été remis !', choix: 1);
                  }
                  else if (publication.active == 2) {
                    setState(() {
                      signalerReception = true;
                    });
                  }
                  else {
                    displayFloat('Réception déjà établie !', choix: 1);
                  }
                }
                else{
                  setState(() {
                    signalerReception = false;
                  });
                }
              },
              onTap: () async {
                // Display DIALOG :
                /*if(!signalerReception) {
                  if (publication.active == 1) {
                    displayFloat(
                        'Le colis n\'a pas encore été remis !', choix: 1);
                  }
                  else if (publication.active == 2) {
                    setState(() {
                      signalerReception = true;
                    });
                  }
                  else {
                    displayFloat('Réception déjà établie !', choix: 1);
                  }
                }
                else{
                  setState(() {
                    signalerReception = false;
                  });
                }*/

                /*if(widget.streamclient.wsConnectionStatus == ConnectionStatus.connected){
                  final channel = widget.streamclient.channel('messaging', id: publication.streamchannelid);
                  channel.watch();
                  openStramChat(widget.streamclient, channel);
                }*/

                final result = await Navigator.push(context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Messagerie(idpub: publication.id, owner: ('${outil.getPublicationOwner()!.nom} ${outil.getPublicationOwner()!.prenom}'),
                        idSuscriber: outil.getPublicationOwner()!.id, client: widget.client);
                    }
                  )
                );
                if(result == '1'){
                  await outil.refreshAllChatsFromResumed(0);
                }
              },
              child: Container(
                  //margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  width: MediaQuery.of(context).size.width,
                  //color: Colors.brown[100],
                  child: Card(
                    color: signalerReception ?
                    const Color(0xFFD1EAD7) :
                    const Color(0xFFEFEFEB),
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
     bool retour = (signalerLivraison || signalerReception) ? false : true;
     if(!retour){
       setState(() {
         if(signalerLivraison) {
           indexSouscripteur = - 1;
           signalerLivraison = false;
         }
         else{
           signalerReception = false;
         }
       });
     }
     return retour;
  }


  // Send Account DATA :
  Future<void> sendLivraisonFalag() async {
    try{
      final url = Uri.parse('${dotenv.env['URL']}markdelivery');
      var response = await widget.client.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "idpub": publication.id,
            "iduser": iduser
          }));

      // Checks :
      if(response.statusCode.toString().startsWith('2')){
        Souscription souscription = await outil.getSouscriptionByIdpubAndIduser(publication.id, iduser);
        // Update it :
        Souscription souscriptionUpdate = Souscription(
            id: souscription.id,
            idpub: publication.id,
            iduser: iduser,
            millisecondes: souscription.millisecondes,
            reserve: souscription.reserve,
            statut: 1,
            streamchannelid: souscription.streamchannelid
        );
        await outil.updateSouscription(souscriptionUpdate);

        // Set FLAG :
        flagSendData = false;
      }
      else {
        displayFloat("Impossible de traiter la demande !");
      }
    }
    catch(e){
    }
    finally{
      closeAlertDialog = false;
    }

  }

  // Subscription DELETION :
  void subscriptionDeletion() async {
    final url = Uri.parse('${dotenv.env['URL']}cancelsuscription');
    var response = await widget.client.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idpub": publication.id,
          "iduser": iduser
        })).timeout(const Duration(seconds: timeOutValue));
    if(response.statusCode == 200){
      // Deactivate PUBLICATION :
      Publication pub = Publication(
          id: publication.id,
          userid: publication.userid,
          villedepart: publication.id,
          villedestination: publication.id,
          datevoyage: publication.datevoyage,
          datepublication: publication.datepublication,
          reserve: publication.reserve,
          active: 0,
          reservereelle: publication.reservereelle,
          souscripteur: publication.souscripteur,
          milliseconds: publication.milliseconds,
          identifiant: publication.identifiant,
          devise: publication.devise,
          prix: publication.prix,
          read: publication.read,
        streamchannelid: publication.streamchannelid
      );
      await outil.updatePublicationWithoutFurtherActions(pub);
      publicationDeletionDone = true;
    }
    flagDeletionData = false;
  }


  // Send DELETION request
  void publicationDeletion() async {
    final url = Uri.parse('${dotenv.env['URL']}canceltravel');
    var response = await widget.client.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idpub": publication.id,
          "iduser": 0
        })).timeout(const Duration(seconds: timeOutValue));
    if(response.statusCode == 200){
      // Deactivate PUBLICATION :
      Publication pub = Publication(
          id: publication.id,
          userid: publication.userid,
          villedepart: publication.villedepart,
          villedestination: publication.villedestination,
          datevoyage: publication.datevoyage,
          datepublication: publication.datepublication,
          reserve: publication.reserve,
          active: 0,
          reservereelle: publication.reservereelle,
          souscripteur: publication.souscripteur,
          milliseconds: publication.milliseconds,
          identifiant: publication.identifiant,
          devise: publication.devise,
          prix: publication.prix,
          read: publication.read,
          streamchannelid: publication.streamchannelid
      );
      await outil.removeDeletedPublication(pub);
      //await outil.updatePublicationWithoutFurtherActions(pub);
      publicationDeletionDone = true;
    }
    flagDeletionData = false;
  }


  // Send Account DATA :
  Future<void> sendReceptionFlag() async {
    try{
      final url = Uri.parse('${dotenv.env['URL']}markreceipt');
      var response = await widget.client.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "idpub": publication.id,
            "iduser": iduser
          }));

      // Checks :
      if(response.statusCode.toString().startsWith('2')){
        // Update the 'PUBLICATION' :
        Publication pub = Publication(
            id: publication.id,
            userid: publication.userid,
            villedepart: publication.villedepart,
            villedestination: publication.villedestination,
            datevoyage: publication.datevoyage,
            datepublication: publication.datepublication,
            reserve: publication.reserve,
            active: 3,
            reservereelle: publication.reservereelle,
            souscripteur: publication.souscripteur, // Use OWNER Id
            milliseconds: publication.milliseconds,
            identifiant: publication.identifiant,
            devise: publication.devise,
            prix: publication.prix,
            read: 1,
            streamchannelid: publication.streamchannelid
        );
        await outil.updatePublicationWithoutFurtherActions(pub);

        // Set FLAG :
        flagSendData = false;
      }
    }
    catch(e){
    }
    finally{
      closeAlertDialog = false;
    }
  }


  void displayFloat(String message, { int choix = 0}){
    
    switch(choix){
      case 0:
        Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 16.0
        );
        break;
      
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: const Duration(seconds: 3),
              content: Text(message)
          ),
        );
        break;
    }
  }


  void dialogForPublicationDeletion(BuildContext fContext) {
    showDialog(
        barrierDismissible: false,
        context: fContext,
        builder: (BuildContext context) {
          dialogContext = context;
          return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                  title: const Text('Attention'),
                  content: const SizedBox(
                      height: 70,
                      child: Column(
                        children: [
                          Text("Confirmer la suppression de cette publication ?"),
                          SizedBox(
                            height: 20,
                          )
                        ],
                      )
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, 'Cancel'),
                      child: const Text('NON'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        // Dispay new ALERTDIALOG
                        displayPublicationDeletion(fContext);
                      },
                      child: const Text('OUI'),
                    ),
                  ]
              ) );
        }
    );
  }


  void displayPublicationDeletion(BuildContext dContext) {
    // Display SYNCHRO :
    showDialog(
        barrierDismissible: false,
        context: dContext,
        builder: (BuildContext context) {
          dialogContext = context;
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
                title: const Text('Information'),
                content: Container(
                    height: 100,
                    child: const Column(
                      children: [
                        Text("Suppression en cours ..."),
                        SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                            height: 30.0,
                            width: 30.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              strokeWidth: 3.0, // Width of the circular line
                            )
                        )
                      ],
                    )
                )
            )
          );
        }
    );

    flagDeletionData = true;
    publicationDeletionDone = false;
    userOrSuscriber == 0 ? subscriptionDeletion() : publicationDeletion();

    // Run TIMER :
    Timer.periodic(
      const Duration(milliseconds: 1500),
          (timer) {
        // Update user about remaining time
        if(!flagDeletionData){
          Navigator.pop(dialogContext);
          timer.cancel();

          if(publicationDeletionDone) {
            // Display message :
            displayFloat('Opération effectuée !');
            // Leave SCREEN :
            Navigator.pop(context, 1);
          }
          else{
            displayFloat('Suppression de l\'annonce impossible');
          }
        }
      },
    );
  }



  // Display INTERFACE for SENDING DATA :
  void displayLoadingInterface(BuildContext dContext) {
    // Display SYNCHRO :
    showDialog(
        barrierDismissible: false,
        context: dContext,
        builder: (BuildContext context) {
          dialogContext = context;
          return AlertDialog(
              title: const Text('Information'),
              content: Container(
                  height: 100,
                  child: Column(
                    children: [
                      Text(signalerLivraison ? "Confirmation livraison ..." : "Confirmation réception ..."),
                      const SizedBox(
                        height: 20,
                      ),
                      const SizedBox(
                          height: 30.0,
                          width: 30.0,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            strokeWidth: 3.0, // Width of the circular line
                          )
                      )
                    ],
                  )
              )
          );
        }
    );

    flagSendData = true;
    closeAlertDialog = true;
    if(signalerLivraison){
      sendLivraisonFalag();
    }
    else{
      sendReceptionFlag();
    }

    // Run TIMER :
    Timer.periodic(
      const Duration(milliseconds: 1500),
          (timer) {
        // Update user about remaining time
        if(!closeAlertDialog){
          Navigator.pop(dialogContext);
          timer.cancel();

          if(!flagSendData){
            // Display message :
            displayFloat('Opération effectuée !');

            // Leave SCREEN :
            if(signalerReception){
              Navigator.pop(context);
            }
            else{
              setState(() {
                signalerLivraison = false;
              });
            }
          }
          else{
            displayFloat('Impossible de traiter l\'opération !');
          }
        }
      },
    );
  }


  // Display ACTION BUTTON for 'CONFIRMER LA LIVRAISON'
  Widget displayActionButton (BuildContext context) {
    return (signalerLivraison || signalerReception) ?
    IconButton(
        onPressed: () {
          // Send DATA to server :
          displayLoadingInterface(context);
        },
        icon: const Icon(Icons.offline_pin, color: Color(0xFF884106)))
    :
    const SizedBox(
      width: 1,
      height: 1
    );
  }

  String displayTitle() {
    if(userOrSuscriber == 1){
      return !signalerLivraison ? publication.identifiant : 'Confirmer la livraison';
    }
    else{
      return !signalerReception ? publication.identifiant : 'Confirmer la réception';
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                displayTitle(),
                textAlign: TextAlign.start,
              ),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )),
              actions: [
                displayActionButton (context)
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
                                      'Heure : ${processTime(publication.datevoyage.split("T")[1])}',
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
                              GetBuilder<PublicationGetController>(
                                builder: (PublicationGetController controller) {
                                  return Container(
                                    margin: const EdgeInsets.only(left: 10, top: 10, right: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('Initial : '),
                                            Text('${ controller.publicationData.where((pub) => pub.id == publication.id).first.reserve} Kg',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(userOrSuscriber == 0 ? 'Réservé : ' : 'Reste : '),
                                            Text(userOrSuscriber == 0 ?
                                            (
                                              '${ controller.publicationData.where((pub) => pub.id == publication.id).first.reservereelle} Kg'
                                            ) :
                                            '${updateReserveBagage(controller.publicationData)} Kg',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue
                                                )
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                }
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
                                    GetBuilder<PublicationGetController>(
                                      builder: (PublicationGetController controller) {
                                        return Text(
                                          formatPrice(controller.publicationData.where((pub) => pub.id == publication.id).first.prix),
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17
                                          ),
                                        );
                                      }
                                    )
                                  ],
                                ),
                              ),
                              userOrSuscriber == 0 ?
                              ((publication.active == 2 || publication.active == 3)?
                                  Container(
                                    margin: const EdgeInsets.only(left: 10, top: 20, right: 10),
                                    child: const Column(
                                      children: [
                                        Divider(
                                          color: Colors.black,
                                          height: 5,
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.clean_hands,
                                              size: 25,
                                              color: Color(0xFF037C0D),
                                            ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            Text('Le colis a été remis',
                                              style: TextStyle(
                                                  fontSize: 18
                                              ),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                              :
                                  const SizedBox(
                                    height: 2,
                                  )
                              )
                              :
                              const SizedBox(
                                height: 2,
                              )
                              ,
                              userOrSuscriber == 0 ?
                              displayOwnerOrReserverButton() :
                              GetBuilder<SouscriptionGetController>(
                                builder: (SouscriptionGetController controller) {
                                  return Column(
                                    children: [
                                      // if(souscription.statut == 0) |
                                      Visibility(
                                        visible: !historique,
                                        child: Container(
                                          alignment: Alignment.topLeft,
                                          margin: const EdgeInsets.only(left: 10, top: 30, right: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              ElevatedButton.icon(
                                                style: ButtonStyle(
                                                    backgroundColor: MaterialStateColor.resolveWith((states) => const Color(
                                                        0xFFCB7228))
                                                ),
                                                label: const Text("Annuler",
                                                    style: TextStyle(
                                                        color: Colors.white
                                                    )),
                                                onPressed: () async {
                                                  // Check if a DELIVRY has been already done for ONE SUBSCRIPTION :
                                                  List<Souscription> lesSous = await outil.getAllSouscriptionByIdpub(publication.id);
                                                  if(lesSous.where((souscription) => souscription.statut ==1).toList().length > 0){
                                                    displayFloat('Suppression impossible, un client a déjà reçu le colis', choix : 1);
                                                  }
                                                  else{
                                                    // Delete the 'PUBLICATION' :
                                                    dialogForPublicationDeletion(context);
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.cancel,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              ElevatedButton.icon(
                                                style: ButtonStyle(
                                                    backgroundColor: MaterialStateColor.resolveWith((states) => const Color(
                                                        0xFF049829))
                                                ),
                                                label: const Text("Modifier",
                                                    style: TextStyle(
                                                        color: Colors.white
                                                    )),
                                                onPressed: () async{
                                                  cUser ??= await outil.pickLocalUser();
                                                  // Get Paydepart from Ville depart :
                                                  paysDepart ??= await _paysRepository.findPaysById(villeDepart.paysid);
                                                  paysDestination ??= await _paysRepository.findPaysById(ville.paysid);
                                                  // Call :
                                                  openTravelForUpdate();
                                                },
                                                icon: const Icon(
                                                  Icons.update,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ),
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

                                            // Drop LOGIC there :
                                            Souscription tSous = lesSouscriptions.where((souscript) => souscript.iduser == listeUser[index].id).
                                            first;

                                            return GestureDetector(
                                              onLongPress: () async{
                                                if(!signalerLivraison) {
                                                  Souscription souscription = await outil
                                                      .getSouscriptionByIdpubAndIduser(
                                                      publication.id,
                                                      listeUser[index].id);
                                                  suscriberSouscription =
                                                      souscription;
                                                  if (souscription.statut ==
                                                      0) {
                                                    setState(() {
                                                      iduser =
                                                          listeUser[index].id;
                                                      indexSouscripteur = index;
                                                      signalerLivraison = true;
                                                    });
                                                  }
                                                  else {
                                                    displayFloat(
                                                        'Livraison déjà effectuée');
                                                  }
                                                }
                                                else{
                                                  setState(() {
                                                    signalerLivraison = false;
                                                  });
                                                }
                                              },
                                              onTap: () async {
                                                // Display DIALOG
                                                final result = await Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (context) {
                                                          return Messagerie(idpub: publication.id, owner: ('${listeUser[index].nom} ${listeUser[index].prenom}'),
                                                              idSuscriber: listeUser[index].id,
                                                            client: widget.client);
                                                        }
                                                    )
                                                );

                                                //
                                                if(result == '1'){
                                                  await outil.refreshAllChatsFromResumed(0);
                                                }

                                                /*Souscription souscription = await outil.getSouscriptionByIdpubAndIduser(publication.id, listeUser[index].id);
                                                if(widget.streamclient.wsConnectionStatus == ConnectionStatus.connected) {
                                                  final channel = widget.streamclient.channel(
                                                      'messaging', id: souscription.streamchannelid);
                                                  channel.watch();
                                                  openStramChat(widget.streamclient, channel);
                                                }*/

                                                if(!signalerLivraison) {
                                                  Souscription souscription = await outil
                                                      .getSouscriptionByIdpubAndIduser(
                                                      publication.id,
                                                      listeUser[index].id);
                                                  suscriberSouscription =
                                                      souscription;
                                                  if (souscription.statut ==
                                                      0) {
                                                    setState(() {
                                                      iduser =
                                                          listeUser[index].id;
                                                      indexSouscripteur = index;
                                                      signalerLivraison = true;
                                                    });
                                                  }
                                                  else {
                                                    displayFloat(
                                                        'Livraison déjà effectuée');
                                                  }
                                                }
                                                else{
                                                  setState(() {
                                                    signalerLivraison = false;
                                                  });
                                                }

                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(right: 10, left: 10, top: 15),
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.black,
                                                        width: 1
                                                    ),
                                                    color: (signalerLivraison && (indexSouscripteur==index)) ?
                                                      const Color(0xFFD1EAD7) :
                                                      const Color(0xFFEFEFEB),
                                                    borderRadius: BorderRadius.circular(16.0)
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(7),
                                                      child: Text('${lesSouscriptions.where((souscript) => souscript.iduser == listeUser[index].id).first.reserve} kg',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold
                                                      ),),
                                                    ),
                                                    Expanded(
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              margin: const EdgeInsets.only(left: 10, right: 10),
                                                              alignment: Alignment.centerLeft,
                                                              child: Text('${listeUser[index].nom} ${listeUser[index].prenom}',
                                                                  style: TextStyle(
                                                                      fontWeight: FontWeight.bold
                                                                  ))
                                                            ),
                                                            Container(
                                                              margin: const EdgeInsets.only(left: 10, top: 3, right: 10),
                                                              child: const Divider(
                                                                color: Colors.black,
                                                                height: 5,
                                                              ),
                                                            ),
                                                            Container(
                                                                margin: const EdgeInsets.only(left: 10, right: 10),
                                                                alignment: Alignment.centerLeft,
                                                                child: Text(tSous.statut == 0 ? 'Non livré' : 'Livraison effectuée',
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    color: tSous.statut == 0 ? Colors.redAccent : Colors.green
                                                                  ),
                                                                )
                                                            )
                                                          ],
                                                        )
                                                    )
                                                  ],
                                                ),
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