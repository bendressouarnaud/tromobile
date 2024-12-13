import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:stream_chat/src/core/models/user.dart' as streamuser;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:http/http.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:tro/getxcontroller/getchatcontroller.dart';
import 'package:tro/models/pays.dart';
import 'package:tro/models/publication.dart';
import 'package:tro/models/ville.dart';
import 'package:tro/models/user.dart' as databaseuser;

import 'package:tro/repositories/parameters_repository.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/publication_repository.dart';
import 'package:tro/repositories/souscription_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';
import 'package:tro/screens/listannonce.dart';
import 'package:tro/services/servicegeo.dart';
import 'package:tro/skeleton.dart';
import 'package:tro/streamchat.dart';
import 'package:tro/streamcontroller/mycustomeventhandler.dart';

import 'annonces.dart';
import 'chatmanagement.dart';
import 'constants.dart';
import 'getxcontroller/getnavbarchat.dart';
import 'loadingpayment.dart';
import 'ecrancompte.dart';
import 'getxcontroller/getnavbarpublication.dart';
import 'getxcontroller/getparamscontroller.dart';
import 'getxcontroller/getpublicationcontroller.dart';
import 'getxcontroller/getusercontroller.dart';
import 'historique.dart';
import 'historiqueannonce.dart';
import 'httpbeans/countrydata.dart';
import 'httpbeans/countrydataunicodelist.dart';
import 'main.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/src/response.dart' as mreponse;

import 'managedeparture.dart';
import 'messagerie.dart';
import 'models/parameters.dart';
import 'models/souscription.dart';
import 'models/user.dart';


class WelcomePage extends StatefulWidget {
  final Client client;
  final StreamChatClient streamclient;
  const WelcomePage({Key? key, required this.client, required this.streamclient}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // A t t r i b u t e s  :
  int currentPageIndex = 0;
  bool displayFloatBut = true;
  late BuildContext dialogContext;
  late BuildContext dialogTownContext;
  bool _isLoading = false;
  bool callApi = false;
  late List<CountryData> listeCountry;
  late List<CountryData> listeTown;
  late CountryData paysDepartMenu;
  late Pays paysDepart;
  late Pays paysDestination;
  TextEditingController menuCountryDepartController = TextEditingController();
  TextEditingController menuCountryDestinationController = TextEditingController();
  final _paysRepository = PaysRepository();
  final _userRepository = UserRepository();
  final _villeRepository = VilleRepository();
  final _publicationRepository = PublicationRepository();
  final _souscriptionRepository = SouscriptionRepository();
  List<Pays> listePays = [];
  List<Ville> listeVille = [];
  late List<Publication> listePublication;
  databaseuser.User? cUser;
  final PublicationGetController _publicationController = Get.put(PublicationGetController());
  final UserGetController _userController = Get.put(UserGetController());
  final ParametersGetController _parametersController = Get.put(ParametersGetController());
  //
  late final AppLifecycleListener _listener;
  int taillePublicationNotRead = 0;
  int cptInitTaillePublication = 0;
  //
  int tailleChatNotRead = 0;
  late databaseuser.User locUser;
  bool streamUserConnected = false;
  //
  List<Publication> listePub = [];
  List<Souscription> listeSouscription = [];
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool checkNetworkConnected = false;

  // Try for a TEST :
  //late StreamChannelListController _listController;



  // M e t h o d  :
  @override
  void initState() {
    // Call first :
    //getPublicationNotRead();
    setupInteractedMessage();
    chechNotificationPermission();
    // Try THIS :
    //getPubAndSouscription();
    //initLocalConnection();

    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Initialize the AppLifecycleListener class and pass callbacks
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );

    // Run this to check :
    //outil.refreshAllChatsFromResumed(0);
    super.initState();
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    if(result.isNotEmpty && (result.first == ConnectivityResult.wifi || result.first == ConnectivityResult.mobile)){
      checkNetworkConnected = true;
    }
    else{
      checkNetworkConnected = true;
    }
    outil.setCheckNetworkConnected(checkNetworkConnected);
  }

  /*void checkPublicationNotRead() async {
    List<Publication> lte = await outil.findAllPublication();
    taillePublicationNotRead = lte.where((element) => element.read == 0).toList().length;
    print("taillePublicationNotRead INITIALISATION : $taillePublicationNotRead");
  }*/

  //
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      processIncomingFCMessage(initialMessage, true);
    }

    // Also handle any interaction when the app is in the background via a Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      processIncomingFCMessage(event, true);
    });
  }

  // Listen to the app lifecycle state changes
  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        //print('--------->      detached');
        //updateAppState('detached');
      case AppLifecycleState.resumed:
        // Try to refresh PUBLICATION from THERE :
        //print('--------->      resumed');
        outil.refreshAllPublicationsFromResumed();
      case AppLifecycleState.inactive:
        //print('--------->      inactive');
        if(outil.getListDate().isNotEmpty){
          // Check to CLEAN the LIST before being called in displayAnnonce(...) method of listannonce.dart
          outil.resetListe();
        }
        //updateAppState('inactive');
      case AppLifecycleState.hidden:
        //print('--------->      hidden');
        //updateAppState('hidden');
      case AppLifecycleState.paused:
        //print('--------->      paused');
        //updateAppState('paused');
    }
  }

  // Check if user has logged in and check if NOTIFICATIONs PERMISSIONs has been given :
  void chechNotificationPermission() async{
    databaseuser.User? usr = await outil.pickLocalUser();
    locUser = usr!;
    // We can request :
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if(apnsToken != null){
        initFire();
      }
    }
    else{
      initFire();
    }
  }

  // String
  String getFirstPrenomIfNeeded(String prenom){
    List<String> tp = prenom.split(" ");
    return tp[0];
  }

  void initLocalConnection() async {
    try {
      if(!(widget.streamclient.wsConnectionStatus == ConnectionStatus.connected)){

        final client = StreamChatCore
            .of(context)
            .client;
        final streamUser = streamuser.User(
            id: locUser.streamid,
            name: '${locUser.nom} ${getFirstPrenomIfNeeded(locUser.prenom)}'
        );

        await widget.streamclient.connectUser(
            streamUser,
            locUser.streamtoken);
        await client.updateUser(streamUser);
        //
        //print('Connexion ******** effectuée');
        streamUserConnected = true;

        // Register DEVICE if NOT :
        Parameters? prms = await _parametersController.refreshData();
        if(prms!.deviceregistered == 0) {
          //
          await client.addDevice(locUser.fcmtoken,
              defaultTargetPlatform == TargetPlatform.android ? PushProvider
                  .firebase : PushProvider.apn,
              pushProviderName: defaultTargetPlatform == TargetPlatform.android ? 'bagages_messaging' :
          'bagage_messaging_apn');
          // Update :
          prms = Parameters(id: prms.id,
              state: prms.state,
              travellocal: prms.travellocal,
              travelabroad: prms.travelabroad,
              notification: prms.notification,
              epochdebut: prms.epochdebut,
              epochfin: prms.epochfin,
              comptevalide: prms.comptevalide,
              deviceregistered: 1
          );
          await _parametersController.updateData(prms);
        }


        /*_listController = StreamChannelListController(
          client: widget.streamclient,
          eventHandler: MyCustomEventHandler(),
        );*/
      }
    }
    catch (e){
      //print('Impossible de connecter l\'utilisateur : $e');
      displaySnack('Impossible de connecter l\'utilisateur : $e');
    }
  }

  void displaySnack(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text(message)
      ),
    );
  }

  // Update things :
  void updateAppState(String state) async{
    Parameters? prms = await _parametersController.refreshData();
    prms = Parameters(id: prms != null ? prms.id : 1,
        state: state,
        travellocal: prms != null ? prms.travellocal : 500,
        travelabroad: prms != null ? prms.travelabroad : 5000,
        notification: prms != null ? prms.notification : 0,
        epochdebut: prms != null ? prms.epochdebut : 0,
        epochfin: prms != null ? prms.epochfin : 0,
      comptevalide: prms!.comptevalide,
      deviceregistered: prms!.deviceregistered,
    );
    await _parametersController.updateData(prms);
  }

  @override
  void dispose() {
    // Do not forget to dispose the listener
    _subscription.cancel();
    _listener.dispose();
    _parametersController.dispose();
    _userController.dispose();
    try {
      widget.streamclient.disconnectUser();
      widget.streamclient.closeConnection();
      widget.streamclient.dispose();
      //
      //print('DéConnexion effectuée');
    }
    catch (e){
      print('Opératio déConnexion : $e');
    }
    //_publicationController.dispose();
    super.dispose();
  }

  // Init Objects :
  Future<List<Publication>> initObjects() async {
    listePays = await _paysRepository.findAll();
    listeVille = await _villeRepository.findAll();
    // Get current user :
    cUser = await _userRepository.getConnectedUser();
    //
    List<Publication> lte = await outil.findAllPublication();//publicationData;
    if(!streamUserConnected) initLocalConnection();
    return lte;
  }

  void initFire() async {
    // Set Flag :
    //outil.setFcmFlag(true);
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        //showFlutterNotification(message, "Notification Commande", "");
        processIncomingFCMessage(message, false);
      });
    }
  }

  // Factoriser le code :
  void processIncomingFCMessage(RemoteMessage message, bool fromNotification) async{
    // Create Object :
    String tampon = message.data['type'];
    if(tampon == "message.new"){
      // From STREAM CHAT, Display 'MESSAGE' :
      displaySnack('Vous avez un nouveau message !!!');
    }
    else {
      int sujet = int.parse(message.data['sujet']);
      switch(sujet){
        case 1:
          if(!fromNotification) {
            Publication? publication = Servicegeo().generatePublication(message);
            if (publication != null) {
              // Check if this ONE exists ALREADY or NOT :
              Publication? pubCheck = await outil.findOptionalPublicationById(publication.id);
              if(pubCheck == null){
                // Create
                outil.addPublication(publication);
              }
              else{
                // Update :
                await outil.updatePublicationWithoutFurtherActions(publication);
              }
            }
          }
          else{
            // Open 'HistoriqueAnnonce'
            Publication pub = await outil.refreshPublication(int.parse(message.data['id']));
            Ville vDepart = await outil.getVilleById(int.parse(message.data['villedepart']));
            Ville vDest = await outil.getVilleById(int.parse(message.data['villedestination']));
            databaseuser.User? lUser = await outil.pickLocalUser();
            int userType = !(lUser!.id == int.parse(message.data['userid'])) ? 0 : 1;
            openHistoriqueAnnonce(pub, vDepart, vDest, userType, false);
          }
          break;

        case 2:
          if(!fromNotification) {
            // Create User if not exist :
            Servicegeo().processReservationNotif(message, outil);
          }
          else{
            // Open 'HistoriqueAnnonce'
            Publication pub = await outil.refreshPublication(int.parse(message.data['idpub']));
            Ville vDepart = await outil.getVilleById(pub.villedepart);
            Ville vDest = await outil.getVilleById(pub.villedestination);
            openHistoriqueAnnonce(pub, vDepart, vDest, 1, false);
          }
          break;

        case 3:
          if(!fromNotification) {
            // Create User if not exist :
            Servicegeo().processIncommingChat(message, outil, widget.client);
          }
          else{
            // Open 'CHAT'
            databaseuser.User usr = (await outil.findAllUserByIdin([int.parse(message.data['sender'])])).single;
            openMessage(int.parse(message.data['idpub']),
                ("${usr.nom} ${usr.prenom}"),
                usr.id
            );
          }
          break;

        case 4:
          if(!fromNotification) {
            // Create User if not exist :
            Servicegeo().performReservationCheck(message, outil);
          }
          else{
            // Open 'HistoriqueAnnonce'
            Publication pub = await outil.refreshPublication(int.parse(message.data['publicationid']));
            Ville vDepart = await outil.getVilleById(pub.villedepart);
            Ville vDest = await outil.getVilleById(pub.villedestination);
            openHistoriqueAnnonce(pub, vDepart, vDest, 0, false);
          }
          break;

        case 5:
        //
          Servicegeo().trackPublicationDelivery(message, outil);
          break;

        case 6:
          Servicegeo().markChatReceipt(message);
          break;

        case 7:
          Servicegeo().updatePublicationReserve(message);
          break;

        case 8:
          Servicegeo().deactivatePublicationFromOwner(message);
          break;

        case 9:
          Servicegeo().deactivateSubscription(message);
          break;

        case 10:
          Servicegeo().upgradeBonus(message);
          break;

        case 11:
          Servicegeo().updatePublicationChannelID(message);
          break;
      }
    }
  }

  void openHistoriqueAnnonce(Publication pub, Ville depart, Ville destination, int userType, bool historique){
    Navigator.push(context,
        MaterialPageRoute(
            builder: (context) {
              return HistoriqueAnnonce(
                  publication: pub,
                  ville: depart,
                  villeDepart: destination,
                  userOrSuscriber: userType,
                historique: historique,
                client: widget.client, streamclient: widget.streamclient,
              );
            }
        )
    );
  }

  void openMessage(int idpub, String username, int userId){
    Navigator.push(context,
        MaterialPageRoute(
            builder: (context) {
              return Messagerie(idpub: idpub, owner: username,
                  idSuscriber: userId, client: widget.client);
            }
        )
    );
  }


  Future<List<int>> produitLoading() async {
    List<int> posts = List.empty(growable: true);
    return posts;
  }

  String getTownValue(){
    return paysDepartMenu.iso3;
  }

  // Get COUNTRIES :
  Future<List<Pays>> countriesLoading() async {
    listePays = await _paysRepository.findAll();
    // Get current user :
    cUser = await _userRepository.getConnectedUser();

    if(listePays.isEmpty) {
      final url = Uri.parse('https://countriesnow.space/api/v0.1/countries/flag/unicode');
      var response = await get(url);
      if(response.statusCode == 200){
        CountryDataUnicodeList ct = CountryDataUnicodeList.fromJson(json.decode(response.body));
        List<CountryData> liste = List.empty(growable: true);
        for (CountryData i in ct.data.where((e) => (e.iso3 == "FRA" || e.iso3 == "CIV")).toList()) {
          if(i.name.length > 30){
            String countryName = "${i.name.substring(0, 29)}...";
            CountryData tmp = CountryData(name: countryName, iso2: i.iso2, iso3: i.iso3, unicodeFlag: i.unicodeFlag);
            liste.add(tmp);
            // Persist :
            Pays pys = Pays(id: 0, name: tmp.name, iso2: tmp.iso2, iso3: tmp.iso3, unicodeFlag: tmp.unicodeFlag);
            listePays.add(pys);
            _paysRepository.insert(pys);
          }
          else {
            liste.add(i);
            Pays pys = Pays(id: 0, name: i.name, iso2: i.iso2, iso3: i.iso3, unicodeFlag: i.unicodeFlag);
            listePays.add(pys);
            _paysRepository.insert(pys);
          }
        }
        //List<CountryData> liste = ct.data.where((e) => (e.iso3 == "FRA" || e.iso3 == "CIV")).toList();
        _isLoading = true;
        listeCountry = liste;
        paysDepartMenu = liste.first;
      } else {
        _isLoading = true;
        throw Exception('Failed to load album');
      }
    }
    else{
      _isLoading = true;
    }
    return listePays;
  }

  // Convert Pays => CountryData
  List<CountryData> convertPaysCountry(List<Pays> liste){
    List<CountryData> retour = [];
    for(Pays p in liste){
      retour.add(CountryData(name: p.name, iso2: p.iso2, iso3: p.iso3, unicodeFlag: p.unicodeFlag));
    }
    return retour;
  }

  // Just loading from DATABASE :
  void callForCountry(List<Pays> liste){ // BuildContext context

    // Init :
    paysDestination = liste.first;
    paysDepart = liste.first;
    bool? isChecked = true;

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext sContext) {
          dialogContext = sContext;
          return  AlertDialog(
            title: Text('Nouvelle annonce'),
            content: Container(
              height: 200,
              child: Column(
                children: [
                  Container(
                      alignment: Alignment.topCenter,
                      color: Colors.brown[100],
                      width: 300,
                      height: 100,
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
                      child: DropdownMenu<Pays>(
                          width: 230,
                          menuHeight: 250,
                          initialSelection: liste.first,
                          controller: menuCountryDepartController,
                          hintText: "Départ",
                          requestFocusOnTap: false,
                          enableFilter: false,
                          label: const Text('Pays de départ'),
                          // Initial Value
                          onSelected: (Pays? value) {
                            paysDepart = value!;
                          },
                          dropdownMenuEntries:
                          liste.map<DropdownMenuEntry<Pays>>((Pays menu) {
                            return DropdownMenuEntry<Pays>(
                                value: menu,
                                label: menu.name,
                                leadingIcon: Icon(Icons.map));
                          }).toList()
                      )
                  ),
                  Container(
                      alignment: Alignment.topCenter,
                      color: Colors.blue[100],
                      width: 300,
                      height: 100,
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
                      child: DropdownMenu<Pays>(
                          width: 230,
                          menuHeight: 250,
                          initialSelection: liste.first,
                          controller: menuCountryDestinationController,
                          hintText: "Destination",
                          requestFocusOnTap: false,
                          enableFilter: false,
                          label: const Text('Pays de destination'),
                          // Initial Value
                          onSelected: (Pays? value) {
                            paysDestination = value!;
                          },
                          dropdownMenuEntries:
                          liste.map<DropdownMenuEntry<Pays>>((Pays menu) {
                            return DropdownMenuEntry<Pays>(
                                value: menu,
                                label: menu.name,
                                leadingIcon: const Icon(Icons.map));
                          }).toList()
                      )
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(sContext, 'Cancel'),
                child: const Text('Annuler',
                  style: TextStyle(
                      color: Colors.brown
                  ),),
              ),
              TextButton(
                onPressed: () async {

                  List<CountryData> data = convertPaysCountry([paysDepart, paysDestination]);

                  // Close dialog
                  Navigator.pop(sContext);

                  /*final sClient = StreamChatClient('tbyj8qz6ucx7');
                  await sClient.connectUser(streamuser.User(id: 'ngbandamakonan'),
                      'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoibmdiYW5kYW1ha29uYW4iLCJpYXQiOjE3MzE4MzQzNDksImlzcyI6IlN0cmVhbSBDaGF0IEphdmEgU0RLIiwic3ViIjoiU3RyZWFtIENoYXQgSmF2YSBTREsifQ.Z_6Qv621l38j9WrSvijQUMN6qUKw9818qWsKnu1bCbw');
                  final channel = sClient.channel('messaging', id: 'flutterdevi');
                  channel.watch();

                  //
                  openStramChat(sClient, channel);*/

                  // Launch ACTIVITY if needed :
                  Navigator.push(
                      sContext,
                      MaterialPageRoute(
                          builder: (context){
                            return ManageDeparture(id: cUser!.id, listeCountry: [paysDepart, paysDestination],
                              nationalite: cUser!.nationnalite, idpub: 0,
                              client: widget.client);
                          }
                      )
                  );
                },
                child: const Text('Valider',
                  style: TextStyle(
                      color: greenAlertValidation
                  ),
                ),
              ),
            ]
          );
        }
    );
  }

  void clearNotifications() async{
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  void lookForData() async{
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Widget processAnnonceIcon(List<int> liste, IconData iconData) {
    taillePublicationNotRead = liste[0];
    if(taillePublicationNotRead > 0){

      // From There we can clear NOTIFICATIONS :
      clearNotifications();

      return Badge.count(
          count: taillePublicationNotRead,
          child: Icon(iconData)
      );
    }
    else {
      return Icon(iconData);
    }
  }

  //
  Widget processChatIcon(List<int> liste, IconData iconData) {
    tailleChatNotRead = liste[0];
    if(tailleChatNotRead > 0){

      // From There we can clear NOTIFICATIONS :
      //clearNotifications();

      return Badge.count(
          count: tailleChatNotRead,
          child: Icon(iconData)
      );
    }
    else {
      return Icon(iconData);
    }
  }

  // Get Publication & Souscription for which stramchannelId is set :
  void getPubAndSouscription() async {
    listePub = await _publicationRepository.findAll();// WithStreamId();
    listeSouscription = await _souscriptionRepository.findAllWithStreamId();
  }

  @override
  Widget build(BuildContext context) {
    //checkPublicationNotRead();
    return Scaffold(
        bottomNavigationBar: NavigationBar(
          indicatorShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              )),
          onDestinationSelected: (int index) async {
            // Refresh the LISTS
            if(index == 1){
              listePub = await _publicationRepository.findAll();// WithStreamId();
              listeSouscription = await _souscriptionRepository.findAllWithStreamId();
            }
            //getPubAndSouscription();

            // Set the refresh CHECK there too :
            if(outil.getListDate().isNotEmpty){
              // Check to CLEAN the LIST before being called in displayAnnonce(...) method of listannonce.dart
              outil.resetListe();
            }

            setState(() {
              displayFloatBut = index == 0 ? true : false;
              currentPageIndex = index;
            });
          },
          indicatorColor: Colors.blue[100],
          selectedIndex: currentPageIndex,
          destinations:  [
            GetBuilder<NavGetController>(
              builder: (NavGetController controller)  {
                return NavigationDestination(
                  selectedIcon: processAnnonceIcon(controller.tableau, Icons.announcement), //Icon(Icons.announcement),
                  icon: processAnnonceIcon(controller.tableau, Icons.announcement_outlined),//Icon(Icons.announcement_outlined),
                  label: 'Annonces',
                );
              }
            ),
            GetBuilder<NavChatGetController>(
                builder: (controller) {
                  return NavigationDestination(
                    selectedIcon: processChatIcon(controller.tableau, Icons.chat_bubble),
                    icon: processChatIcon(controller.tableau, Icons.chat_bubble_outline),
                    label: 'Chat',
                  );
                }
            ),
            const NavigationDestination(
              selectedIcon: Icon(Icons.access_time_filled),
              icon: Icon(Icons.access_time),
              label: 'Historique',
            ),
            const NavigationDestination(
              selectedIcon: Icon(Icons.account_circle_rounded),
              icon: Icon(Icons.account_circle_outlined),
              label: 'Compte',
            ),
          ],
        ),
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "CoBagage",
            textAlign: TextAlign.left,
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )
          ),
          /*actions: [
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: Colors.black))
          ],*/
        ),
        floatingActionButton: Visibility(
          visible: displayFloatBut,
          child: FloatingActionButton(
            backgroundColor: const Color.fromRGBO(51, 159, 255, 1.0),
            tooltip: 'Nouvelle commande',
            onPressed: () async{
              databaseuser.User? usr = await outil.pickLocalUser();
              if(usr != null){
                // Init if needed
                cUser ??= usr;
                //
                callForCountry(listePays);
              }
              else{
                Fluttertoast.showToast(
                    msg: "Veuillez créer votre compte !",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0
                );
              }
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
        body: <Widget>[
          FutureBuilder(
            future: Future.wait([initObjects()]),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                listePublication = snapshot.data[0];
                return GetBuilder<PublicationGetController>(
                    builder: (PublicationGetController controller) {
                      // Sort :
                      var milliseconds = DateTime.now().millisecondsSinceEpoch;
                      List<Publication> reste = controller.publicationData.
                        where((pub) => (pub.milliseconds >= milliseconds ))
                          .toList(); //  && pub.active == 1))
                      reste.sort((a,b) =>
                          b.id.compareTo(a.id));
                      return SingleChildScrollView(
                        child: EcranAnnonce().displayAnnonce(reste
                            , listePays, listeVille,
                        _userController.userData ,context, false, widget.client, widget.streamclient,
                        controller.souscriptionData),
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
          ),
          AnnoncesUsers(streamclient: widget.streamclient, listePublication: listePub, listeSouscription: listeSouscription),//ChatManagement(client: widget.client),
          Historique(client: widget.client, streamclient: widget.streamclient),
          EcranCompte(client: widget.client),
        ][currentPageIndex]);
  }
}

class NewsCardSkelton extends StatelessWidget {
  const NewsCardSkelton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      baseColor: Colors.black,
      highlightColor: Colors.grey[500]!,
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: const Skeleton(height: 120, width: 120),
          ),
          const SizedBox(width: defaultPadding),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 80),
                SizedBox(height: defaultPadding / 2),
                Skeleton(),
                SizedBox(height: defaultPadding / 2),
                Skeleton(),
                SizedBox(height: defaultPadding / 2),
                Row(
                  children: [
                    Expanded(
                      child: Skeleton(),
                    ),
                    SizedBox(width: defaultPadding),
                    Expanded(
                      child: Skeleton(),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ));
}
