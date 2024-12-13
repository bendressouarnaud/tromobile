

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
import 'package:restart_app/restart_app.dart';
import 'package:tro/getxcontroller/getciblecontroller.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/main.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import 'constants.dart';
import 'getxcontroller/getparamscontroller.dart';
import 'httpbeans/cibleresponse.dart';
import 'models/cible.dart';
import 'models/parameters.dart';
import 'models/pays.dart';
import 'models/publication.dart';
import 'models/user.dart';
import 'models/ville.dart';

class ConfirmerMail extends StatefulWidget {
  // Attributes
  final Client client;
  final int tache;

  const ConfirmerMail({Key? key, required this.client, required this.tache}) : super(key: key);

  @override
  State<ConfirmerMail> createState() => _SConfirmerMail();
}

class _SConfirmerMail extends State<ConfirmerMail> {
  // A T T R I B U T E S :
  final _userRepository = UserRepository();
  TextEditingController codeEmailController = TextEditingController();
  final ParametersGetController _parametersController = Get.put(ParametersGetController());
  late BuildContext dialogContext;
  bool flagSendData = false;
  bool closeAlertDialog = false;
  late BuildContext contextG;


  // M E T H O D S
  @override
  void initState() {
    super.initState();

  }

  // Send Account DATA :
  Future<void> sendEmailAccountValidation() async {
    try {
      User? lUser = await outil.pickLocalUser();
      final url = Uri.parse('${dotenv.env['URL']}validatemailaccount');
      var response = await widget.client.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "iduser": lUser!.id,
            "code": codeEmailController.text
          })).timeout(const Duration(seconds: timeOutValue));

      // Checks :
      if (response.statusCode == 200) {
        Parameters? prms = await _parametersController.refreshData();
        prms = Parameters(id: prms!.id,
            state: prms.state,
            travellocal: prms.travellocal,
            travelabroad: prms.travelabroad,
            notification: prms.notification,
            epochdebut: prms.epochdebut,
            epochfin: prms.epochfin,
            comptevalide: 1,
            deviceregistered: 0
        );
        await _parametersController.updateData(prms);

        // Set FLAG :
        flagSendData = false;
      }
      else {
        displayToast("Impossible de traiter la demande");
      }
      closeAlertDialog = false;
    }
    catch (e) {
      //
    }
    finally{
      closeAlertDialog = false;
    }
  }

  // Send Account DATA :
  Future<void> reSendPassword() async {
    try {
      User? lUser = await outil.pickLocalUser();
      final url = Uri.parse('${dotenv.env['URL']}resendpassword');
      var response = await widget.client.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "iduser": lUser!.id,
            "code": lUser!.email
          })).timeout(const Duration(seconds: timeOutValue));

      // Checks :
      if (response.statusCode == 200) {
        // Set FLAG :
        flagSendData = false;
      }
      else {
        displayToast("Impossible de traiter la demande");
      }
      closeAlertDialog = false;
    }
    catch (e) {
      //
    }
    finally{
      closeAlertDialog = false;
    }
  }

  // Our TOAST :
  void displayToast(String message){
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }


  void displayDisplay() {
    showDialog(
        barrierDismissible: false,
        context: contextG,
        builder: (BuildContext context) {
          dialogContext = context;
          return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
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
                        Restart.restartApp();
                      },
                      child: const Text('OK'),
                    ),
                  ]
              ) );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    //
    contextG = context;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const Icon(
              Icons.contact_mail_outlined,
          color: Colors.black),
          elevation: 1,
          backgroundColor: Colors.white,
          title: const Text('Confirmer le mail',
            style: TextStyle(
                color: Colors.black
            ),
            textAlign: TextAlign.center,
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
              child: Container(
                  margin: const EdgeInsets.only(top: 100),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 90,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: const Text('Renseignez le code reçu par mail',
                          style: TextStyle(
                              fontSize: 19
                          ),),
                      ),
                      Container(
                        width: 300,
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                        margin: const EdgeInsets.only(bottom: 40),
                        child: TextField(
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 19
                          ),
                          keyboardType: TextInputType.text,
                          controller: codeEmailController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Code...'
                          ),
                          textInputAction: TextInputAction.next,
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
                          if(codeEmailController.text.isEmpty){
                            Fluttertoast.showToast(
                                msg: "Veuillez saisir le code !",
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 3,
                                backgroundColor: Colors.red,
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
                                                  Text("Validation du mail ..."),
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
                            sendEmailAccountValidation();

                            // Run TIMER :
                            Timer.periodic(
                              const Duration(seconds: 1),
                                  (timer) {
                                // Update user about remaining time
                                if(!closeAlertDialog){
                                  Navigator.pop(dialogContext);
                                  timer.cancel();

                                  // Kill ACTIVITY :
                                  if(!flagSendData) {
                                    //widget.tache == 1 ? displayDisplay() : Navigator.pop(context);
                                    displayDisplay();
                                  }
                                  else{
                                    displayToast("Veuillez réessayer la validation !");
                                  }
                                }
                              },
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.send,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.only(top: 45),
                          child: GestureDetector(
                              onTap: () {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      dialogContext = context;
                                      return PopScope(
                                          canPop: false,
                                          child: const AlertDialog(
                                              title: Text('Information'),
                                              content: SizedBox(
                                                  height: 100,
                                                  child: Column(
                                                    children: [
                                                      Text("Renvoi du mot de passe ..."),
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
                                reSendPassword();

                                // Run TIMER :
                                Timer.periodic(
                                  const Duration(seconds: 1),
                                      (timer) {
                                    // Update user about remaining time
                                    if(!closeAlertDialog){
                                      Navigator.pop(dialogContext);
                                      timer.cancel();

                                      // Kill ACTIVITY :
                                      if(!flagSendData) {
                                        displayToast("Renvoi du mot de passe effectué !");
                                      }
                                      else{
                                        displayToast("Veuillez vérifier votre connexion !");
                                      }
                                    }
                                  },
                                );
                              },
                              child: Text(
                                  'Renvoyer le mot de passe',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    decoration: TextDecoration.underline,
                                  )
                              )
                          )
                      ),

                    ],
                  )
              )
          ),
        )
    );
  }
}