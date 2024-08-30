import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tro/models/ville.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/ville_repository.dart';
import 'authentification.dart';
import 'constants.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as https;

import 'ecrancreationcompte.dart';
import 'gestioncible.dart';
import 'getxcontroller/getusercontroller.dart';
import 'httpbeans/countrydata.dart';
import 'models/pays.dart';



class EcranCompte extends StatefulWidget {
  const EcranCompte({Key? key}) : super(key: key);

  @override
  State<EcranCompte> createState() => _NewEcranState();
}

class _NewEcranState extends State<EcranCompte> {
  // A t t r i b u t e s  :
  //late Future<List<Produit>> futureProduit;
  //late Future<List<Beanarticledetail>> futureBeanarticle;
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
  int cptInit = 0;
  late List<Pays> listePays;
  late List<Ville> listeVille;



  // M e t h o d  :
  @override
  void initState() {
    //client = widget.client;
    loadingPays();
    super.initState();
  }

  //
  void loadingPays() async {
    listePays = await _paysRepository.findAll();
    listeVille = await _villeRepository.findAll();
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


  // Delete ACHAT
  void deleteAccount() async {
    final url = Uri.parse(
        '${dotenv.env['URL']}backendcommerce/deleteaccountfromphone');
    // client.
    var response = await post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": _userController.userData.isNotEmpty ? _userController.userData[0].id : 0,
          "lib": 'deletion',
        }));

    // Checks :
    if (response.statusCode == 200) {
      //List<dynamic> body = jsonDecode(response.body);
      /*RequestBean rn = RequestBean.fromJson(jsonDecode(const Utf8Decoder().convert(response.bodyBytes)));
      if (rn != null) {
        if (rn.id == 1) {
          // Clear the USER's ACCOUNT :
          await _userController.deleteUser(_userController.userData[0].idcli);
        }
        else {
          Fluttertoast.showToast(
              msg: "Suppression du compte imposible !",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0
          );
        }
      }

      // Set FLAG :
      accountDeletion = false;*/
    }
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
        body: Container(
          color: Colors.brown[50],
          child: Column(
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
                            onPressed: () {
                              //

                              if(listePays.isNotEmpty){
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder:
                                        (context) =>
                                            EcranCreationCompte(listeCountry: listePays, listeVille: listeVille,)
                                    )
                                );

                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[400]
                            ),
                            child: GetBuilder<UserGetController>(
                              builder: (_) {
                                return Text (_userController.userData.isEmpty ? "CONNECTEZ-VOUS" : "MON COMPTE",
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
              Container(
                margin: const EdgeInsets.only(top: 10, left: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right_sharp,
                      color: Colors.black,
                      size: 30,
                    ),
                    GestureDetector(
                      onTap: () {
                        // Display DIALOG
                        Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                      return GestionCible();
                                    }));
                      },
                      child: Text('Gestion des cibles',
                        style: TextStyle(
                            fontSize: 18
                        ),
                      ),
                    )

                  ],
                ),
              ),
              /*Container(
                height: 40,
                color: Colors.white,
                margin: const EdgeInsets.only(right: 7, left: 7),
                child: const Row(
                  children: [
                    Icon(
                      Icons.emoji_people,
                      color: Colors.black,
                      size: 24.0,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text("Parrainage"),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                          size: 24.0,
                        ),
                      )
                    ),
                  ]
                ),
              ),
              Container(
                height: 40,
                color: Colors.white,
                margin: const EdgeInsets.only(right: 7, left: 7),
                child: const Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: Colors.black,
                        size: 24.0,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Filleul"),
                      Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black,
                              size: 24.0,
                            ),
                          )
                      ),
                    ]
                ),
              ),
              Container(
                height: 40,
                color: Colors.white,
                margin: const EdgeInsets.only(right: 7, left: 7),
                child: const Row(
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: Colors.black,
                        size: 24.0,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Bonus"),
                      Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black,
                              size: 24.0,
                            ),
                          )
                      ),
                    ]
                ),
              ),*/
              const SizedBox(
                height: 70,
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
                              return AuthentificationEcran();
                            }
                            ));
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
                                  return AlertDialog(
                                      title: const Text('Information'),
                                      content: const Text(
                                          "Confirmer la suppression de votre compte ?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, 'Cancel'),
                                          child: const Text('NON'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Send DATA :
                                            accountDeletion = true;
                                            deleteAccount();

                                            // Run TIMER :
                                            Timer.periodic(
                                              const Duration(seconds: 1),
                                                  (timer) {
                                                // Update user about remaining time
                                                if (!accountDeletion) {
                                                  Navigator.pop(dialogContext);
                                                  timer.cancel();

                                                  // if PANIER is empty, then CLOSE the INTERFACE :
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
                                  );
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
          ),
        )
    );
  }
}
