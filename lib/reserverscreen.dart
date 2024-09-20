import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cinetpay/cinetpay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:http/http.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/loadingpayment.dart';
import 'package:tro/repositories/publication_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/singletons/outil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';
import 'getxcontroller/getreservercontroller.dart';
import 'httpbeans/hubwaveresponseshort.dart';
import 'httpbeans/reservationresponse.dart';
import 'models/publication.dart';
import 'models/user.dart';
import 'models/ville.dart';

class ReservePaiement extends StatefulWidget {
  // Attribute
  //int idart = 0;
  final Publication publication;
  final Client client;

  ReservePaiement({Key? key, required this.publication, required this.client}) : super(key: key);
  //ArticleEcran.setId(this.idart, this.fromadapter, this.qte, this.client);

  @override
  State<ReservePaiement> createState() => _ReservePaiement();
}

class _ReservePaiement extends State<ReservePaiement> {
  // A T T R I B U T E S:
  final PublicationGetController _publicationController =
      Get.put(PublicationGetController());
  late Publication publication;
  late Ville ville;
  late Ville villeDepart;
  late int userOrSuscriber; // 0 : Suscriber, 1 : User

  TextEditingController reserveController = TextEditingController();
  final ReserverGetController _reserveController = Get.put(ReserverGetController());
  Map<String, dynamic>? response;
  IconData? icon;
  Color? color;
  bool show = false;
  String? message;
  final _userRepository = UserRepository();
  final _publicationRepository = PublicationRepository();
  late User localuser;
  late BuildContext dialogContext;
  bool flagSendData = false;
  bool flagLoadingPayment = false;
  bool closeAlertDialog = false;
  Outil outil = Outil();
  String montantFinal = "";
  //
  late final AppLifecycleListener _listener;
  bool hitServerAfterUrlPayment = false;



  // M E T H O D S
  @override
  void initState() {
    super.initState();

    //_reserveController.clear();
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );
    publication = widget.publication;
    getLocalUser();
  }

  // Listen to the app lifecycle state changes
  void _onStateChanged(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed && hitServerAfterUrlPayment){
      // Check on SERVER :
      hitServerAfterUrlPayment = false;
      displayLoadingInterface(context);
    }
  }

  @override
  void dispose() {
    // Do not forget to dispose the listener
    _listener.dispose();
    super.dispose();
  }

  void getLocalUser() async{
    localuser = (await _userRepository.getConnectedUser())!;
  }

  String processData(ReserverGetController controller){
    if(controller.data.isEmpty){
      if(publication.prix == 0){
        montantFinal = "0";
        return "Gratuit";
      }
      else{
        montantFinal = "0";
        return formatPrice(publication.prix);
      }
    }

    String tampon = controller.data.isNotEmpty ? controller.data[controller.data.length - 1] : '0';
    int res = 0;
    // Convert
    try {
      res = int.parse(tampon);
    } catch (e) {
      // No specified type, handles all
      res = 0;
    }

    if(publication.prix == 0){
      montantFinal = "0";
      return "Gratuit";
    }
    else{
      int price = publication.prix * res;
      montantFinal = price.toString();
      return formatPrice(price);
    }
  }

  String formatPrice(int price){
    MoneyFormatter fmf = MoneyFormatter(
        amount: price.toDouble()
    );
    return fmf.output.withoutFractionDigits;
  }

  // Display SNACK
  void displayMessage(String message, int delay){
    // Display SNACKBAR :
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          duration: Duration(seconds: delay),
          content: Text(message)
      ),
    );
  }

  Future<void> callWaveApi() async {
    final url = Uri.parse('${dotenv.env['URL']}generatewaveid');
    var response = await widget.client.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": montantFinal,
          "currency": 'XOF',
          "error_url": 'https://example.com/error',
          "success_url": 'https://example.com/success',
          "idpub": publication.id,
          "iduser": localuser.id,
          "reserve": reserveController.text
        })).timeout(const Duration(seconds: timeOutValue));;

    // Checks :
    flagLoadingPayment = false;
    if(response.statusCode == 200){
      HubWaveResponseShort hubWaveResponse = HubWaveResponseShort.fromJson(json.decode(response.body));
      if(hubWaveResponse.id.isNotEmpty) {
        // Open link
        final Uri url = Uri.parse(hubWaveResponse.wave_launch_url);
        if (!await launchUrl(url)) {
          //throw Exception('Could not launch $_url');
        }
        else{
          //
          hitServerAfterUrlPayment = true;
        }
      }
    }
    else{
      displayMessage('Une erreur est survenue', 3);
    }
  }

  // Requesting to get WAVE URL :
  void loadingWavePayment(BuildContext dContext){
    showDialog(
        barrierDismissible: false,
        context: dContext,
        builder: (BuildContext context) {
          dialogContext = context;
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
                title: const Text('Synchonisation'),
                content: Container(
                    height: 100,
                    child: const Column(
                      children: [
                        Text("Chargement moyen de paiement ..."),
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
            ),
          );
        }
    );

    flagLoadingPayment = true;
    callWaveApi();

    // Run TIMER :
    Timer.periodic(
      const Duration(milliseconds: 1000),
          (timer) {
        // Update user about remaining time
        if(!flagLoadingPayment){
          Navigator.pop(dialogContext);
          timer.cancel();
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
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
                title: const Text('Information'),
                content: Container(
                    height: 100,
                    child: Column(
                      children: [
                        Text(montantFinal == "0" ? "Réservation encours ..." : "Finalisation paiement ..."),
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
            )
          );
        }
    );

    flagSendData = true;
    closeAlertDialog = true;
    sendReservationRequest();

    // Run TIMER :
    Timer.periodic(
      const Duration(milliseconds: 1500),
          (timer) {
        // Update user about remaining time
        if(!flagSendData){
          Navigator.pop(dialogContext);
          timer.cancel();

          // Kill ACTIVITY :
          if(!closeAlertDialog) {
            if (Navigator.canPop(dContext)) {
              Navigator.pop(dContext);
              //Navigator.of(context).pop({'selection': '1'});
            }
          }
        }
      },
    );
  }


  // Send Account DATA :
  Future<void> sendReservationRequest() async {
    final hNow = DateTime.now();
    final url = montantFinal == "0" ? Uri.parse('${dotenv.env['URL']}bookreservation') :
      Uri.parse('${dotenv.env['URL']}managereservation');
    var response = await widget.client.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idpub": publication.id,
          "iduser": localuser.id, // CHANGE THAT :
          "montant": montantFinal,
          "reserve": reserveController.text
        })).timeout(const Duration(seconds: timeOutValue));

    // Checks :
    if(response.statusCode == 200){
      ReservationResponse data =  ReservationResponse.fromJson(jsonDecode(const Utf8Decoder().convert(response.bodyBytes)));
      // Check USER's presence :
      User? user = await _userRepository.findById(data.id);
      if(user == null){
        // Persist DATA :
        // Create new :
        user = User(nationnalite: data.nationnalite,
            id: data.id,
            typepieceidentite: '',
            numeropieceidentite: '',
            nom: data.nom,
            prenom: data.prenom,
            email: '',
            numero: '',
            adresse: data.adresse,
            fcmtoken: '',
            pwd: "123",
            codeinvitation: "123",
            villeresidence: 0);
        // Save :
        outil.addUser(user);
        //await _userRepository.insertUser(user);
      }

      // Now update 'publication'
      Publication pub = Publication(
        id: publication.id,
        userid: publication.userid,
        villedepart: publication.villedepart,
        villedestination: publication.villedestination,
        datevoyage: publication.datevoyage,
        datepublication: publication.datepublication,
        reserve: publication.reserve,
        active: 1,
        reservereelle: int.parse(reserveController.text),
        souscripteur: user.id, // Use OWNER Id
        milliseconds: publication.milliseconds,
        identifiant: publication.identifiant,
        devise: publication.devise,
        prix: publication.prix,
        read: 1
      );
      // Update  :
      await outil.updatePublication(pub);

      // Set FLAG :
      flagSendData = false;
      closeAlertDialog = false;
    }
    else if(response.statusCode == 403) {
      flagSendData = false;
      displayFloat("Opération de paiement non finalisée");
    }
    else{
      flagSendData = false;
      // Erreur Réseau :
      displayFloat("Impossible de traiter l'opération");
    }
  }

  void displayFloat(String message){
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


  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CinetPay Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        //backgroundColor: Colors.white,
        appBar: AppBar(
          //backgroundColor: Colors.white,
          title: Text(
            'Ticket ${publication.identifiant}',
            textAlign: TextAlign.start,
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 30),
                child: Text('Renseigner les données',
                  style: TextStyle(
                      fontSize: 20
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 40, right: 40, top: 15),
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: reserveController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Réserve (kg)',
                  ),
                  //style: TextStyle(height: 0.8),
                  textAlignVertical: TextAlignVertical.bottom,
                  textAlign: TextAlign.center,
                  onChanged: (texte) {
                    //print('valeur $texte');
                    _reserveController.addData(texte);
                  },
                ),
              ),
              GetBuilder<ReserverGetController>(
                builder: (ReserverGetController controller) {
                  return Container(
                    padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Text('Prix : ',
                          style: TextStyle(
                              fontSize: 17
                          ),
                        ),
                        Text(processData(controller),
                          style: const TextStyle(
                              fontSize: 17,
                            fontWeight: FontWeight.bold
                          )
                        )
                      ],
                    )
                  );
                }
              ),
              Container(
                alignment: Alignment.topRight,
                margin: const EdgeInsets.only(left: 40, top: 30, right: 40),
                child: ElevatedButton.icon(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Colors.blue)),
                  label:
                  const Text("Valider", style: TextStyle(color: Colors.white)),
                  onPressed: () async {

                    // Convert
                    int reservation = 0;
                    try {
                      reservation = int.parse(reserveController.text);
                    } catch (e) {
                      // No specified type, handles all
                      reservation = 0;
                    }

                    if(reservation == 0){
                      displayFloat("Définissez votre réserve !");
                      return;
                    }

                    if(publication.prix == 0){
                      // Launch PAYMENT :
                      displayLoadingInterface(context);
                    }
                    else{
                      String amount = montantFinal;
                      if (amount.isEmpty) {
                        // Mettre une alerte
                        return;
                      }
                      double _amount;
                      try {
                        _amount = double.parse(amount);
                        if (_amount < 100) {
                          // Mettre une alerte
                          return;
                        }
                        if (_amount > 1500000) {
                          // Mettre une alerte
                          return;
                        }
                      } catch (exception) {
                        return;
                      }

                      final String transactionId = Random()
                          .nextInt(100000000)
                          .toString(); // Mettre en place un endpoint à contacter côté serveur pour générer des ID unique dans votre BD

                      loadingWavePayment(context);
                    }
                  },
                  icon: const Icon(
                    Icons.money,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}
