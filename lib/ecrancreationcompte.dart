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
import 'package:tro/models/cible.dart';
import 'package:tro/models/filiation.dart';
import 'package:tro/models/ville.dart';
import 'package:tro/pageaccueil.dart';
import 'package:tro/repositories/cible_repsository.dart';
import 'package:tro/repositories/filiation_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import 'constants.dart';
import 'getxcontroller/getciblecontroller.dart';
import 'getxcontroller/getusercontroller.dart';
import 'package:http/http.dart' as https;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'httpbeans/countrydata.dart';
import 'httpbeans/countrydataunicodelist.dart';
import 'httpbeans/usercreationresponse.dart';
import 'main.dart';
import 'models/pays.dart';
import 'models/user.dart';


class EcranCreationCompte extends StatefulWidget {
  const EcranCreationCompte({Key? key, required this.listeCountry, required this.listeVille, required this.client, required this.gUser, required this.returnValue}) : super(key: key);
  final List<Pays> listeCountry;
  final List<Ville> listeVille;
  final Client client;
  final User? gUser;
  final bool returnValue;
  //final https.Client client;

  @override
  State<EcranCreationCompte> createState() => _NewCreationState();
}

class _NewCreationState extends State<EcranCreationCompte> {

  // LINK :
  // https://api.flutter.dev/flutter/material/AlertDialog-class.html

  // A t t r i b u t e s  :
  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController numeroController = TextEditingController();
  TextEditingController adresseController = TextEditingController();
  TextEditingController pieceController = TextEditingController();
  TextEditingController menuCountryNationaliteController = TextEditingController();
  TextEditingController villeResidenceController = TextEditingController();
  TextEditingController codeParrainageController = TextEditingController();
  late bool _isLoading;
  // Initial value :
  var dropdownvaluePays = "France";
  var dropdownvalueTitre = "CNI";
  String defaultGenre = "M";
  final lesGenres = ["M", "F"];
  final typePiece = ["CNI", "TITRE SEJOUR", "PASSEPORT"];
  final _userRepository = UserRepository();
  final _villeRepository = VilleRepository();
  final _cibleRepository = CibleRepository();
  final _filiationRepository = FiliationRepository();
  late BuildContext dialogContext;
  bool flagSendData = false;
  bool flagServerResponse = false;
  //
  final UserGetController _userController = Get.put(UserGetController());
  final CibleGetController _cibleController = Get.put(CibleGetController());
  //late https.Client client;
  late List<Pays> listeCountry;
  late List<Ville> listeVille;
  //
  String? getToken = "";
  Pays? paysDepartMenu;
  Ville? villeResidence;
  int init = 0;
  Filiation? filiation = null;



  // M E T H O D S
  @override
  void initState() {
    super.initState();

    listeCountry = widget.listeCountry;
    paysDepartMenu = listeCountry.first;
    listeVille = widget.listeVille.where((ville) => ville.paysid == paysDepartMenu!.id).toList();
    villeResidence = listeVille.first;
    villeResidenceController.text = villeResidence!.name;
    // Order LIST :
    listeVille.sort((a,b) => a.name.compareTo(b.name));

    // Set DATA if needed :
    checkUserPresence();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.

    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    numeroController.dispose();
    adresseController.dispose();
    pieceController.dispose();
    menuCountryNationaliteController.dispose();

    super.dispose();
  }

  // refresh Ville
  void refreshVille(List<Ville> villes){
    // Update the list :
    setState(() {
      listeVille = villes;
      listeVille.sort((a,b) => a.name.compareTo(b.name));
      villeResidence = listeVille.first;
      villeResidenceController.text = villeResidence!.name;
    }
    );
  }

  void checkUserPresence() async{
    User? usr = widget.gUser;
    if(usr != null){
      // Pick CODE PARRAINAGE :
      codeParrainageController = TextEditingController(text: usr.codeinvitation );
      nomController = TextEditingController(text: usr.nom );
      prenomController = TextEditingController(text: usr.prenom );
      emailController = TextEditingController(text: usr.email );
      numeroController = TextEditingController(text: usr.numero );
      adresseController = TextEditingController(text: usr.adresse );
      pieceController = TextEditingController(text: usr.numeropieceidentite );
      // NATIONALITE :
      paysDepartMenu = listeCountry.where((pays) => pays.iso2 == usr.nationnalite).first;
      // Refresh this :
      listeVille = await _villeRepository.findAllByPaysId(paysDepartMenu!.id);
      // Ville residence , From CIBLE :
      villeResidence = listeVille.where((ville) => ville.id == usr.villeresidence).first;
      villeResidenceController.text = villeResidence!.name;
      // PIECE IDENTITE :
      dropdownvalueTitre = usr.typepieceidentite;
    }
  }


  // Get VILLE :
  Future<List<CountryData>> countriesLoading() async {

    /*CountryData cta1 = CountryData(name: 'France', iso2: 'FR', iso3: 'FRA', unicodeFlag: '🇫🇷');
    CountryData cta2 = CountryData(name: 'Côte d\'Ivoire', iso2: 'CV', iso3: 'CIV', unicodeFlag: '🇨🇮');
    List<CountryData> lite = [cta1, cta2];
    CountryDataUnicodeList cd = CountryDataUnicodeList(error: false, msg: '', data: lite);*/

    final url = Uri.parse('https://countriesnow.space/api/v0.1/countries/flag/unicode');
    mreponse.Response response = await get(url);
    if(response.statusCode == 200){
      _isLoading = true;
      CountryDataUnicodeList ct = CountryDataUnicodeList.fromJson(json.decode(response.body));
      List<CountryData> lite = ct.data.where((e) => (e.iso3 == "FRA" || e.iso3 == "CIV")).toList();

      // Update COMMUNE :
      /*codeController = TextEditingController(text: _userController.userData.isNotEmpty ? _userController.userData[0].codeinvitation : '');
      nomController = TextEditingController(text: _userController.userData.isNotEmpty ? _userController.userData[0].nom : '');
      prenomController = TextEditingController(text: _userController.userData.isNotEmpty ? _userController.userData[0].prenom : '');
      emailController = TextEditingController(text: _userController.userData.isNotEmpty ? _userController.userData[0].email : '');
      numeroController = TextEditingController(text: _userController.userData.isNotEmpty ? _userController.userData[0].numero : '');
      adresseController = TextEditingController(text: _userController.userData.isNotEmpty ? _userController.userData[0].adresse : '');
      defaultGenre = _userController.userData.isNotEmpty ? (_userController.userData[0].genre==1 ? "M" : "F") : "M";
      dropdownvalue = _userController.userData.isNotEmpty ? posts.where((e) => e.idcom==_userController.userData[0].commune).first.libelle :
        posts[0].libelle;*/
      return lite;
    } else {
      throw Exception('Failed to load album');
    }
  }

  // Process :
  bool checkField(){
    if(nomController.text.isEmpty || prenomController.text.isEmpty || emailController.text.isEmpty ||
        codeParrainageController.text.isEmpty){
      return true;
    }
    return false;
  }

  //
  void generateTokenSuscription(String abrevPays, String pays) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic("trocross");
      getToken = await FirebaseMessaging.instance.getToken();

      sendAccountRequest(abrevPays, pays);
    }
    catch(e){
      flagServerResponse = false;
    }
  }

  // Send Account DATA :
  Future<void> sendAccountRequest(String abrevPays, String pays) async {
    final url = Uri.parse('${dotenv.env['URL']}manageuser');
    try {
      var response = await widget.client.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "iduser": widget.gUser == null ? 0 : widget.gUser!.id,
            "nom": nomController.text,
            "prenom": prenomController.text,
            "email": emailController.text,
            "contact": '***',//numeroController.text,
            "adresse": '***',//adresseController.text,
            "codeinvitation": codeParrainageController.text, // Set default :
            "numeropieceidentite": '***',// // pieceController.text
            "idpays": paysDepartMenu!.id,
            "pays": pays,
            "abreviationpays": abrevPays,
            "idville": villeResidence!.id,
            "ville": villeResidence!.name,
            "typepieceidentite": dropdownvalueTitre,
            "token": getToken,
            "smartphonetype": defaultTargetPlatform == TargetPlatform.android ? 1 : 0
          })).timeout(const Duration(seconds: timeOutValue));

      // Checks :
      if(response.statusCode == 200){
        UserCreationResponse ur =  UserCreationResponse.fromJson(json.decode(response.body));
        displayToast("Votre compte a été créé !");
        // Update or create user :
        if(_userController.userData.isEmpty){
          // Create new :
          User user = User(nationnalite: abrevPays,
              id: ur.userid,
              typepieceidentite: dropdownvalueTitre,
              numeropieceidentite: pieceController.text,
              nom: nomController.text,
              prenom: prenomController.text,
              email: emailController.text,
              numero: numeroController.text,
              adresse: adresseController.text,
              fcmtoken: getToken!,
              pwd: "",
              codeinvitation: codeParrainageController.text,
              villeresidence: villeResidence!.id,
              streamtoken: ur.streamchatoken,
              streamid: ur.streamchatid);
          // Save :
          _userController.addData(user);

          // Add default CIBLE :
          if(ur.cibleid > 0) {
            Cible cible = Cible(id: ur.cibleid,
                villedepartid: villeResidence!.id,
                paysdepartid: paysDepartMenu!.id,
                villedestid: villeResidence!.id,
                paysdestid: paysDepartMenu!.id,
                topic: '');
            _cibleController.addData(cible);

            // From there, Hit NEW FILIATION :
            Filiation filiation = Filiation(id: 1, code: ur.codeparrainage, bonus: 0);
            await _filiationRepository.insert(filiation);
          }
        }

        // Set FLAG :
        flagSendData = false;
      }
      else if(response.statusCode == 500){
        // Set FLAG :
        displayToast("Cette adresse est déjà utilisée !");
      }
      else if(response.statusCode == 501){
        // Set FLAG :
        displayToast("Code parrainage inexistant !");
      }
      else {
        // Set FLAG :
        displayToast("Erreur apparue");
      }

    }
    catch(e){}
    finally{
      // Can close WINDOW :
      flagServerResponse = false;
    }
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
                  child: Text("Compte",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      )
                  ),
                ) ,
              ),
              Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
                  child: DropdownMenu<Pays>(
                      width: MediaQuery.of(context).size.width - 20,
                      menuHeight: 250,
                      initialSelection: listeCountry.first,
                      controller: menuCountryNationaliteController,
                      hintText: "Sélectionner le pays",
                      requestFocusOnTap: false,
                      enableFilter: false,
                      label: const Text('Pays de résidence'),
                      // Initial Value
                      onSelected: (Pays? value) {
                        paysDepartMenu = value!;
                        init++;
                        // Update the list :
                        _villeRepository.findAllByPaysId(paysDepartMenu!.id).then((value) => refreshVille(value));
                      },
                      dropdownMenuEntries:
                      listeCountry.map<DropdownMenuEntry<Pays>>((Pays menu) {
                        return DropdownMenuEntry<Pays>(
                            value: menu,
                            label: menu.name,
                            leadingIcon: Icon(Icons.map));
                      }).toList()
                  )
              ),
              Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: DropdownMenu<Ville>(
                      width: MediaQuery.of(context).size.width - 20,
                      menuHeight: 250,
                      initialSelection: villeResidence,
                      controller: villeResidenceController,
                      hintText: "Ville de résidence",
                      requestFocusOnTap: true,
                      enableSearch: true,
                      enableFilter: false,
                      label: const Text('Ville résidence'),
                      // Initial Value
                      onSelected: (Ville? value) {
                        villeResidence = value!;
                      },
                      dropdownMenuEntries:
                      listeVille.map<DropdownMenuEntry<Ville>>((Ville menu) {
                        return DropdownMenuEntry<Ville>(
                            value: menu,
                            label: menu.name,
                            leadingIcon: Icon(Icons.map));
                      }).toList()
                  )
              ),
              /*Row(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: DropdownMenu<String>(
                        width: 180,
                        hintText: "Type pièce",
                        // Initial Value
                        initialSelection: typePiece.first,
                        onSelected: (String? value) {
                          // This is called when the user selects an item.
                          dropdownvalueTitre = value!;
                        },
                        dropdownMenuEntries: typePiece.map((piece) => piece).toList()
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        keyboardType: TextInputType.name,
                        controller: pieceController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Num. de la pièce',
                        ),
                        textInputAction: TextInputAction.next
                      ),
                    ),
                  ),
                ],
              ),*/
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 5, top: 10),
                      child: TextField(
                        keyboardType: TextInputType.name,
                        controller: nomController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Nom...',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5, right: 10, top: 10),
                      child: TextField(
                        keyboardType: TextInputType.name,
                        controller: prenomController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Prénom...',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: TextField(
                  keyboardType: TextInputType.emailAddress,
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email...',
                  ),
                  textInputAction: TextInputAction.next,
                ),
              )              ,
              /*Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 5, top: 10),
                      child: TextField(
                        keyboardType: TextInputType.phone,
                        controller: numeroController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Contact...',
                        ),
                        textInputAction: TextInputAction.next,
                      )
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5, right: 10, top: 10),
                      child: TextField(
                        keyboardType: TextInputType.streetAddress,
                        controller: adresseController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Adresse...',
                        ),
                      )
                    ),
                  ),
                ],
              ),*/
              Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: TextField(
                  readOnly: codeParrainageController.text.isNotEmpty && widget.gUser != null ? true : false,
                  keyboardType: TextInputType.text,
                  controller: codeParrainageController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Code Parrainage...',
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: FractionalOffset.bottomLeft,
                  child: SafeArea(
                      child: Container(
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
                              label: const Text("Enregistrer",
                                  style: TextStyle(
                                      color: Colors.white
                                  )
                              ),
                              onPressed: () async {

                                if(villeResidenceController.text != villeResidence!.name){
                                  displaySnack('Ville de résidence incorrecte !');
                                  return;
                                }

                                outil.setCheckNetworkConnected(true); // We force this :
                                if(outil.getCheckNetworkConnected()) {
                                  if(checkField()){
                                    Fluttertoast.showToast(
                                        msg: "Veuillez renseigner tous les champs !",
                                        toastLength: Toast.LENGTH_LONG,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 3,
                                        backgroundColor: Colors.red,
                                        textColor: Colors.white,
                                        fontSize: 16.0
                                    );
                                  }
                                  else{
                                    // Further CHECK on EMAIL :
                                    if(!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                        .hasMatch(emailController.text.trim())){
                                      displayToast("Renseignez une adresse email vailde !");
                                      return;
                                    }

                                    // Get 'COMMUNE' id
                                    var abrevPays = listeCountry.where((element) => element == paysDepartMenu!)
                                        .first.iso2;
                                    // Get 'Genre' id :
                                    //var idGenr = defaultGenre == "M" ? 1 : 0;
                                    var idGenr = 1;
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
                                                          Text("Création du compte ..."),
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
                                    // Send DATA :
                                    flagSendData = true;
                                    flagServerResponse = true;

                                    if(defaultTargetPlatform == TargetPlatform.iOS){
                                      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
                                      if(apnsToken == null){
                                        flagServerResponse = false;
                                      }
                                      else{
                                        generateTokenSuscription(abrevPays, paysDepartMenu!.name);
                                      }
                                    }
                                    else{
                                      generateTokenSuscription(abrevPays, paysDepartMenu!.name);
                                    }

                                    // Run TIMER :
                                    Timer.periodic(
                                      const Duration(seconds: 1),
                                          (timer) {
                                        // Update user about remaining time
                                        if(!flagServerResponse){
                                          Navigator.pop(dialogContext);
                                          timer.cancel();

                                          // Kill ACTIVITY :
                                          if(!flagSendData) {
                                            if (widget.returnValue) {
                                              Navigator.pop(context, 1);
                                            }
                                            else {
                                              Navigator.pop(context);
                                            }
                                            //Navigator.of(context).pop({'selection': '1'});
                                          }
                                          else {
                                            displaySnack('Création du compte impossible !');
                                          }
                                        }
                                      },
                                    );
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
                  )
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}