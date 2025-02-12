import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tro/ecranfiliation.dart';
import 'package:tro/main.dart';
import 'package:tro/models/ville.dart';
import 'package:tro/repositories/cible_repsository.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';
import 'authentification.dart';
import 'confidentialite.dart';
import 'constants.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as https;

import 'ecrancreationcompte.dart';
import 'gestioncible.dart';
import 'getxcontroller/getusercontroller.dart';
import 'httpbeans/countrydata.dart';
import 'managenotifications.dart';
import 'models/pays.dart';
import 'models/user.dart';



class EcranCompte extends StatefulWidget {
  final Client client;
  EcranCompte({Key? key, required this.client}) : super(key: key);

  @override
  State<EcranCompte> createState() => _NewEcranState();
}

class _NewEcranState extends State<EcranCompte> {
  // A t t r i b u t e s  :
  late bool _isLoading;
  int callNumber = 0;
  int currentPageIndex = 0;
  //final UserBloc userBloc = UserBloc();
  int idcli = 12;
  String selection = "";
  //
  final UserGetController _userController = Get.put(UserGetController());
  //late https.Client client;
  late BuildContext dialogContext;
  bool accountDeletion = false;
  final _paysRepository = PaysRepository();
  final _villeRepository = VilleRepository();
  final _userRepository = UserRepository();
  final _cibleRepository = CibleRepository();
  int cptInit = 0;
  late List<Pays> listePays;
  late List<Ville> listeVille;
  User? usr;



  // M e t h o d  :
  @override
  void initState() {
    //client = widget.client;
    loadingPays();
    super.initState();
  }

  //
  void loadingPays() async {
    //
    usr = await _userRepository.getConnectedUser();
    listePays = await _paysRepository.findAll();
    listeVille = await _villeRepository.findAll();
  }

  void callFiliationInterface() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return GestionFiliation(client: widget.client, userId: usr!.id);
        }));
  }

  // Display Notification when ACCOUNT Created and NOTIFICATION PERMISSION not given yet :
  String requestNotificationPermission() {

    if(_userController.userData.isNotEmpty) {
      // Set timer to
      Future.delayed(const Duration(milliseconds: 600),
              () async {
            FirebaseMessaging messaging = FirebaseMessaging.instance;
            NotificationSettings settings = await messaging
                .getNotificationSettings();
            if (settings.authorizationStatus !=
                AuthorizationStatus.authorized) {
              // Request for it :
              NotificationSettings settings = await messaging.requestPermission(
                alert: true,
                announcement: false,
                badge: true,
                carPlay: false,
                criticalAlert: false,
                provisional: false,
                sound: true,
              );
            }
          }
      );
    }

    return _userController.userData.isEmpty ? "CRÉER COMPTE" : "MON COMPTE";
  }


  // Convert Pays => CountryData
  Future<List<CountryData>> convertPaysCountry() async{
    List<CountryData> retour = [];
    List<Pays> listePays = await _paysRepository.findAll();
    for(Pays p in listePays){
      retour.add(CountryData(name: p.name, iso2: p.iso2, iso3: p.iso3, unicodeFlag: p.unicodeFlag));
    }
    _isLoading = true;
    return retour;
  }

  // Just loading from DATABASE :
  Future<void> callForCountry(BuildContext context) async {
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

    _isLoading = false;
    List<CountryData> data = await convertPaysCountry();

    // Run TIMER :
    Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        // Update user about remaining time
        if(_isLoading){

          Navigator.pop(dialogContext);
          timer.cancel();

          /*Navigator.push(
              context,
              MaterialPageRoute(builder:
                  (context) =>
                  EcranCreationCompte(listeCountry: data)
              )
          );*/
        }
      },
    );
  }

  void displayCreationAccount() {
    if(listePays.isNotEmpty){
      Navigator.push(
          context,
          MaterialPageRoute(builder:
              (context) =>
              EcranCreationCompte(listeCountry: listePays, listeVille: listeVille, client: widget.client, gUser: usr,
                returnValue: false)
          )
      );
    }
  }


  // Delete ACHAT
  void deleteAccount() async {
    // Delete account from USER :
    await _cibleRepository.deleteAllCibles();
    await outil.deleteAllUsers();
    await outil.deleteAllPublications();
    accountDeletion = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        /*appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text("Gouabo", textAlign: TextAlign.start, ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )
          ),
          actions: [
            IconButton(
                onPressed: (){},
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black,)
            ),
            IconButton(
                onPressed: (){},
                icon: const Icon(Icons.search, color: Colors.black)
            )
          ],
        ),*/
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(right: 7, left: 7),
              color: Colors.black,
              child: Row(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text ("Bonjour\nGérer vos données",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )
                    ) ,
                  ),
                  Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: ElevatedButton(
                            onPressed: () async {
                              usr = await _userRepository.getConnectedUser();
                              displayCreationAccount();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[400]
                            ),
                            child: GetBuilder<UserGetController>(
                              builder: (_) {
                                return Text (requestNotificationPermission(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )
                                );
                              },
                            )

                        ),
                      )
                  )
                ],
              ),
            ),
            Container(
                padding: const EdgeInsets.only(right: 7, left: 7),
                margin: const EdgeInsets.only(top: 10),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: Text("MON COMPTE",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                )
            ),
            GetBuilder<UserGetController>(
                builder: (_) {
                  return _userController.userData.isEmpty ?
                  Container() :
                  Column (
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 20, left: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right_sharp,
                              color: Colors.black,
                              size: 30,
                            ),
                            GestureDetector(
                              onTap: () {
                                // Display DIALOG
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                      return GestionCible(client: widget.client,);
                                    }));
                              },
                              child: const Text('Cibles',
                                style: TextStyle(
                                    fontSize: 18
                                ),
                              ),
                            )

                          ],
                        ),
                      ),
                      Container(
                          margin: const EdgeInsets.only(top: 10, left: 15, right: 15),
                          child: const Divider(
                            height: 2,
                            color: Colors.black,
                          )
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10, left: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right_sharp,
                              color: Colors.black,
                              size: 30,
                            ),
                            GestureDetector(
                              onTap: () {
                                // Display DIALOG
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                      return ManageNotification(client: widget.client);
                                    }));
                              },
                              child: const Text('Périodes de notification',
                                style: TextStyle(
                                    fontSize: 18
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                          margin: const EdgeInsets.only(top: 10, left: 15, right: 15),
                          child: const Divider(
                            height: 2,
                            color: Colors.black,
                          )
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10, left: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right_sharp,
                              color: Colors.black,
                              size: 30,
                            ),
                            GestureDetector(
                              onTap: () async{
                                // Display DIALOG
                                usr ??= await _userRepository.getConnectedUser();
                                callFiliationInterface();
                              },
                              child: const Text('Filiations & Soldes',
                                style: TextStyle(
                                    fontSize: 18
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                      Container(
                          margin: const EdgeInsets.only(top: 10, left: 15, right: 15),
                          child: const Divider(
                            height: 2,
                            color: Colors.black,
                          )
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10, left: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right_sharp,
                              color: Colors.black,
                              size: 30,
                            ),
                            GestureDetector(
                              onTap: () {
                                // Display DIALOG
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                      return PolitiqueConfidentialite.setAction(1);
                                    }));
                              },
                              child: const Text('Politique de confidentialité',
                                style: TextStyle(
                                    fontSize: 18
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  );
                }
            ),
            const SizedBox(
              height: 100,
            ),
            Container(
                alignment: Alignment.center,
                child: GetBuilder<UserGetController>(
                  builder: (_) {
                    return _userController.userData.isEmpty ? GestureDetector(
                      onTap: () {
                        // Display
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return AuthentificationEcran(client: widget.client, returnValue: false);
                            }
                            )
                        );
                      },
                      child: Text("Vous possédez déjà un compte ?",
                        style: TextStyle(
                            color: Colors.deepOrange[600],
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ) : Container();
                  },
                )
            ),
            Container(
                alignment: Alignment.center,
                child: GetBuilder<UserGetController>(
                  builder: (_) {
                    return _userController.userData.isNotEmpty ? GestureDetector(
                      onTap: () {
                        if(!accountDeletion) {
                          // Display
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                dialogContext = context;
                                return WillPopScope(
                                    onWillPop: () async => false,
                                    child: AlertDialog(
                                        title: const Text('Information'),
                                        content: const SizedBox(
                                          height: 80,
                                          child: Column(
                                            children: [
                                              Text("Confirmer la suppression de votre compte ?"),
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
                                              accountDeletion = true;

                                              deleteAccount();

                                              // Run TIMER :
                                              Timer.periodic(
                                                const Duration(milliseconds: 500),
                                                    (timer) {
                                                  // Update user about remaining time
                                                  if (!accountDeletion) {
                                                    timer.cancel();
                                                    Navigator.pop(dialogContext);

                                                    //
                                                    if (_userController.userData
                                                        .isEmpty) {
                                                      // Kill ACTIVITY :
                                                      if (Navigator.canPop(
                                                          context)) {
                                                        Navigator.pop(context);
                                                      }
                                                    }
                                                    else {
                                                      setState(() {});
                                                    }
                                                  }
                                                },
                                              );
                                            },
                                            child: const Text('OUI'),
                                          ),
                                        ]
                                    ) );
                              }
                          );
                        }
                        else{
                          Fluttertoast.showToast(
                              msg: "Un processus est en cours ...",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0
                          );
                        }
                      },
                      child: Text("Supprimez votre compte !",
                        style: TextStyle(
                            color: Colors.deepOrange[600],
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ) : Container();
                  },
                )
            )
          ],
        )
    );
  }
}
