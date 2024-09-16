class User {

  // https://vaygeth.medium.com/reactive-flutter-todo-app-using-bloc-design-pattern-b71e2434f692
  // https://pythonforge.com/dart-classes-heritage/

  // A t t r i b u t e s  :
  final int id;
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
  final int villeresidence;

  // M e t h o d s  :
  User({required this.nationnalite, required this.id, required this.typepieceidentite, required this.numeropieceidentite, required this.nom, required this.prenom, required this.email, required this.numero,
    required this.adresse, required this.fcmtoken, required this.pwd, required this.codeinvitation, required this.villeresidence});
  factory User.fromDatabaseJson(Map<String, dynamic> data) => User(
    //This will be used to convert JSON objects that
    //are coming from querying the database and converting
    //it into a Todo object
    id: data['id'],
    typepieceidentite: data['typepieceidentite'],
    numeropieceidentite: data['numeropieceidentite'],
    nom: data['nom'],
    prenom: data['prenom'],
    email: data['email'],
    numero: data['numero'],
    adresse: data['adresse'],
    fcmtoken: data['fcmtoken'],
    pwd: data['pwd'],
    codeinvitation: data['codeinvitation'],
    nationnalite: data['nationnalite'],
    villeresidence: data['villeresidence'],
  );

  Map<String, dynamic> toDatabaseJson() => {
    //This will be used to convert Todo objects that
    //are to be stored into the datbase in a form of JSON
    "id": id,
    "typepieceidentite": typepieceidentite,
    "numeropieceidentite": numeropieceidentite,
    "nom": nom,
    "prenom": prenom,
    "email": email,
    "numero": numero,
    "adresse": adresse,
    "fcmtoken": fcmtoken,
    "pwd": pwd,
    "codeinvitation": codeinvitation,
    "nationnalite": nationnalite,
    "villeresidence": villeresidence,
  };
}