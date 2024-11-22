import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as https;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
as picker;
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/main.dart';
import 'package:tro/models/publication.dart';
import 'package:tro/models/souscription.dart';
import 'package:tro/models/ville.dart';
import 'package:tro/pageaccueil.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/publication_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import 'constants.dart';
import 'getxcontroller/getdeparturecontroller.dart';
import 'httpbeans/countrydata.dart';
import 'httpbeans/countrydataunicodelist.dart';
import 'httpbeans/departureresponse.dart';
import 'httpbeans/refreshbean.dart';
import 'mesbeans/devises.dart';
import 'models/pays.dart';


class ManageDeparture extends StatefulWidget {
  const ManageDeparture({Key? key, required this.id, required this.listeCountry, required this.nationalite,
    required this.idpub, required this.client}) : super(key: key);
  final int id;
  final List<Pays> listeCountry;
  final String nationalite;
  final int idpub;
  final Client client;

  @override
  State<ManageDeparture> createState() => _ManageDepartureState();
}

class CustomPicker extends picker.CommonPickerModel {
  String digits(int value, int length) {
    return '$value'.padLeft(length, "0");
  }

  CustomPicker({DateTime? currentTime, picker.LocaleType? locale})
      : super(locale: locale) {
    this.currentTime = currentTime ?? DateTime.now();
    this.setLeftIndex(this.currentTime.hour);
    this.setMiddleIndex(this.currentTime.minute);
    this.setRightIndex(this.currentTime.second);
  }

  @override
  String? leftStringAtIndex(int index) {
    if (index >= 0 && index < 24) {
      return this.digits(index, 2);
    } else {
      return null;
    }
  }

  @override
  String? middleStringAtIndex(int index) {
    if (index >= 0 && index < 60) {
      return this.digits(index, 2);
    } else {
      return null;
    }
  }

  @override
  String? rightStringAtIndex(int index) {
    if (index >= 0 && index < 60) {
      return this.digits(index, 2);
    } else {
      return null;
    }
  }

  @override
  String leftDivider() {
    return "|";
  }

  @override
  String rightDivider() {
    return "|";
  }

  @override
  List<int> layoutProportions() {
    return [1, 2, 1];
  }

  @override
  DateTime finalTime() {
    return currentTime.isUtc
        ? DateTime.utc(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        this.currentLeftIndex(),
        this.currentMiddleIndex(),
        this.currentRightIndex())
        : DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        this.currentLeftIndex(),
        this.currentMiddleIndex(),
        this.currentRightIndex());
  }
}

class _ManageDepartureState extends State<ManageDeparture> {

  // LINK :
  // https://api.flutter.dev/flutter/material/AlertDialog-class.html

  // A t t r i b u t e s  :
  TextEditingController dateDepartController = TextEditingController();
  TextEditingController heureDepartController = TextEditingController();
  TextEditingController longitudeChargementCommandeController = TextEditingController();
  TextEditingController reserveController = TextEditingController();
  TextEditingController deviceCommandeController = TextEditingController();
  TextEditingController villeController = TextEditingController();
  TextEditingController menuCountryDepartController = TextEditingController();
  TextEditingController menuDepartController = TextEditingController();
  TextEditingController menuDestinationController = TextEditingController();
  TextEditingController prixController = TextEditingController();
  //
  Pays? paysDepartMenu;
  final _paysRepository = PaysRepository();
  final _villeRepository = VilleRepository();
  final _publicationRepository = PublicationRepository();
  final DepartureGetController _departureController = Get.put(DepartureGetController());
  bool initInterface = false;

  late bool _isLoading;
  // Initial value :
  var dropdownvalue = "SYNOX";
  String defaultGenre = "M";
  String dateLecture = "";
  final lesGenres = ["M", "F"];
  final lesDevises = [
    Devises(libelle: 'CFA', id: 1),
    Devises(libelle: 'EURO', id: 2),
    Devises(libelle: 'USD', id: 3)
  ];
  late Devises devises;
  //final _userRepository = UserRepository();
  late BuildContext dialogContext;
  bool flagSendData = false;
  bool closeAlertDialog = false;
  int retour = 0;
  //
  //final PublicationGetController _publicationController = Get.put(PublicationGetController());
  late https.Client client;
  //
  String? getToken = "";
  int id = 0;
  int idpub = 0;
  int keep_idpub = 0;
  String nationalite = "";
  late List<Pays> listeCountry;
  late List<Ville> listeVilleDepart;
  late List<Ville> listeVilleDestination;
  Ville? villeDepartMenu;
  Ville? villeDestinationMenu;
  late String ordernumber;
  String ipaddress = "";
  int milliseconds = 0;
  late Publication publication;
  bool updatePubDate = false;
  bool updatePubHour = false;
  late BuildContext customContext;



  // M E T H O D S
  @override
  void initState() {

    super.initState();

    id = widget.id;
    idpub = widget.idpub;
    keep_idpub = widget.idpub;
    nationalite = widget.nationalite;
    listeCountry = widget.listeCountry;
    //paysDepartMenu = listeCountry.where((element) => element.iso2 == nationalite).first;
    devises = lesDevises.first;
    // Init : things
    _departureController.clear();

    if(idpub > 0){
      getPublicationIfNeeded();
    }
  }

  void getPublicationIfNeeded() async {
    publication = await _publicationRepository.findPublicationById(idpub);
  }

  TextEditingController processData(DepartureGetController controller, int choix){
    if(choix == 0){
      if(idpub > 0 && !updatePubDate) {
        updatePubDate = true;
        return dateDepartController;
      }
      dateDepartController = TextEditingController(text: controller.data.isNotEmpty ? controller.data[0] : '');
      return dateDepartController;
    }
    else{
      if(idpub > 0 && !updatePubHour) {
        updatePubHour = true;
        return heureDepartController;
      }
      heureDepartController = TextEditingController(text: controller.data.isNotEmpty ? controller.data[1] : '');
      return heureDepartController;
    }
  }

  // Get Towns related to COUNTRIES :
  Future<int> getTowns() async {
    // from iso2
    Pays paysDep = await _paysRepository.findPaysByIso(listeCountry.first.iso2);
    Pays paysDest = await _paysRepository.findPaysByIso(listeCountry.last.iso2);
    // Get the towns
    listeVilleDepart = await _villeRepository.findAllByPaysId(paysDep.id);
    listeVilleDepart.sort((a,b) =>
        a.name.compareTo(b.name));
    listeVilleDestination = await _villeRepository.findAllByPaysId(paysDest.id);
    listeVilleDestination.sort((a,b) =>
        a.name.compareTo(b.name));
    if(idpub == 0) {
      villeDepartMenu = listeVilleDepart.first;
      villeDestinationMenu = listeVilleDestination.first;
      devises = lesDevises.first;
    }
    else{
      villeDepartMenu = listeVilleDepart.where((ville) => ville.id == publication.villedepart).first;
      villeDestinationMenu = listeVilleDestination.where((ville) => ville.id == publication.villedestination).first;
      // Date
      dateDepartController = TextEditingController(text: publication.datevoyage.split("T")[0] );
      heureDepartController = TextEditingController(text: publication.datevoyage.split("T")[1] );
      reserveController = TextEditingController(text: publication.reserve.toString());
      prixController = TextEditingController(text: publication.prix.toString());
      // DEVISES
      devises = lesDevises.where((devise) => devise.id == publication.devise).first;
      milliseconds = DateTime.parse('${publication.datevoyage.split("T")[0]} ${publication.datevoyage.split("T")[1]}Z')
          .millisecondsSinceEpoch;
    }
    return 0;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.

    dateDepartController.dispose();
    heureDepartController.dispose();
    longitudeChargementCommandeController.dispose();
    reserveController.dispose();
    deviceCommandeController.dispose();
    villeController.dispose();
    menuCountryDepartController.dispose();
    //_departureController.dispose();
    prixController.dispose();

    super.dispose();
  }

  bool destinationSameDeparture() {
    return villeDepartMenu!.id == villeDestinationMenu!.id ;
  }

  void processDataForSending() {
    showDialog(
        barrierDismissible: false,
        context: customContext,
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
                          Text("Création de l'annonce ..."),
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
    retour = 0;
    // Currently not running FCM for iphone
    sendOrderRequest();

    // Run TIMER :
    Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        // Update user about remaining time
        if(!flagSendData){
          Navigator.pop(dialogContext);
          timer.cancel();

          // Kill ACTIVITY :
          if(!closeAlertDialog) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              //Navigator.of(context).pop({'selection': '1'});
            }
          }
        }
        else if(retour > 0){
          Navigator.pop(dialogContext);
          retour = 0;
        }
      },
    );
  }

  // In case PUBLICATION has already been suscribed, make
  Future<bool> checkSuscription() async{
    if(idpub > 0){
      List<Souscription> listeSouscription = await outil.findAllSuscriptionByIdpub(idpub);
      if(listeSouscription.isNotEmpty){
        // If previous MONTANT was FREE and new one is not, AVOID it :
        if(publication.prix < int.parse(prixController.text)){
          displayToast("Impossible de modifier le prix, \n car des souscriptions ont été faites.");
          return false;
        }
      }
    }
    return true;
  }

  bool verifyPrix() {
    try{
      int res = int.parse(prixController.text);
    }
    catch (e){
      return false;
    }
    return true;
  }

  bool verifyReserve() {
    try{
      int res = int.parse(reserveController.text);
    }
    catch (e){
      return false;
    }
    return true;
  }

  // Process :
  bool checkField(BuildContext context){
    customContext = context;
    if(dateDepartController.text.isEmpty || heureDepartController.text.isEmpty){
      displayToast("Veuillez renseigner la DATE et l'HEURE");
      return true;
    }
    else if(reserveController.text.isEmpty){
      displayToast("Veuillez définir la réserve");
      return true;
    }
    else if(!verifyReserve()){
      displayToast("La valeur de la réserve est incorrecte");
      return true;
    }
    else if(prixController.text.isEmpty){
      displayToast("Veuillez fixer le prix");
      return true;
    }
    else if(!verifyPrix()){
      displayToast("Le prix renseigné est incorrect");
      return true;
    }
    else if(destinationSameDeparture()){
      displayToast("Les 2 villes doivent être différentes");
      return true;
    }
    return false;
  }

  // Our TOAST :
  void displayToast(String message){
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  // Send Account DATA :
  Future<void> sendOrderRequest() async {
    try{
      final hNow = DateTime.now();
      final url = Uri.parse('${dotenv.env['URL']}managetravel');
      var response = await widget.client.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "id": idpub,
            "idpaysdepart": listeCountry.first.id,
            "paysdepart": listeCountry.first.name,
            "abrevpaysdepart": listeCountry.first.iso2,
            "idvilledepart": villeDepartMenu!.id,
            "villedepart": villeDepartMenu!.name,

            "idpaysdestination": listeCountry.last.id,
            "paysdestination": listeCountry.last.name,
            "abrevpaysdestination": listeCountry.last.iso2,
            "idvilledestination": villeDestinationMenu!.id,
            "villedestination": villeDestinationMenu!.name,

            "date": dateDepartController.text,
            "heure": heureDepartController.text,
            "heuregeneration": "${hNow.hour}:${hNow.minute}:${hNow.second}",
            "reserve": reserveController.text, //gpsController.t
            "user": id,
            "milliseconds": milliseconds,

            "deviseid": devises.id,
            "deviselib": devises.libelle,
            "prix": prixController.text,
          })).timeout(const Duration(seconds: timeOutValue));

      // Checks :
      if (response.statusCode == 200) {
        DepartureResponse reponse = DepartureResponse.fromJson(
            json.decode(response.body));
        Publication pub = Publication(
            id: idpub == 0 ? reponse.id : idpub,
            userid: id,
            villedepart: villeDepartMenu!.id,
            villedestination: villeDestinationMenu!.id,
            datevoyage: (dateDepartController.text + "T" +
                heureDepartController.text),
            datepublication: reponse.date,
            reserve: int.parse(reserveController.text),
            active: idpub == 0 ? 1 : publication.active,
            reservereelle: int.parse(reserveController.text),
            souscripteur: idpub == 0 ? 0 : publication.souscripteur,
            milliseconds: milliseconds,
            identifiant: idpub == 0 ? reponse.identifiant : publication
                .identifiant,
            devise: devises.id,
            prix: int.parse(prixController.text),
            read: 1,
          streamchannelid: ''
        );
        if (idpub > 0) {
          // From THERE, REFRESH SOUSCRIPTION :
          for(RefreshReserveBean rn in reponse.reserveBean){
            if(rn.idpub > 0) {
              Souscription souscription = await outil
                  .getSouscriptionByIdpubAndIduser(rn.idpub, rn.iduser);
              // Update it :
              Souscription souscriptionUpdate = Souscription(
                  id: souscription.id,
                  idpub: rn.idpub,
                  iduser: rn.iduser,
                  millisecondes: souscription.millisecondes,
                  reserve: rn.reserve,
                  statut: souscription.statut,
                  streamchannelid: souscription.streamchannelid
              );
              await outil.updateSouscription(souscriptionUpdate);
            }
          }
          // Annonce modifiée :
          await outil.updatePublicationWithoutFurtherActions(pub);
          displayToast("Annonce modifiée !");
        }
        else {
          // Save :
          outil.addPublication(pub);
          displayToast("Annonce créée !");
        }
        // Set FLAG :
        closeAlertDialog = false;
      }
      else {
        retour = 1;
        Fluttertoast.showToast(
            msg: "Impossible de traiter la commande !",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
      }
    }
    catch (e){
      displayToast("Traitement impossible !");
    }

    //
    flagSendData = false;
  }

  void displaySnack(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text(message)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder(
          future: Future.wait([getTowns()]),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 60, left: 10),
                      child: const Align(
                        alignment: Alignment.topLeft,
                        child: Icon(
                          Icons.airplane_ticket_sharp,
                          color: Colors.brown,
                          size: 80.0,
                        ),
                      ) ,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20, left: 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(idpub == 0 ? 'Nouvelle annonce' : 'Modification annonce',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            )
                        ),
                      ) ,
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Départ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87
                                  )),
                              Text('Destination',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87
                                  ))
                            ],
                          ),
                          Divider(
                            color: Colors.black,
                            height: 5,
                          )
                        ],
                      ),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownMenu<Ville>(
                                width: 180,
                                menuHeight: 250,
                                initialSelection: villeDepartMenu,
                                controller: menuDepartController,
                                hintText: "Ville de départ",
                                requestFocusOnTap: false,
                                enableFilter: false,
                                label: const Text('Ville de départ'),
                                // Initial Value
                                onSelected: (Ville? value) {
                                  villeDepartMenu = value!;
                                },
                                dropdownMenuEntries:
                                listeVilleDepart.map<DropdownMenuEntry<Ville>>((Ville menu) {
                                  return DropdownMenuEntry<Ville>(
                                      value: menu,
                                      label: menu.name,
                                      leadingIcon: Icon(Icons.map));
                                }).toList()
                            ),
                            DropdownMenu<Ville>(
                                width: 180,
                                menuHeight: 250,
                                initialSelection: villeDestinationMenu,
                                controller: menuDestinationController,
                                hintText: "Ville de destination",
                                requestFocusOnTap: false,
                                enableFilter: false,
                                label: const Text('Ville de destination'),
                                // Initial Value
                                onSelected: (Ville? value) {
                                  villeDestinationMenu = value!;
                                },
                                dropdownMenuEntries:
                                listeVilleDestination.map<DropdownMenuEntry<Ville>>((Ville menu) {
                                  return DropdownMenuEntry<Ville>(
                                      value: menu,
                                      label: menu.name,
                                      leadingIcon: Icon(Icons.map));
                                }).toList()
                            )
                          ],
                        )
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith((states) => Colors.blue)
                        ),
                        label: const Text("Date de départ",
                            style: TextStyle(
                                color: Colors.white
                            )
                        ),
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
                                milliseconds = date.millisecondsSinceEpoch;
                                _departureController.addData(date);
                              },
                              locale: picker.LocaleType.fr);
                        },
                        icon: const Icon(
                          Icons.access_time_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GetBuilder<DepartureGetController>(
                        builder: (DepartureGetController controller) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10, right: 5, top: 5),
                                  child: TextField(
                                    enabled: false,
                                    controller: processData(controller, 0),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Date...',
                                    ),
                                    style: TextStyle(
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
                                    controller: processData(controller, 1),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Heure...',
                                    ),
                                    style: TextStyle(
                                        height: 0.8
                                    ),
                                    textAlignVertical: TextAlignVertical.bottom,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: const Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Réserve",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Divider(
                            color: Colors.black,
                            height: 5,
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 180,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              controller: reserveController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Réserve (kg)',
                              ),
                              style: const TextStyle(
                                  height: 0.8
                              ),
                              textAlignVertical: TextAlignVertical.bottom,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 17),
                            child: DropdownMenu<Devises>(
                                width: 170,
                                menuHeight: 250,
                                initialSelection: devises,
                                //controller: menuDepartController,
                                hintText: "Devises",
                                requestFocusOnTap: false,
                                enableFilter: false,
                                label: const Text('Choix devise'),
                                // Initial Value
                                onSelected: (Devises? value) {
                                  devises = value!;
                                },
                                dropdownMenuEntries:
                                lesDevises.map<DropdownMenuEntry<Devises>>((Devises menu) {
                                  return DropdownMenuEntry<Devises>(
                                      value: menu,
                                      label: menu.libelle,
                                      leadingIcon: const Icon(Icons.money));
                                }).toList(),
                              inputDecorationTheme: InputDecorationTheme(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                constraints: BoxConstraints.tight(const
                                Size.fromHeight(70)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      //
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: prixController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Prix (Kg)',
                          ),
                          style: const TextStyle(
                              height: 0.8
                          ),
                          textAlignVertical: TextAlignVertical.bottom,
                          textAlign: TextAlign.center,
                        ),
                      )
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 30, left: 10, right: 10),
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
                            label: const Text("Enregistrer",
                                style: TextStyle(
                                    color: Colors.white
                                )
                            ),
                            onPressed: () async {
                              if(outil.getCheckNetworkConnected()) {
                                if (!checkField(context)) {
                                  var checkAmountValidation = await checkSuscription();
                                  if (checkAmountValidation) {
                                    processDataForSending();
                                  }
                                }
                              }
                              else{
                                displaySnack('Assure-vous d\'avoir la connexion INTERNET!');
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
              );
            }
            else {
              return const Center(
              child: Text('Chargement ...'),
            );
            }
          }
        )
    );
  }
}