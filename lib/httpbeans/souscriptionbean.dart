import 'dart:convert';

import 'package:tro/models/cible.dart';
import 'package:tro/models/publication.dart';

class SouscriptionBean {

  // https://vaygeth.medium.com/reactive-flutter-todo-app-using-bloc-design-pattern-b71e2434f692
  // https://pythonforge.com/dart-classes-heritage/

  // A t t r i b u t e s  :
  final int iduser;
  final int idpub;
  final int millisecondes;
  final int reserve;
  final int statut;
  final String channelid;

  // M e t h o d s  :
  SouscriptionBean({required this.iduser, required this.idpub, required this.millisecondes, required this.reserve
    , required this.statut, required this.channelid});
  factory SouscriptionBean.fromJson(Map<String, dynamic> json) {
    return SouscriptionBean(
      //This will be used to convert JSON objects that
      //are coming from querying the database and converting
      //it into a Todo object
        iduser: json['iduser'],
        idpub: json['idpub'],
        millisecondes: json['millisecondes'],
        reserve: json['reserve'],
        statut: json['statut'],
        channelid: json['channelid']
    );
  }
}