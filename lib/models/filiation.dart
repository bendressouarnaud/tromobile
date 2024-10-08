class Filiation {

  // A t t r i b u t e s  :
  final int id;
  final String code;
  final double bonus;

  // M e t h o d s  :
  Filiation({required this.id,required this.code,required this.bonus});
  factory Filiation.fromDatabaseJson(Map<String, dynamic> data) => Filiation(
    //it into a Todo object
      id: data['id'],
      code: data['code'],
      bonus: data['bonus']
  );

  Map<String, dynamic> toDatabaseJson() => {
    //This will be used to convert Todo objects that
    //are to be stored into the datbase in a form of JSON
    "id": id,
    "code": code,
    "bonus": bonus
  };
}