class Souscription {

  // A t t r i b u t e s  :
  final int id;
  final int idpub;
  final int iduser;
  final int millisecondes;
  final int reserve;
  final int statut; // 0 : encours , 1 : traité, 2 : annulé par le souscripteur

  // M e t h o d s  :
  Souscription({required this.id, required this.idpub, required this.iduser, required this.millisecondes, required this.reserve
    , required this.statut});
  factory Souscription.fromDatabaseJson(Map<String, dynamic> data) => Souscription(
    id: data['id'],
    idpub: data['idpub'],
    iduser: data['iduser'],
    millisecondes: data['millisecondes'],
    reserve: data['reserve'],
    statut: data['statut'],
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": id,
    "idpub": idpub,
    "iduser": iduser,
    "millisecondes": millisecondes,
    "reserve": reserve,
    "statut": statut
  };
}