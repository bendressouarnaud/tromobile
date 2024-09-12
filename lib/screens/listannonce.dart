
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:tro/models/pays.dart';
import 'package:tro/repositories/ville_repository.dart';

import '../constants.dart';
import '../getxcontroller/getpublicationcontroller.dart';
import '../historiqueannonce.dart';
import '../models/publication.dart';
import '../models/user.dart';
import '../models/ville.dart';
import '../repositories/pays_repository.dart';

class EcranAnnonce {

  // Attributes :
  final _paysRepository = PaysRepository();
  final _villeRepository = VilleRepository();
  late BuildContext dialogContext;
  TextEditingController reserveController = TextEditingController();
  final lesCouleurs = [Colors.black12, Colors.blue[100], Colors.blueGrey[100], Colors.red[100], Colors.orange[100], Colors.yellow[100],
  Colors.green[100], Colors.purple[100], Colors.brown[100], Colors.white70, Colors.pink[100]];
  int cptCouleur = 0;
  List<String> listeDate = [];


  // Limit Country length :
  String limitWord(int idVill, List<Pays> pays, List<Ville> villes) {
    // Get Pays from idVille
    Ville ville = villes.where((ville) => ville.id == idVill).single;
    // Get Country
    Pays lePays = pays.where((pys) => pys.id == ville.paysid).single;
    String tampnVille = ville.name.length > 15 ? '${ville.name.substring(0,14)}...' : ville.name;
    //String tampnPays  = lePays.name.length > 15 ? '${lePays.name.substring(0,14)}...' : lePays.name;
    String tampnPays  = lePays.iso3;
    // Get the country :
    //Pays pays = await _paysRepository
    return "$tampnPays ($tampnVille)";
  }

  Widget displayObjectData(Publication pub, List<Pays> pays, List<Ville> villes, List<User> user, BuildContext context,
      bool historique) {
    return GestureDetector(
      onTap: () {
        // Display DIALOG
        Navigator.push(context,
            MaterialPageRoute(builder: (context) {
              return HistoriqueAnnonce(publication: pub,
                  ville: villes.where((ville) => ville.id == pub.villedestination).single,
                  villeDepart: villes.where((ville) => ville.id == pub.villedepart).single,
                  userOrSuscriber: !(pub.userid == user.first.id) ? 0 : 1,
              historique: historique);
            }));
      },
      child: Container(
          decoration: BoxDecoration(
              color: markPublicationAsNotRead(pub),
              borderRadius: BorderRadius.circular(8.0)
          ),
          margin: const EdgeInsets.only(left: 7,right: 7, bottom: 15),
          width: MediaQuery.of(context).size.width,
          height: 95,
          child: Row(
            children: [
              ElevatedButton(
                  onPressed: (){},
                  style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: pub.userid == user.first.id ? Colors.white : processButtonColor()
                  ),
                  child: pub.userid == user.first.id ? Icon(
                    Icons.person_outline,
                    color: Colors.red[400],
                    size: 30.0,
                  ) :
                  Text(generateRaccourci(pub.villedepart, pub.villedestination, villes),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                      )
                  )
              ),
              Expanded(
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(pub.identifiant),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(limitWord(pub.villedepart, pays, villes),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                )),
                            Text(limitWord(pub.villedestination, pays, villes),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                ))
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(processDate(pub.datevoyage, 0)),
                            Text(processDate(pub.datevoyage, 1))
                          ],
                        ),
                      ),
                      Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text('Réserve : '),
                                  Text('${pub.reserve} Kg',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87
                                      )
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  Text(pub.prix == 0 ? 'Gratuit' : 'Payant',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: pub.prix == 0 ? const Color(
                                              0xFF16A807) :
                                          Colors.red
                                      )
                                  )
                                ],
                              )
                            ],
                          )
                      )
                    ],
                  )
              )
            ],
          )
      ),
    );
  }

  String processDateDisplay(String date){
    List<String> tampon = date.split("T");
    List<String> jour = tampon[0].split("-");
    return '${jour[2]}/${jour[1]}/${jour[0]}';
  }

  String displayDate(String date) {
    if( listeDate.isEmpty ){
      listeDate.add(processDateDisplay(date));
      return listeDate[0];
    }
    else{
      String tampon = processDateDisplay(date);
      // Look for this :
      int taille = listeDate.where((element) => element == tampon).toList().length;
      if(taille == 0){
        // No match, add :
        listeDate.add(tampon);
        return tampon;
      }
      else{
        // Exist already :
        return "";
      }
    }
  }

  Color markPublicationAsNotRead(Publication publication){
    return publication.read == 0 ? const Color(0xFFECECF1) :
    const Color(0xFFFFFFFF);
  }

  String generateRaccourci(int villeDepart, int villeDest, List<Ville> villes){
    Ville villeDEP = villes.where((ville) => ville.id == villeDepart).single;
    Ville villeDES = villes.where((ville) => ville.id == villeDest).single;
    return '${villeDEP.name.substring(0,1)}${villeDES.name.substring(0,1)}';
  }

  // Process Date
  String processDate(String date, int index){
    var tmp = date.split("T");
    return tmp[index];
  }

  // Set COLOR :
  Color processColor(int taille){
    if(taille > 0 && taille <= 3){
      return Colors.orange;
    }
    else if(taille > 3){
      return Colors.green;
    }
    else return Colors.red;
  }

  Color? processButtonColor(){
    if(cptCouleur==11) cptCouleur = 0;
    return lesCouleurs[cptCouleur++];
  }

  // Check USER :
  //int checkUser()

  // Display DialogBox
  void displayAlert(BuildContext context, int reserveMax) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext dContext) {
          dialogContext = dContext;
          return AlertDialog(
              title: const Text('Précisez votre réservation',
              style: TextStyle(
                fontSize: 20
              ),
              ),
              content: Container(
                width: 300,
                margin: EdgeInsets.only(top: 15),
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: reserveController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Réserve (kg)',
                  ),
                  style: TextStyle(
                      height: 0.8
                  ),
                  textAlignVertical: TextAlignVertical.bottom,
                  textAlign: TextAlign.center,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('Annuler',
                    style: TextStyle(
                        color: Colors.brown
                    ),),
                ),
                TextButton(
                  onPressed: () {

                    // Send DATA :
                    /*flagDeleteData = true;
                    deleteAchat(idart);

                    // Run TIMER :
                    Timer.periodic(
                      const Duration(seconds: 1),
                          (timer) {
                        // Update user about remaining time
                        if(!flagDeleteData){
                          Navigator.pop(dialogContext);
                          timer.cancel();

                          // if PANIER is empty, then CLOSE the INTERFACE :
                          if(_achatController.taskData.isEmpty){
                            // Kill ACTIVITY :
                            if(Navigator.canPop(context)){
                              Navigator.pop(context);
                            }
                          }
                          else{
                            setState(() {
                            });
                          }
                        }
                      },
                    );*/

                  },
                  child: const Text('Valider',
                  style: TextStyle(
                    color: greenAlertValidation
                  ),
                  ),
                ),
              ]
          );
        }
    );
  }


  // Methods
  Widget displayAnnonce(List<Publication> liste, List<Pays> pays, List<Ville> villes, List<User> user,BuildContext context,
      bool historique){
    return
    liste.length > 0 ?
    ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: liste.length,
        itemBuilder: (BuildContext context, int index) {
          return GetBuilder<PublicationGetController>(
              builder: (_)
              {
                String currentDate = displayDate(liste[index].datepublication);
                return currentDate.isNotEmpty ?
                Column(
                  children: [
                    Container(
                      //alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(left: 7,right: 7, top: 15),
                      child: Text(currentDate)
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 7,right: 7, top: 7, bottom: 7),
                      child: const Divider(
                        color: Colors.black,
                        height: 5,
                      )
                    ),
                    displayObjectData(liste[index], pays, villes, user, context, historique)
                  ],
                ) :
                displayObjectData(liste[index], pays, villes, user, context, historique);
              }
          );
        }
    ) :
    Container(
      margin: EdgeInsets.only(top: (MediaQuery.of(context).size.width / 2)),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.airplanemode_active,
                  color: Colors.black,
                  size: 50.0,
                ),
                Icon(
                  Icons.car_repair,
                  color: Colors.brown,
                  size: 50.0,
                ),
                Icon(
                  Icons.directions_boat_outlined,
                  color: Color.fromRGBO(51, 159, 255, 1.0),
                  size: 50.0,
                )
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: const Text("Aucune annonce",
                  style: TextStyle(
                    color: Colors.black,
                    //fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )
              )
            )
          ],
        )
    );
  }
}