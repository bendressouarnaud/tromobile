class Publication {

  // https://vaygeth.medium.com/reactive-flutter-todo-app-using-bloc-design-pattern-b71e2434f692
  // https://pythonforge.com/dart-classes-heritage/

  // A t t r i b u t e s  :
  final int id;
  final int userid;
  final int villedepart;
  final int villedestination;
  final String datevoyage;
  final String datepublication;
  final int reserve;
  final int active;
  final int reservereelle;
  final int souscripteur;
  final int milliseconds;
  final String identifiant;
  final int devise;
  final int prix;

  // M e t h o d s  :
  Publication({required this.id, required this.userid, required this.villedepart, required this.villedestination, required this.datevoyage, required this.datepublication,
    required this.reserve, required this.active, required this.reservereelle, required this.souscripteur, required this.milliseconds
  , required this.identifiant, required this.devise, required this.prix});
  factory Publication.fromDatabaseJson(Map<String, dynamic> data) => Publication(
    //This will be used to convert JSON objects that
    //are coming from querying the database and converting
    //it into a Todo object
    id: data['id'],
    userid: data['userid'],
    villedepart: data['villedepart'],
    villedestination: data['villedestination'],
    datevoyage: data['datevoyage'],
    datepublication: data['datepublication'],
    reserve: data['reserve'],
    active: data['active'],
    reservereelle: data['reservereelle'],
    souscripteur: data['souscripteur'],
    milliseconds: data['milliseconds'],
    identifiant: data['identifiant'],
    devise: data['devise'],
    prix: data['prix'],
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": id,
    "userid": userid,
    "villedepart": villedepart,
    "villedestination": villedestination,
    "datevoyage": datevoyage,
    "datepublication": datepublication,
    "reserve": reserve,
    "active": active,
    "reservereelle": reservereelle,
    "souscripteur": souscripteur,
    "milliseconds": milliseconds,
    "identifiant": identifiant,
    "devise": devise,
    "prix": prix
  };
}