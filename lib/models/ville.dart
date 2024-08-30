class Ville {

  // A t t r i b u t e s  :
  final int id;
  final String name;
  final int paysid;

  // M e t h o d s  :
  Ville({required this.id, required this.name, required this.paysid});
  factory Ville.fromDatabaseJson(Map<String, dynamic> data) => Ville(
    //This will be used to convert JSON objects that
    //are coming from querying the database and converting
    //it into a Todo object
      id: data['id'],
      name: data['name'],
      paysid: data['paysid']
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": id,
    "name": name,
    "paysid": paysid
  };
}