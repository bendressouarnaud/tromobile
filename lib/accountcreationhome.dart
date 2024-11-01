import 'dart:html';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tro/pageaccueil.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import 'authentification.dart';
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
    }
  }

  void openHomeScreen() {
    Navigator.push(
        contextG,
        MaterialPageRoute(builder:
            (context) =>
            WelcomePage(client: client)
        )
    );
  }

  void closeWindow() {
    Navigator.pop(contextG);
  }

  @override
  Widget build(BuildContext context) {

    // Track this :
    contextG = context;

    return FutureBuilder(
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
                    Icon(
                        Icons.account_circle_rounded,
                        size: 70
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          if(listePays.isNotEmpty){
                            final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder:
                                    (context) =>
                                        EcranCreationCompte(listeCountry: listePays, listeVille: listeVille, client: client, gUser: usr,
                                            returnValue: false)
                                )
                            );

                            if(result != null) {
                              // Request for Permission :
                              requestForNotificationPermission();

                              // Display new INTERFACE :
                              openHomeScreen();

                              // Close current INTERFACE :
                              closeWindow();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[400]
                        ),
                        child: Text ('Créer un compte',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )
                        )
                    ),
                    Container(
                        width: 160,
                        child: Divider(
                          height: 3,
                          color: Colors.black,
                          thickness: 1.0,
                        )
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) {
                                    return AuthentificationEcran(client: client, returnValue: true
                                      );
                                  }
                              )
                          );

                          if(result != null) {
                            // Request for Permission :
                            requestForNotificationPermission();

                            // Display new INTERFACE :
                            openHomeScreen();

                            // Close current INTERFACE :
                            closeWindow();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400]
                        ),
                        child: Text ('Identifiez-vous',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )
                        )
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
    );
  }

}