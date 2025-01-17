
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import 'authentification.dart';
import 'confirmermail.dart';
import 'ecrancreationcompte.dart';
import 'main.dart';
import 'models/pays.dart';
import 'models/user.dart';
import 'models/ville.dart';

class AccountCreationHome extends StatelessWidget {

  AccountCreationHome({ super.key });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: NewAccountCreationHome());
  }
}

class NewAccountCreationHome extends StatelessWidget {

  //
  final _paysRepository = PaysRepository();
  final _villeRepository = VilleRepository();
  final _userRepository = UserRepository();
  int cptInit = 0;
  late List<Pays> listePays;
  late List<Ville> listeVille;
  late BuildContext contextG;
  late BuildContext dialogContext;
  User? usr;

  //
  Future<List<Ville>> loadingPays() async {
    usr = await _userRepository.getConnectedUser();
    listePays = await _paysRepository.findAll();
    listeVille = await _villeRepository.findAll();
    return listeVille;
  }

  void requestForNotificationPermission() async{
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

      /*if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      } else {
      }*/

      //
      //displayDisplay();
      openApp();
    }
  }

  // Open MAIN app :
  void openApp() {

    Navigator.pop(contextG);

    Navigator
        .push(
        contextG,
        MaterialPageRoute(builder:
            (context) =>
            MyApp(client: client, streamclient: streamClient)
        )
    );
  }

  void displayDisplay() {
    showDialog(
        barrierDismissible: false,
        context: contextG,
        builder: (BuildContext context) {
          dialogContext = context;
          return AlertDialog(
              title: const Text('Information'),
              content: const SizedBox(
                  height: 70,
                  child: Column(
                    children: [
                      Text("L'application va redémarrer ou relancez la sinon !"),
                      SizedBox(
                        height: 20,
                      )
                    ],
                  )
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    /*Navigator.pop(context);
                        Navigator.pop(context);*/
                    Restart.restartApp();
                  },
                  child: const Text('OK'),
                ),
              ]
          );
        }
    );
  }

  void displayAccountValidation() async{
    Navigator.pop(contextG);

    Navigator
        .push(
        contextG,
        MaterialPageRoute(builder:
            (context) =>
            ConfirmerMail(client: client, tache: 0,)
        )
    );

    /*if (resultValidation != null) {
      // Request for Permission :
      requestForNotificationPermission();
    }
    else{
      closeApp();
    }*/
  }

  // Close doors :
  void closeApp() {
    // Close DOORS
    //Navigator.pop(contextG);
    Navigator.of(contextG).maybePop();
  }

  @override
  Widget build(BuildContext context) {

    // Track this :
    contextG = context;
    /*if(usr != null) {
      // Display SCREEn for ACCOUNT VALIDATION :
      Future.delayed(const Duration(milliseconds: 1500),
              () {
                displayAccountValidation();
          }
      );
    }*/

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // This is the theme of your application.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
        backgroundColor: Colors.white,
      ),
            body: FutureBuilder(
                future: Future.wait([ loadingPays() ]),
                builder: (BuildContext contextB, AsyncSnapshot<dynamic> snapshot){
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                    List<Ville> data = snapshot.data[0];
                    return Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                                Icons.account_circle_rounded,
                                size: 70
                            ),
                            ElevatedButton(
                                onPressed: () async {
                                  if(usr == null) {
                                    if (listePays.isNotEmpty) {
                                      final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder:
                                              (context) =>
                                              EcranCreationCompte(
                                                  listeCountry: listePays,
                                                  listeVille: listeVille,
                                                  client: client,
                                                  gUser: usr,
                                                  returnValue: true)
                                          )
                                      );

                                      if (result != null) {
                                        displayAccountValidation();
                                      }
                                      /*if (result != null) {
                                        final resultValidation = await Navigator
                                            .push(
                                            context,
                                            MaterialPageRoute(builder:
                                                (context) =>
                                                ConfirmerMail(client: client)
                                            )
                                        );

                                        if (resultValidation) {
                                          // Request for Permission :
                                          requestForNotificationPermission();
                                        }
                                      }*/
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[400]
                                ),
                                child: const Text ('Créer un compte',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )
                                )
                            ),
                            Container(
                                width: 160,
                                child: const Divider(
                                  height: 3,
                                  color: Colors.black,
                                  thickness: 1.0,
                                )
                            ),
                            ElevatedButton(
                                onPressed: () async {
                                  if(usr == null) {
                                    final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) {
                                              return AuthentificationEcran(
                                                  client: client,
                                                  returnValue: true
                                              );
                                            }
                                        )
                                    );

                                    if (result != null) {
                                      // Request for Permission :
                                      requestForNotificationPermission();
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[400]
                                ),
                                child: const Text ('Identifiez-vous',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )
                                )
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 70),
                              child: const Text('Powered by ANKK & Co',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold
                              ),),
                            )
                          ],
                        )
                    );
                  }
                  else {
                    return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          strokeWidth: 3.0, // Width of the circular line
                        )
                    );
                  }
                }
            )
        )
    );

    /*return ;*/
  }

}