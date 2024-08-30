class Chat {

  // https://vaygeth.medium.com/reactive-flutter-todo-app-using-bloc-design-pattern-b71e2434f692
  // https://pythonforge.com/dart-classes-heritage/

  // A t t r i b u t e s  :
  final int id;
  final int idpub;
  final int iduser;
  final int idlocaluser;
  final int milliseconds;
  final int sens; // 0 : Utilisateur actuel, 1 : Expéditeur
  final int statut; // 0 : A transmettre, 1 : Envoyé, 2 : reçu
  final String contenu;
  final String identifiant;

  // M e t h o d s  :
  Chat({required this.id,required this.idpub,required this.milliseconds,required this.sens,required this.statut,required this.contenu
    ,required this.identifiant, required this.iduser, required this.idlocaluser});
  factory Chat.fromDatabaseJson(Map<String, dynamic> data) => Chat(
    //it into a Todo object
    id: data['id'],
    idpub: data['idpub'],
    milliseconds: data['milliseconds'],
    sens: data['sens'],
    statut: data['statut'],
    contenu: data['contenu'],
    identifiant: data['identifiant'],
    iduser: data['iduser'],
    idlocaluser: data['idlocaluser']
  );

  Map<String, dynamic> toDatabaseJson() => {
    //This will be used to convert Todo objects that
    //are to be stored into the datbase in a form of JSON
    "id": id,
    "idpub": idpub,
    "milliseconds": milliseconds,
    "sens": sens,
    "statut": statut,
    "contenu": contenu,
    "identifiant": identifiant,
    "iduser": iduser,
    "idlocaluser": idlocaluser
  };
}