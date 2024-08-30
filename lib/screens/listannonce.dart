
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
    if(cptCouleur==12) cptCouleur = 0;
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
  Widget displayAnnonce(List<Publication> liste, List<Pays> pays, List<Ville> villes, List<User> user,BuildContext context){
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
                return GestureDetector(
                    onTap: () {
                      // Display DIALOG
                      //!(liste[index].userid == user.first.id) ? displayAlert(context, liste[index].reserve) :
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                            return HistoriqueAnnonce(publication: liste[index],
                                ville: villes.where((ville) => ville.id == liste[index].villedestination).single,
                              villeDepart: villes.where((ville) => ville.id == liste[index].villedepart).single,
                              userOrSuscriber: !(liste[index].userid == user.first.id) ? 0 : 1);
                          }));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        //color: cardviewsousproduit,
                        borderRadius: BorderRadius.circular(8.0)
                      ),
                      margin: const EdgeInsets.only(left: 3,right: 3, bottom: 25),
                      width: MediaQuery.of(context).size.width,
                      height: 95,
                      child: Row(
                        children: [
                          ElevatedButton(
                              onPressed: (){},
                              style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  backgroundColor: liste[index].userid == user.first.id ? Colors.white : processButtonColor()
                              ),
                              child: liste[index].userid == user.first.id ? Icon(
                                Icons.person_outline,
                                color: Colors.red[400],
                                size: 30.0,
                              ) :
                              Text(generateRaccourci(liste[index].villedepart, liste[index].villedestination, villes),
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
                                    child: Text(liste[index].identifiant),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(right: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(limitWord(liste[index].villedepart, pays, villes),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87
                                            )),
                                        Text(limitWord(liste[index].villedestination, pays, villes),
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
                                        Text(processDate(liste[index].datevoyage, 0)),
                                        Text(processDate(liste[index].datevoyage, 1))
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    child: Row(
                                      children: [
                                        const Text('Réserve : '),
                                        Text('${liste[index].reserve} Kg',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87
                                            )
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
                          )
                        ],
                      )
                    ),
                );
              }
          );
        }
    ) :
    Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            opacity: 0.2,
            image: AssetImage("assets/images/arret_bus.jpeg"),
          ),
          border: Border.all(
              color: Colors.black
          ),
          borderRadius: BorderRadius.circular(8.0),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [
              0.3,
              0.58,
            ],
            colors: [
              Colors.white38,
              Colors.blue,
            ],
          )
      ),
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Align(
        alignment: Alignment.topCenter,
        child: Text("Aucune annonce",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            )
        ),
      ),
      //color: Colors.blue,
    );
  }
}