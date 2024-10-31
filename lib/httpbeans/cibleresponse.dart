import 'package:tro/httpbeans/userbean.dart';

import '../models/publication.dart';

class CibleResponse {
  final int idcible;
  final String champ;
  final List<Publication> publications;

  const CibleResponse({
    required this.idcible,
    required this.champ,
    required this.publications
  });

  factory CibleResponse.fromJson(Map<String, dynamic> json) {
    return CibleResponse(
        idcible: json['idcible'],
        champ: json['champ'],
        publications: List<dynamic>.from(json['publications']).map((i) => Publication.fromDatabaseJson(i)).toList()
    );
  }
}