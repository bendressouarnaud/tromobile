import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';
import 'package:tro/screens/listannonce.dart';

import 'main.dart';
import 'models/pays.dart';
import 'models/publication.dart';
import 'models/user.dart';
import 'models/ville.dart';

class Historique extends StatelessWidget {
  Historique({ super.key });

  // O B J E C T S :
  final _paysRepository = PaysRepository();
  final _userRepository = UserRepository();
  final _villeRepository = VilleRepository();
  List<Pays> listePays = [];
  List<Ville> listeVille = [];
  User? localUser;


  // M E T H O D S :
  Future<List<Publication>> pickData() async {
    //
    localUser = await _userRepository.getConnectedUser();
    listePays = await _paysRepository.findAll();
    listeVille = await _villeRepository.findAll();
    return await outil.findOldAll();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([pickData()]),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot){
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            List<Publication> data = snapshot.data[0];
            return data.isNotEmpty ?
            SingleChildScrollView(
              child: EcranAnnonce().displayAnnonce(snapshot.data[0], listePays, listeVille,
                  [localUser!] ,context, true),
            )
            :
            const Center(
              child: Text('Aucun historique',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17
                )
              )
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 3.0, // Width of the circular line
              )
            );
          }
        }
    );
  }
}