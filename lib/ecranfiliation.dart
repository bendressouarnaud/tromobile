

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:http/http.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:tro/getxcontroller/getciblecontroller.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/models/filiation.dart';
import 'package:tro/repositories/filiation_repository.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import 'constants.dart';
import 'creercible.dart';
import 'httpbeans/filiationrefresh.dart';
import 'models/cible.dart';
import 'models/pays.dart';
import 'models/publication.dart';
import 'models/ville.dart';

class GestionFiliation extends StatefulWidget {
  // Attributes
  final Client client;
  final int userId;
  GestionFiliation({Key? key, required this.client, required this.userId}) : super(key: key);

  @override
  State<GestionFiliation> createState() => _GestionFiliation();
}

class _GestionFiliation extends State<GestionFiliation> {

  // A T T R I B U T E S:
  final _filiationRepository = FiliationRepository();
  TextEditingController montantController = TextEditingController();
  late BuildContext dialogContext;
  bool flagSendData = false;
  bool closeAlertDialog = false;
  late String codeParrainage;
  late double bonus;
  final double redrawalAmount = 500;



  // M E T H O D S
  @override
  void initState() {
    super.initState();

  }

  Future<Filiation?> getData() async{
    Filiation? tampon = await _filiationRepository.findById(1);
    codeParrainage = tampon!.code;
    bonus = tampon.bonus;
    return tampon;
  }

  String formatPrice(double price){
    MoneyFormatter fmf = MoneyFormatter(
        amount: price
    );
    return fmf.output.withoutFractionDigits;
  }


  void dialogRequestSolde(BuildContext fContext, double leBonus) {
    showDialog(
        barrierDismissible: false,
        context: fContext,
        builder: (BuildContext context) {
          dialogContext = context;
          return PopScope(
              canPop: false,
              child: AlertDialog(
                  title: const Text('Renseignez le montant'),
                  content: SizedBox(
                      height: 70,
                      child: Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              controller: montantController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Montant',
                              ),
                              style: const TextStyle(
                                  height: 1.0
                              ),
                              textAlignVertical: TextAlignVertical.bottom,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
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
                        try{
                          int montant = int.parse(montantController.text);
                          if(montant > leBonus){
                            displayFloat("Le montant est supérieur au solde !", choix: 0);
                          }
                          else{
                            Navigator.pop(dialogContext);
                            displayLoadingPaymentRequest(context, montant);
                          }
                        }
                        catch (e){
                          displayFloat("Le montant est incorrect !", choix: 0);
                        }
                      },
                      child: const Text('OUI'),
                    ),
                  ]
              ) );
        }
    );
  }


  void displayLoadingPaymentRequest(BuildContext dContext, int montant) {
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
                      Text("Synchonisation ..."),
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
    sendPaymentRequest(montant);
    int waitForTimeout = 0;

    // Run TIMER :
    Timer.periodic(
      const Duration(milliseconds: 1000),
          (timer) {
        waitForTimeout++;
        // Update user about remaining time
        if(!closeAlertDialog || (waitForTimeout <= timeOutValue)){
          Navigator.pop(dialogContext);
          timer.cancel();
          if(!flagSendData){
            // Data sent :
            setState(() {
            });
          }
        }
      },
    );
  }


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
                  child: const Column(
                    children: [
                      Text("Synchonisation ..."),
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
    sendFiliationRequest();

    // Run TIMER :
    Timer.periodic(
      const Duration(milliseconds: 1500),
          (timer) {
        // Update user about remaining time
        if(!flagSendData){
          Navigator.pop(dialogContext);
          timer.cancel();
        }
      },
    );
  }


  // Send Account DATA :
  Future<void> sendFiliationRequest() async {
    final url = Uri.parse('${dotenv.env['URL']}refreshfiliation');
    var response = await widget.client.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "iduser": widget.userId,
          "choix": 0
        })).timeout(const Duration(seconds: timeOutValue));

    // Checks :
    if(response.statusCode.toString().startsWith('2')){
      FiliationRefresh frh =  FiliationRefresh.fromJson(json.decode(response.body));
      // From there, Hit NEW FILIATION while keeping current BONUS :
      Filiation filiation = Filiation(id: 1, code: frh.parrainage, bonus: bonus);
      await _filiationRepository.update(filiation);

      // Set FLAG :
      closeAlertDialog = false;

      setState(() {
        codeParrainage = frh.parrainage;
        bonus = frh.bonus;
      });
    }
    else {
      displayFloat("Erreur de traitement !", choix: 1);
    }
    flagSendData = false;
  }


  // Send Account DATA :
  Future<void> sendPaymentRequest(int montant) async {
    try{
      final url = Uri.parse('${dotenv.env['URL']}requestpayment');
      var response = await widget.client.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "iduser": widget.userId,
            "amount": montant
          })).timeout(const Duration(seconds: timeOutValue));

      // Checks :
      if(response.statusCode.toString().startsWith('2')){
        // From there, Hit NEW FILIATION :
        double newAmount = bonus - montant;
        Filiation filiation = Filiation(id: 1, code: codeParrainage, bonus: newAmount);
        await _filiationRepository.update(filiation);

        // Set FLAG :
        flagSendData = false;
        bonus = newAmount;
      }
      else {
        displayFloat("Requête de paiment non traitée !", choix: 1);
      }
    }
    catch (e){}
    closeAlertDialog = false;
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Filiation',
            textAlign: TextAlign.start,
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )),
        ),
        body: FutureBuilder(
            future: Future.wait([getData()]),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                // Get DATA
                Filiation? filiation = snapshot.data[0];

                return Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      margin: const EdgeInsets.only(right: 20, left: 20, top: 20),
                      child: const Text('Code Parrainage',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF000000)
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 20, left: 20, top: 5),
                      child: const Divider(
                        height: 2,
                      )
                    ),
                    Container(
                        margin: const EdgeInsets.only(right: 20, left: 20, top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(codeParrainage,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFAD6004),
                                    fontSize: 18
                                )
                            ),
                            ElevatedButton.icon(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateColor.resolveWith((states) => Colors.blueGrey)
                              ),
                              label: const Text("Actualiser",
                                  style: TextStyle(
                                      color: Colors.white
                                  )),
                              onPressed: () {
                                displayLoadingInterface(context);
                              },
                              icon: const Icon(
                                Icons.refresh_sharp,
                                size: 20,
                                color: Colors.white,
                              ),
                            )
                          ],
                        )
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 20, left: 20, top: 5),
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith((states) => Colors.blue)
                        ),
                        label: const Text("Partager",
                            style: TextStyle(
                                color: Colors.white
                            )),
                        onPressed: () async {
                          await FlutterShare.share(
                              title: 'Code Parrainage',
                              text: codeParrainage,
                              chooserTitle: 'Partager le code');
                        },
                        icon: const Icon(
                          Icons.share,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      margin: const EdgeInsets.only(right: 20, left: 20, top: 20),
                      child: const Text('BONUS',
                        style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF000000)
                        ),
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.only(right: 20, left: 20, top: 5),
                        child: const Divider(
                          height: 2,
                        )
                    ),
                    Container(
                        alignment: Alignment.topLeft,
                        margin: const EdgeInsets.only(right: 20, left: 20, top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${formatPrice(bonus)} FCFA',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFAD6004),
                                    fontSize: 25
                                )
                            ),
                            Visibility(
                                visible: bonus >= redrawalAmount,
                                child: ElevatedButton.icon(
                                  style: ButtonStyle(
                                      backgroundColor: MaterialStateColor.resolveWith((states) => greenAlertValidation)
                                  ),
                                  label: const Text("Transfert",
                                      style: TextStyle(
                                          color: Colors.white
                                      )),
                                  onPressed: () {
                                    dialogRequestSolde(context, bonus);
                                  },
                                  icon: const Icon(
                                    Icons.monetization_on,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                )
                            )
                          ],
                        )
                        /**/
                    ),
                    Visibility(
                      visible: bonus < redrawalAmount,
                      child: Container(
                          margin: const EdgeInsets.only(right: 20, left: 20, top: 15),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.black,
                                  width: 1
                              ),
                              color: cardviewsoldeminimum,
                              borderRadius: BorderRadius.circular(16.0)
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                child: Icon(Icons.add_alert_sharp,
                                  color: Colors.orangeAccent,),
                              ),
                              Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    child: Text(
                                      'Solde minimum à atteindre avant le prochain transfert : 500',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  )
                              )
                            ],
                          ),
                        )
                    )
                  ],
                );
              }
              else {
                return Center(
                  child: Text('Chargement ...'),
                );
              }
            }
        )
    );
  }
}