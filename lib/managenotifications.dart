import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:tro/repositories/parameters_repository.dart';
import 'package:tro/repositories/user_repository.dart';

import 'constants.dart';
import 'models/parameters.dart';
import 'models/user.dart';

enum ChoixNotification { perpetuelle, momentane }

class ManageNotification extends StatefulWidget {
  final Client client;
  const ManageNotification({super.key, required this.client});

  @override
  State<ManageNotification> createState() => _ManageNotificationState();
}

class _ManageNotificationState extends State<ManageNotification> {

  // A T T R I B U T E S
  ChoixNotification? _notification = ChoixNotification.perpetuelle;
  int millisecondsDebut = 0;
  int millisecondsFin = 0;
  TextEditingController dateDebutController = TextEditingController();
  TextEditingController heureDebutController = TextEditingController();
  //
  TextEditingController dateFinController = TextEditingController();
  TextEditingController heureFinController = TextEditingController();
  final _userRepository = UserRepository();
  final _repository = ParametersRepository();
  User? localuser;
  Parameters? parameters;
  bool flagSendData = false;
  bool closeAlertDialog = false;
  late BuildContext dialogContext;


  // M E T H O D S
  @override
  void initState() {
    super.initState();

    //
    getLocalUser();
  }

  void getLocalUser() async{
    localuser = await _userRepository.getConnectedUser();
    parameters = await _repository.findById(1);
    //
    millisecondsDebut = parameters!.epochdebut;
    millisecondsFin = parameters!.epochfin;
    _notification = parameters!.notification == 0 ? ChoixNotification.perpetuelle : ChoixNotification.momentane;
    if(parameters!.notification == 1 && millisecondsDebut > 0 && millisecondsFin > 0){
      processDatetime(DateTime.fromMillisecondsSinceEpoch(millisecondsDebut), 0);
      processDatetime(DateTime.fromMillisecondsSinceEpoch(millisecondsFin), 1);
    }
  }


  void processDatetime(DateTime dateTime, int choix){
    // Clear first :
    List<String> tp = dateTime.toString().split(" ");
    String tpDate = tp[0] ;
    List<String> tpH = tp[1].split(".");
    String tpHeure = tpH[0] ;
    //
    setState(() {
      if(choix == 0){
        // DEBUT :
        dateDebutController = TextEditingController(text: tpDate);
        heureDebutController = TextEditingController(text: tpHeure);
      }
      else{
        dateFinController = TextEditingController(text: tpDate);
        heureFinController = TextEditingController(text: tpHeure);
      }
    });
  }


  // Display INTERFACE for SENDING DATA :
  void displayLoadingInterface(BuildContext dContext) {

    if(dateDebutController.text.isEmpty){
      displayFloat('Veuillez définir la date de début', 1);
      return;
    }

    if(dateFinController.text.isEmpty){
      displayFloat('Veuillez définir la date de fin', 1);
      return;
    }

    if(_notification == ChoixNotification.momentane){
      if(millisecondsFin <= millisecondsDebut){
        displayFloat('La date de fin doit être supérieure à celle du début', 1);
        return;
      }
    }

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
                  child: const Column(
                    children: [
                      Text("Synchonisation paramètre ..."),
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
          );
        }
    );

    flagSendData = true;
    closeAlertDialog = true;
    sendNotificationRequest();

    // Run TIMER :
    Timer.periodic(
      const Duration(milliseconds: 1500),
          (timer) {
        // Update user about remaining time
        if(!flagSendData){
          Navigator.pop(dialogContext);
          timer.cancel();

          if(!closeAlertDialog){
            // Kill ACTIVITY :
            displayFloat("Paramètre modifié", 1);
          }
        }
      },
    );
  }


  // Send Account DATA :
  Future<void> sendNotificationRequest() async {
    try{
      final url = Uri.parse('${dotenv.env['URL']}managenotification');
      var response = await widget.client.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "iduser": localuser!.id,
            "choix": _notification == ChoixNotification.perpetuelle ? 0 : 1, // CHANGE THAT :
            "startdatetime": millisecondsDebut,
            "enddatetime": millisecondsFin
          })).timeout(const Duration(seconds: timeOutValue));

      // Checks :
      if(response.statusCode.toString().startsWith('2')){
        // Update DATA :
        Parameters updateParam = Parameters(
            id: parameters!.id,
            state: parameters!.state,
            travellocal: parameters!.travellocal,
            travelabroad: parameters!.travelabroad,
            notification: _notification == ChoixNotification.perpetuelle ? 0 : 1,
            epochdebut: millisecondsDebut,
            epochfin: millisecondsFin, comptevalide: parameters!.comptevalide,
            deviceregistered: parameters!.deviceregistered,
            privacypolicy: parameters!.privacypolicy, appmigration: parameters!.appmigration
        );
        await _repository.update(updateParam);
        // Set FLAG :
        closeAlertDialog = false;
      }
      else {
        displayFloat("Erreur de traitement : ${response.statusCode}", 0);
      }
    }
    catch(e){
    }
    finally{
      flagSendData = false;
    }
  }

  void displayFloat(String message, int choix){
    if(choix == 0) {
      Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(message)
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Réception notification',
            textAlign: TextAlign.start,
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )
          ),
        ),
        body: Column(
          children: <Widget>[
            ListTile(
              title: const Text('Indéfinie'),
              leading: Radio<ChoixNotification>(
                value: ChoixNotification.perpetuelle,
                groupValue: _notification,
                onChanged: (ChoixNotification? value) {
                  setState(() {
                    millisecondsDebut = 0;
                    millisecondsFin = 0;
                    _notification = value;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Temporaire'),
              leading: Radio<ChoixNotification>(
                value: ChoixNotification.momentane,
                groupValue: _notification,
                onChanged: (ChoixNotification? value) {
                  setState(() {
                    _notification = value;
                  });
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: const Divider(
                height: 1,
                color: Colors.black,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10),
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: () {

                    // get current datetime :
                    final now = DateTime.now();

                    picker.DatePicker.showDateTimePicker(context,
                        showTitleActions: true,
                        minTime: DateTime(now.year, now.month, now.day, now.hour, now.minute),
                        maxTime: DateTime(2026, 6, 7, 05, 09),
                        onChanged: (date) {
                          /*//dateLecture = date.timeZoneOffset.inHours.toString();
                                print('change $date in time zone ' +
                                    date.timeZoneOffset.inHours.toString());*/
                        },
                        onConfirm: (date) {
                          millisecondsDebut = date.millisecondsSinceEpoch;
                          processDatetime(date, 0);
                        },
                        locale: picker.LocaleType.fr);
                  },
                  child: const Text(
                    'Date de début',
                    style: TextStyle(
                        color: Colors.blue),
                  )
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 5, top: 5),
                    child: TextField(
                      enabled: false,
                      controller: dateDebutController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Date...',
                      ),
                      style: const TextStyle(
                          height: 0.8
                      ),
                      textAlignVertical: TextAlignVertical.bottom,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5, right: 10, top: 5),
                    child: TextField(
                      enabled: false,
                      controller: heureDebutController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Heure...',
                      ),
                      style: const TextStyle(
                          height: 0.8
                      ),
                      textAlignVertical: TextAlignVertical.bottom,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 10),
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: () {

                    // get current datetime :
                    final now = DateTime.now();

                    picker.DatePicker.showDateTimePicker(context,
                        showTitleActions: true,
                        minTime: DateTime(now.year, now.month, now.day, now.hour, now.minute),
                        maxTime: DateTime(2026, 6, 7, 05, 09),
                        onChanged: (date) {
                          /*//dateLecture = date.timeZoneOffset.inHours.toString();
                                print('change $date in time zone ' +
                                    date.timeZoneOffset.inHours.toString());*/
                        },
                        onConfirm: (date) {
                          millisecondsFin = date.millisecondsSinceEpoch;
                          processDatetime(date, 1);
                        },
                        locale: picker.LocaleType.fr);
                  },
                  child: const Text(
                    'Date de fin',
                    style: TextStyle(
                        color: Colors.blue),
                  )
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 5, top: 5),
                    child: TextField(
                      enabled: false,
                      controller: dateFinController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Date...',
                      ),
                      style: const TextStyle(
                          height: 0.8
                      ),
                      textAlignVertical: TextAlignVertical.bottom,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5, right: 10, top: 5),
                    child: TextField(
                      enabled: false,
                      controller: heureFinController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Heure...',
                      ),
                      style: const TextStyle(
                          height: 0.8
                      ),
                      textAlignVertical: TextAlignVertical.bottom,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              alignment: Alignment.topRight,
              margin: const EdgeInsets.only(left: 5, top: 20, right: 5),
              child: ElevatedButton.icon(
                style: ButtonStyle(
                    backgroundColor: MaterialStateColor.resolveWith(
                            (states) => Colors.blue)),
                label:
                const Text("Enregistrer", style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  displayLoadingInterface(context);
                },
                icon: const Icon(
                  Icons.save_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            )
          ],
        )
    );
  }
}