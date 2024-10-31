

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:http/http.dart';
import 'package:tro/getxcontroller/getciblecontroller.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import 'constants.dart';
import 'creercible.dart';
import 'models/cible.dart';
import 'models/pays.dart';
import 'models/publication.dart';
import 'models/ville.dart';

class GestionCible extends StatefulWidget {
  // Attributes
  final Client client;
  GestionCible({Key? key, required this.client}) : super(key: key);

  @override
  State<GestionCible> createState() => _GestionCible();
}

class _GestionCible extends State<GestionCible> {
  // A T T R I B U T E S:
  final CibleGetController _cibleController = Get.put(CibleGetController());
  List<Pays> listePays = [];
  List<Ville> listeVille = [];
  List<Cible> listeCible = [];
  final _paysRepository = PaysRepository();
  final _villeRepository = VilleRepository();


  // M E T H O D S
  @override
  void initState() {
    super.initState();
    
  }
  
  Future<List<Cible>> getData() async{
    listePays = await _paysRepository.findAll();
    listeVille = await _villeRepository.findAll();
    return _cibleController.data;
  }

  // Get Country
  String getCountryName(int idPays){
    return listePays.where((pays) => pays.id == idPays).single.name;
  }

  String getTownName(int idVille){
    Ville? mVille = listeVille.where((ville) => ville.id == idVille).firstOrNull;
    return mVille != null ? mVille.name : "...";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Gestion des cibles',
            textAlign: TextAlign.start,
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )),
          /*actions: [
            IconButton(
                onPressed: () {
                  /*Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return SearchEcran(client: client!);
                    }));*/
                },
                icon: const Icon(Icons.search, color: Colors.black)
            )
          ]*/
      ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromRGBO(51, 159, 255, 1.0),
          tooltip: 'Nouvelle cible',
          onPressed: (){
            Navigator.push(context,
                MaterialPageRoute(builder: (context) {
                  return CreerCible(
                      idpaysdep: 1,
                      idpaysdest: 1,
                      idvilledep: 1,
                      idvilledest: 1,
                      idCible: 0,
                    client: widget.client,
                  );
                }));
          },
          child: const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 28),
        ),
      body: FutureBuilder(
          future: Future.wait([getData()]),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              // Get DATA
              listeCible = snapshot.data[0];
              
              return GetBuilder<CibleGetController>(builder: (_) {
                return ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: listeCible.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GetBuilder<CibleGetController>(
                          builder: (_)
                          {
                            return GestureDetector(
                              onTap: () {
                                // Display DIALOG
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                      return CreerCible(
                                        idpaysdep: listeCible[index].paysdepartid,
                                        idpaysdest: listeCible[index].paysdestid,
                                        idvilledep: listeCible[index].villedepartid,
                                        idvilledest: listeCible[index].villedestid,
                                        idCible: listeCible[index].id,
                                        client: widget.client
                                      );
                                    }));
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: cardviewsousproduit,
                                      borderRadius: BorderRadius.circular(8.0)
                                  ),
                                  margin: const EdgeInsets.all(3),
                                  padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                                  width: MediaQuery.of(context).size.width,
                                  height: 90,
                                  child: Column(
                                    children: [
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Départ'),
                                          Text('Destination')
                                        ],
                                      ),
                                      const Divider(
                                        height: 2,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(getCountryName(listeCible[index].paysdepartid)),
                                          const Icon(Icons.arrow_right_sharp),
                                          Text(getCountryName(listeCible[index].paysdestid),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold
                                          ),)
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(getTownName(listeCible[index].villedepartid)),
                                          const Icon(Icons.arrow_right_sharp),
                                          Text(getTownName(listeCible[index].villedestid),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold
                                            ),)
                                        ],
                                      )
                                    ],
                                  )
                              ),
                            );
                          }
                      );
                    }
                );
              });
            }
            else return Container(
              child: Center(
                child: Text('Chargement ...'),
              ),
            );
          }
      )
    );
  }
}