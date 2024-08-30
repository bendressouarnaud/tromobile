class Pays {

  // https://vaygeth.medium.com/reactive-flutter-todo-app-using-bloc-design-pattern-b71e2434f692
  // https://pythonforge.com/dart-classes-heritage/

  // A t t r i b u t e s  :
  final int id;
  final String name;
  final String iso2;
  final String iso3; // ville
  final String unicodeFlag; // ville

  // M e t h o d s  :
  Pays({required this.id, required this.name, required this.iso2, required this.iso3,
    required this.unicodeFlag});
  factory Pays.fromDatabaseJson(Map<String, dynamic> data) => Pays(
    //This will be used to convert JSON objects that
    //are coming from querying the database and converting
    //it into a Todo object
      id: data['id'],
      name: data['name'],
      iso2: data['iso2'],
      iso3: data['iso3'],
      unicodeFlag: data['unicodeFlag']
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": id,
    "name": name,
    "iso2": iso2,
    "iso3": iso3,
    "unicodeFlag": unicodeFlag,
  };
}