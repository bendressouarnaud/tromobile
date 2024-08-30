import 'package:firebase_messaging/firebase_messaging.dart';

import '../httpbeans/countrydata.dart';
import '../models/chat.dart';
import '../models/publication.dart';
import '../models/souscription.dart';
import '../models/user.dart';
import '../singletons/outil.dart';

class Servicegeo {


  //
  List<CountryData> generateCountry(){
    List<CountryData> liste = [
      CountryData(name: 'France', iso2: 'FR', iso3: 'FRA', unicodeFlag: '🇫🇷'),
      CountryData(name: 'Côte d\'Ivoire', iso2: 'CV', iso3: 'CIV', unicodeFlag: '🇨🇮')
    ];
    return liste;
  }

  // Generate Publication :
  Publication? generatePublication(RemoteMessage message){
    if(message.data.isNotEmpty){
      // Date voyage :
      List<String> tamponVoyage = message.data['datevoyage'].toString().split(":");
      // Delete following two characters :
      //String offSet = tamponVoyage[1].substring(0,2);
      String offSet = "${tamponVoyage[1].substring(2)}:${tamponVoyage[2]}";
      final hNow = DateTime.parse(tamponVoyage[0]+offSet);
      String tamponNow = hNow.toString();
      List<String> tamponFinal = tamponNow.split(" ");
      String getHour = tamponFinal[1].substring(0,8);
      String finalDateVoyage = "${tamponFinal[0]}T$getHour";
      // Set DATA :
      Publication pub = Publication(
          id: int.parse(message.data['id']),
          userid: int.parse(message.data['userid']),
          villedepart: int.parse(message.data['villedepart']),
          villedestination: int.parse(message.data['villedestination']),
          datevoyage: finalDateVoyage,
          datepublication: message.data['datepublication'],
          reserve: int.parse(message.data['reserve']),
          active: 1,
          reservereelle: int.parse(message.data['reserve']),
          souscripteur: 0,
          milliseconds: hNow.millisecondsSinceEpoch,
          identifiant: message.data['identifiant'],
          devise: int.parse(message.data['devise']),
          prix: int.parse(message.data['prix'])
      );
      return pub;
    }
    else return null;
  }

  // Process :
  void processReservationNotif(RemoteMessage message, Outil outil) async{
    User? user = await outil.findUserById(int.parse(message.data['id']));
    if(user == null){
      // Persist DATA :
      // Create new :
      user = User(nationnalite: message.data['nationalite'],
          id: int.parse(message.data['id']),
          typepieceidentite: '',
          numeropieceidentite: '',
          nom: message.data['nom'],
          prenom: message.data['prenom'],
          email: '',
          numero: '',
          adresse: message.data['adresse'],
          fcmtoken: '',
          pwd: "123",
          codeinvitation: "123");
      // Save :
      outil.addUser(user);
    }

    // Now feed 'souscription table' :
    Souscription souscription = Souscription(
        id: 0,
        idpub: int.parse(message.data['idpub']),
        iduser: int.parse(message.data['id']),
        millisecondes: DateTime.now().millisecondsSinceEpoch,
        reserve: int.parse(message.data['reserve']));
    outil.addSouscription(souscription);
  }

  void processIncommingChat(RemoteMessage message, Outil outil) async{
    User localUser = outil.getLocalUser();
    Chat newChat = Chat(
        id: 0,
        idpub: int.parse(message.data['idpub']),
        milliseconds: int.parse(message.data['time']),
        sens: 1,
        contenu: message.data['message'],
        statut: 2,
        identifiant: message.data['identifiant'],
        iduser: int.parse(message.data['sender']),
        idlocaluser: localUser.id
    );
    await outil.insertChat(newChat);
  }
}