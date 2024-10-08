import 'dart:convert';

import 'package:tro/httpbeans/souscriptionbean.dart';
import 'package:tro/httpbeans/userbean.dart';
import 'package:tro/models/cible.dart';
import 'package:tro/models/publication.dart';

class AuthenticateResponse {

  // https://vaygeth.medium.com/reactive-flutter-todo-app-using-bloc-design-pattern-b71e2434f692
  // https://pythonforge.com/dart-classes-heritage/

  // A t t r i b u t e s  :
  final int id;
  final int villeresidence;
  final String typepieceidentite;
  final String numeropieceidentite;
  final String nationnalite;
  final String nom;
  final String prenom;
  final String email;
  final String numero;
  final String adresse;
  final String fcmtoken;
  final String pwd;
  final String codeinvitation;
  final List<Cible> cibles;
  final List<Publication> publications;
  final List<UserBean> souscripteurs;
  final List<SouscriptionBean> sosucriptions;
  final String codeparrainage;
  final double bonus;

  // M e t h o d s  :
  AuthenticateResponse({required this.nationnalite, required this.id, required this.typepieceidentite, required this.numeropieceidentite, required this.nom, required this.prenom, required this.email, required this.numero,
    required this.adresse, required this.fcmtoken, required this.pwd, required this.codeinvitation, required this.cibles
    , required this.publications, required this.souscripteurs, required this.sosucriptions, required this.villeresidence
    , required this.codeparrainage, required this.bonus});
  factory AuthenticateResponse.fromJson(Map<String, dynamic> json) {
    return AuthenticateResponse(
      //This will be used to convert JSON objects that
      //are coming from querying the database and converting
      //it into a Todo object
      id: json['id'],
      villeresidence: json['villeresidence'],
      typepieceidentite: json['typepieceidentite'],
      numeropieceidentite: json['numeropieceidentite'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      numero: json['numero'],
      adresse: json['adresse'],
      fcmtoken: json['fcmtoken'],
      pwd: json['pwd'],
      codeinvitation: json['codeinvitation'],
      nationnalite: json['nationnalite'],
      cibles: List<dynamic>.from(json['cibles']).map((i) => Cible.fromDatabaseJson(i)).toList(),
      publications: List<dynamic>.from(json['publications']).map((i) => Publication.fromDatabaseJson(i)).toList(),
      souscripteurs: List<dynamic>.from(json['publicationowner']).map((i) => UserBean.fromJson(i)).toList(),
      sosucriptions: List<dynamic>.from(json['subscriptions']).map((i) => SouscriptionBean.fromJson(i)).toList(),
      codeparrainage: json['codeparrainage'],
      bonus: json['bonus']
    );
  }
}