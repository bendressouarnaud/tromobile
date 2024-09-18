import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:tro/main.dart';

import '../constants.dart';
import '../httpbeans/countrydata.dart';
import '../models/chat.dart';
import '../models/publication.dart';
import '../models/souscription.dart';
import '../models/user.dart';
import '../singletons/outil.dart';

class Servicegeo {

  // A T T R I B U T E S :



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
      String tamponDateVoyage = message.data['datevoyage'].toString().replaceFirst('Z', ':00Z');
      //List<String> tamponVoyage = message.data['datevoyage'].toString().split(":");
      //String offSet = "${tamponVoyage[1].substring(2)}:${tamponVoyage[2]}";
      //final hNow = DateTime.parse(tamponVoyage[0]+offSet.replaceFirst('Z', '+00:00'));
      final hNow = DateTime.parse(tamponDateVoyage);
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
          prix: int.parse(message.data['prix']),
          read: 0
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
          codeinvitation: "123",
          villeresidence: 0);
      // Save :
      outil.addUser(user);
    }

    // Now feed 'souscription table' :
    Souscription souscription = Souscription(
        id: 0,
        idpub: int.parse(message.data['idpub']),
        iduser: int.parse(message.data['id']),
        millisecondes: DateTime.now().millisecondsSinceEpoch,
        reserve: int.parse(message.data['reserve']),
        statut: 0);
    outil.addSouscription(souscription);
  }

  void processIncommingChat(RemoteMessage message, Outil outil, Client client) async{
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
        idlocaluser: localUser.id,
        read: 0
    );
    await outil.insertChat(newChat);

    // Send back 'ACCUSé DE RéCEPTION'
    sendAccuseReception(message.data['identifiant'], int.parse(message.data['idpub']), client);
  }

  // Hit USER and PUBLICATION :
  void performReservationCheck(RemoteMessage message, Outil outil) async {
    // Check USER's presence :
    User? user = await outil.findUserById(int.parse(message.data['id']));
    if(user == null){
      // Persist DATA :
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
          codeinvitation: "123",
          villeresidence: 0);
      // Save :
      outil.addUser(user);
    }
    
    // On PUBLICATION :
    Publication pub = await outil.refreshPublication(int.parse(message.data['publicationid']));
    Publication newPub = Publication(
        id: pub.id,
        userid: pub.userid,
        villedepart: pub.villedepart,
        villedestination: pub.villedestination,
        datevoyage: pub.datevoyage,
        datepublication: pub.datepublication,
        reserve: pub.reserve,
        active: 1,
        reservereelle: int.parse(message.data['reservevalide']),
        souscripteur: pub.souscripteur, // Use OWNER Id
        milliseconds: pub.milliseconds,
        identifiant: pub.identifiant,
        devise: pub.devise,
        prix: pub.prix,
        read: 1
    );
    // Update  :
    await outil.updatePublicationWithoutFurtherActions(newPub);
  }

  // Hit PUBLICATION :
  void trackPublicationDelivery(RemoteMessage message, Outil outil) async {
    // On PUBLICATION :
    Publication pub = await outil.refreshPublication(int.parse(message.data['idpub']));
    Publication newPub = Publication(
        id: pub.id,
        userid: pub.userid,
        villedepart: pub.villedepart,
        villedestination: pub.villedestination,
        datevoyage: pub.datevoyage,
        datepublication: pub.datepublication,
        reserve: pub.reserve,
        active: 2,
        reservereelle: pub.reservereelle,
        souscripteur: pub.souscripteur, // Use OWNER Id
        milliseconds: pub.milliseconds,
        identifiant: pub.identifiant,
        devise: pub.devise,
        prix: pub.prix,
        read: 1
    );
    // Update  :
    //await outil.updatePublication(newPub);
    await outil.updatePublicationWithoutFurtherActions(newPub);
  }


  // Refresh CHAT
  void markChatReceipt(RemoteMessage message) async {
    Chat ct = await outil.findChatByIdentifiant(message.data['identifiant']);
    Chat newChat = Chat(
        id: ct.id,
        idpub: ct.idpub,
        milliseconds: ct.milliseconds,
        sens: ct.sens,
        contenu: ct.contenu,
        statut: 3, // Accusé de réception
        identifiant: ct.identifiant,
        iduser: ct.iduser,
        idlocaluser: ct.idlocaluser,
        read: ct.read
    );
    await outil.updateData(newChat);
  }


  Future<Widget> processAnnonceIcon(IconData iconData) async{
    List<Publication> liste = await outil.findAllPublication();
    int taille = liste.where((element) => element.read == 0).toList().length;
    if(taille > 0){
      return Badge.count(
        count: taille,
        child: Icon(iconData)
      );
    }
    else {
      return Icon(iconData);
    }
  }

  // Send Account DATA :
  Future<void> sendAccuseReception(String identifiant, int idpub, Client client) async {
    final url = Uri.parse('${dotenv.env['URL']}sendaccusereception');
    await client.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifiant": identifiant,
          "idpub": idpub
        })
    ).timeout(const Duration(seconds: timeOutValue));
  }
}