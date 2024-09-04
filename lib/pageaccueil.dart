import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:http/http.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tro/models/pays.dart';
import 'package:tro/models/publication.dart';
import 'package:tro/models/ville.dart';
import 'package:tro/repositories/parameters_repository.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/publication_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';
import 'package:tro/screens/listannonce.dart';
import 'package:tro/services/servicegeo.dart';
import 'package:tro/skeleton.dart';

import 'constants.dart';
import 'ecrancompte.dart';
import 'getxcontroller/getparamscontroller.dart';
import 'getxcontroller/getpublicationcontroller.dart';
import 'getxcontroller/getusercontroller.dart';
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
  const WelcomePage({Key? key})
      : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // A t t r i b u t e s  :
  int currentPageIndex = 0;
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
  List<Pays> listePays = [];
  List<Ville> listeVille = [];
  late List<Publication> listePublication;
  User? cUser;
  //final PublicationGetController _publicationController = Get.put(PublicationGetController());
  final UserGetController _userController = Get.put(UserGetController());
  final ParametersGetController _parametersController = Get.put(ParametersGetController());
  //
  //late final AppLifecycleListener _listener;


  // M e t h o d  :
  @override
  void initState() {

    // Call first :
    setupInteractedMessage();
    chechNotificationPermission();

    // Initialize the AppLifecycleListener class and pass callbacks
    /*_listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );*/

    // Init FireBase :
    super.initState();
  }

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
        print('--------->      detached');
        //updateAppState('detached');
      case AppLifecycleState.resumed:
        print('--------->      resumed');
        //updateAppState('resumed');
      case AppLifecycleState.inactive:
        print('--------->      inactive');
        //updateAppState('inactive');
      case AppLifecycleState.hidden:
        print('--------->      hidden');
        //updateAppState('hidden');
      case AppLifecycleState.paused:
        print('--------->      paused');
        //updateAppState('paused');
    }
  }

  // Check if user has logged in and check if NOTIFICATIONs PERMISSIONs has been given :
  void chechNotificationPermission() async{
    User? usr = await outil.pickLocalUser();
    //FirebaseMessaging messaging = FirebaseMessaging.instance;
    //NotificationSettings settings = await messaging.getNotificationSettings();
    if(usr != null){
      // We can request :
      if (defaultTargetPlatform == TargetPlatform.android) {
        initFire();
      }
    }
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
    );
    await _parametersController.updateData(prms);
  }

  @override
  void dispose() {
    // Do not forget to dispose the listener
    //_listener.dispose();
    _parametersController.dispose();
    _userController.dispose();
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
        //
        //showFlutterNotification(message, "Notification Commande", "");

        Fluttertoast.showToast(
            msg: "Notification Commande ${message.data['sujet']}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );

        //
        processIncomingFCMessage(message, false);
      });
    }
  }

  // Factoriser le code :
  void processIncomingFCMessage(RemoteMessage message, bool fromNotification) async{
    // Create Object :
    int sujet = int.parse(message.data['sujet']);
    switch(sujet){
      case 1:
        if(!fromNotification) {
          Publication? publication = Servicegeo().generatePublication(message);
          if (publication != null) {
            outil.addPublication(publication);
          }
        }
        else{
          // Open 'HistoriqueAnnonce'
          Publication pub = await outil.refreshPublication(int.parse(message.data['id']));
          Ville vDepart = await outil.getVilleById(int.parse(message.data['villedepart']));
          Ville vDest = await outil.getVilleById(int.parse(message.data['villedestination']));
          User? lUser = await outil.pickLocalUser();
          int userType = !(lUser!.id == int.parse(message.data['userid'])) ? 0 : 1;
          openHistoriqueAnnonce(pub, vDepart, vDest, userType);
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
          openHistoriqueAnnonce(pub, vDepart, vDest, 1);
        }
        break;

      case 3:
        if(!fromNotification) {
          // Create User if not exist :
          Servicegeo().processIncommingChat(message, outil);
        }
        else{
          // Open 'CHAT'
          User usr = (await outil.findAllUserByIdin([0])).single;
          openMessage(int.parse(message.data['idpub']),
              ("${usr.nom} ${usr.prenom}"),
              usr.id
          );
        }
        break;
    }
  }

  void openHistoriqueAnnonce(Publication pub, Ville depart, Ville destination, int userType){
    Navigator.push(context,
        MaterialPageRoute(
            builder: (context) {
              return HistoriqueAnnonce(
                  publication: pub,
                  ville: depart,
                  villeDepart: destination,
                  userOrSuscriber: userType
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
                  idSuscriber: userId);
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
                onPressed: () {

                  List<CountryData> data = convertPaysCountry([paysDepart, paysDestination]);

                  // Close dialog
                  Navigator.pop(sContext);

                  // Launch ACTIVITY if needed :
                  Navigator.push(
                      sContext,
                      MaterialPageRoute(
                          builder: (context){
                            return ManageDeparture(id: cUser!.id, listeCountry: [paysDepart, paysDestination], nationalite: cUser!.nationnalite, idpub: 0,);
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

  Widget processAnnonceIcon(List<Publication> liste, IconData iconData) {
    int taille = liste.where((element) => element.read == 0).toList().length;
    if(taille > 0){

      // From There we can clear NOTIFICATIONS :
      clearNotifications();

      return Badge.count(
          count: taille,
          child: Icon(iconData)
      );
    }
    else {
      return Icon(iconData);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: NavigationBar(
          indicatorShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              )),
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Colors.blue[100],
          selectedIndex: currentPageIndex,
          destinations:  [
            GetBuilder<PublicationGetController>(
              builder: (PublicationGetController controller)  {
                return NavigationDestination(
                  selectedIcon: processAnnonceIcon(controller.publicationData, Icons.announcement), //Icon(Icons.announcement),
                  icon: processAnnonceIcon(controller.publicationData, Icons.announcement_outlined),//Icon(Icons.announcement_outlined),
                  label: 'Annonces',
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
            "Trô",
            textAlign: TextAlign.start,
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )),
          actions: [
            /*badges.Badge(
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                badgeAnimation: const badges.BadgeAnimation.slide(),
                showBadge: true,
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: Colors.red,
                ),
                badgeContent: GetBuilder<AchatGetController>(
                  builder: (_) {
                    return Text(
                      '${_achatController.taskData.length}',
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
                child: IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                            return Paniercran(client: client);
                          }));
                    })),*/
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: Colors.black))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromRGBO(51, 159, 255, 1.0),
          tooltip: 'Nouvelle commande',
          onPressed: () async{
            User? usr = await outil.pickLocalUser();
            if(usr != null){
              //callForCountry(context, listePays);
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
        body: <Widget>[

          FutureBuilder(
            future: Future.wait([initObjects()]),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                listePublication = snapshot.data[0];
                return GetBuilder<PublicationGetController>(
                    builder: (PublicationGetController controller) {
                      return SingleChildScrollView(
                        child: EcranAnnonce().displayAnnonce(controller.publicationData, listePays, listeVille,
                        _userController.userData ,context),
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
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: const Center(
              child: Text(
                "Veuillez créer votre compte",
                style: TextStyle(fontSize: 17, color: Colors.black),
              ),
            ),
          ),
          EcranCompte(),
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
