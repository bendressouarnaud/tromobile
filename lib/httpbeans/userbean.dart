import 'dart:convert';

import 'package:tro/models/cible.dart';
import 'package:tro/models/publication.dart';

class UserBean {

  // https://vaygeth.medium.com/reactive-flutter-todo-app-using-bloc-design-pattern-b71e2434f692
  // https://pythonforge.com/dart-classes-heritage/

  // A t t r i b u t e s  :
  final int iduser;
  final String nationalite;
  final String nom;
  final String prenom;
  final String adresse;

  // M e t h o d s  :
  UserBean({required this.nationalite, required this.iduser, required this.nom, required this.prenom,
    required this.adresse});
  factory UserBean.fromJson(Map<String, dynamic> json) {
    return UserBean(
      //This will be used to convert JSON objects that
      //are coming from querying the database and converting
      //it into a Todo object
        iduser: json['iduser'],
        nom: json['nom'],
        prenom: json['prenom'],
        adresse: json['adresse'],
        nationalite: json['nationalite']
    );
  }
}