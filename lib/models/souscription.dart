class Souscription {

  // A t t r i b u t e s  :
  final int id;
  final int idpub;
  final int iduser;
  final int millisecondes;
  final int reserve;

  // M e t h o d s  :
  Souscription({required this.id, required this.idpub, required this.iduser, required this.millisecondes, required this.reserve});
  factory Souscription.fromDatabaseJson(Map<String, dynamic> data) => Souscription(
    id: data['id'],
    idpub: data['idpub'],
    iduser: data['iduser'],
    millisecondes: data['millisecondes'],
    reserve: data['reserve'],
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": id,
    "idpub": idpub,
    "iduser": iduser,
    "millisecondes": millisecondes,
    "reserve": reserve
  };
}