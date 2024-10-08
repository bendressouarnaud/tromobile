import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:http/src/response.dart' as mreponse;
import 'package:tro/getxcontroller/getsouscriptioncontroller.dart';
import 'package:tro/repositories/filiation_repository.dart';
import 'package:tro/repositories/user_repository.dart';

import 'constants.dart';
import 'getxcontroller/getciblecontroller.dart';
import 'getxcontroller/getpublicationcontroller.dart';
import 'getxcontroller/getusercontroller.dart';
import 'httpbeans/authenticateresponse.dart';
import 'httpbeans/souscriptionbean.dart';
import 'httpbeans/userbean.dart';
import 'models/cible.dart';
import 'models/filiation.dart';
import 'models/publication.dart';
import 'models/souscription.dart';
import 'models/user.dart';
import 'package:http/http.dart' as https;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;


class AuthentificationEcran extends StatefulWidget {
  final Client client;
  const AuthentificationEcran({Key? key, required this.client}) : super(key: key);
  //final https.Client client;

  @override
  State<AuthentificationEcran> createState() => _NewAuth();
}

class _NewAuth extends State<AuthentificationEcran> {

  // LINK :
  // https://api.flutter.dev/flutter/material/AlertDialog-class.html

  // A t t r i b u t e s  :
  TextEditingController emailController = TextEditingController();
  TextEditingController pwdController = TextEditingController();
  late bool _isLoading;
  // Initial value :
  var dropdownvalue = "Koumassi";
  String defaultGenre = "M";
  final lesGenres = ["M", "F"];
  final _userRepository = UserRepository();
  late BuildContext dialogContext;
  bool flagSendData = false;
  bool closeAlertDialog = false;
  //
  final UserGetController _userController = Get.put(UserGetController());
  final CibleGetController _cibleController = Get.put(CibleGetController());
  final PublicationGetController _publicationController = Get.put(PublicationGetController());
  final SouscriptionGetController _souscriptionController = Get.put(SouscriptionGetController());
  final _filiationRepository = FiliationRepository();
  //late https.Client client;
  //
  String? getToken = "";
  bool user_Company = false;



  // M E T H O D S
  @override
  void initState() {
    super.initState();

    //client = widget.client!;
  }


  // Process :
  bool checkField(){
    if(emailController.text.isEmpty || pwdController.text.isEmpty){
      return true;
    }
    return false;
  }


  //
  void generateTokenSuscription() async {
    await FirebaseMessaging.instance.subscribeToTopic("gouabocross");
    getToken = await FirebaseMessaging.instance.getToken();
    authenicatemobilecustomer();
  }


  // Send Account DATA :
  Future<void> authenicatemobilecustomer() async {
    final url = Uri.parse('${dotenv.env['URL']}authenticate');
    var response = await widget.client.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "mail": emailController.text,
        "pwd": pwdController.text,
        "fcmtoken": getToken
      })
    ).timeout(const Duration(seconds: timeOutValue));

    // Checks :
    if(response.statusCode == 200){
      //List<dynamic> body = jsonDecode(response.body);
      AuthenticateResponse bn = AuthenticateResponse.fromJson(jsonDecode(const Utf8Decoder().convert(response.bodyBytes)));
      // Persist user :
      User user = User(
          nationnalite: bn.nationnalite,
          id: bn.id,
          typepieceidentite: bn.typepieceidentite,
          numeropieceidentite: bn.numeropieceidentite,
          nom: bn.nom,
          prenom: bn.prenom,
          email: bn.email,
          numero: bn.numero,
          adresse: bn.adresse,
          fcmtoken: getToken!,
          pwd: "",
          codeinvitation: "",
          villeresidence: bn.villeresidence);
      // Save :
      _userController.addData(user);

      // From there, Hit NEW FILIATION :
      Filiation filiation = Filiation(id: 1, code: bn.codeparrainage, bonus: bn.bonus);
      await _filiationRepository.insert(filiation);

      // Persist CIBLE :
      for(Cible ce in bn.cibles){
        Cible cible = Cible(id: ce.id,
            villedepartid: ce.villedepartid,
            paysdepartid: ce.paysdepartid, villedestid: ce.villedestid, paysdestid: ce.paysdestid, topic: ce.topic);
        _cibleController.addData(cible);
      }
      // Persist PUBLICATION
      for(Publication publication in bn.publications){
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
        _publicationController.addData(pub);
      }

      // If the one connected has created PUBLICATION suscribed by PEOPLE, save them :
      for(UserBean userbean in bn.souscripteurs){
        User? user = await _userRepository.findById(userbean.iduser);
        if(user == null){
          // Persist DATA :
          // Create new :
          user = User(nationnalite: userbean.nationalite,
              id: userbean.iduser,
              typepieceidentite: '',
              numeropieceidentite: '',
              nom: userbean.nom,
              prenom: userbean.prenom,
              email: '',
              numero: '',
              adresse: userbean.adresse,
              fcmtoken: '',
              pwd: "123",
              codeinvitation: "123",
              villeresidence: 0);
          // Save :
          _userController.addData(user);
        }
      }

      // To close, persist 'SUBSCRIPTION' if needed :
      for(SouscriptionBean souscriptionBean in bn.sosucriptions){
        Souscription souscription = Souscription(
            id: 0,
            idpub: souscriptionBean.idpub,
            iduser: souscriptionBean.iduser,
            millisecondes: souscriptionBean.millisecondes,
            reserve: souscriptionBean.reserve,
            statut: souscriptionBean.statut);
        _souscriptionController.addData(souscription);
      }

      // Set FLAG :
      closeAlertDialog = false;
    }
    else{
      Fluttertoast.showToast(
          msg: "Identifiants incorrects",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }
    // Notify :
    flagSendData = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 60, left: 10),
                  child: const Align(
                    alignment: Alignment.topLeft,
                    child: Icon(
                      Icons.account_circle,
                      color: Colors.brown,
                      size: 80.0,
                    ),
                  ) ,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20, left: 10),
                  child: const Align(
                    alignment: Alignment.topLeft,
                    child: Text("Authentification",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        )
                    ),
                  ) ,
                ),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email...',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: pwdController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Mot de passe...',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith((states) => Colors.blueGrey)
                        ),
                        label: const Text("Retour",
                            style: TextStyle(
                                color: Colors.white
                            )),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith((states) => Colors.brown)
                        ),
                        label: const Text("Soumettre",
                            style: TextStyle(
                                color: Colors.white
                            )
                        ),
                        onPressed: () {
                          if(checkField()){
                            Fluttertoast.showToast(
                                msg: "Veuillez renseigner les champs !",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 16.0
                            );
                          }
                          else{
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext context) {
                                  dialogContext = context;
                                  return WillPopScope(
                                      onWillPop: () async => false,
                                      child: const AlertDialog(
                                          title: Text('Information'),
                                          content: SizedBox(
                                              height: 100,
                                              child: Column(
                                                children: [
                                                  Text("Veuillez patienter ..."),
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

                            // Send DATA :
                            flagSendData = true;
                            closeAlertDialog = true;
                            if(defaultTargetPlatform == TargetPlatform.android){
                              generateTokenSuscription();//
                            }
                            else{
                              // Currently not running FCM for iphone
                              authenicatemobilecustomer();
                            }

                            // Run TIMER :
                            Timer.periodic(
                              const Duration(seconds: 1),
                                  (timer) {
                                // Update user about remaining time
                                if(!flagSendData){
                                  Navigator.pop(dialogContext);
                                  timer.cancel();

                                  if(!closeAlertDialog) {
                                    if (user_Company) {
                                      // Kill APPLICATION :
                                      SystemNavigator.pop();
                                    }
                                    else if (_userController.userData.isNotEmpty) {
                                      // Kill ACTIVITY :
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  }
                                }
                              },
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.save,
                          size: 20,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        )
    );
  }
}