class Parameters {

  // A t t r i b u t e s  :
  final int id;
  final String state;
  final int travellocal;
  final int travelabroad;

  // M e t h o d s  :
  Parameters({required this.id, required this.state, required this.travellocal, required this.travelabroad});
  factory Parameters.fromDatabaseJson(Map<String, dynamic> data) => Parameters(
    //This will be used to convert JSON objects that
    //are coming from querying the database and converting
    //it into a Todo object
      id: data['id'],
      state: data['state'],
      travellocal: data['travellocal'],
      travelabroad: data['travelabroad']
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": id,
    "state": state,
    "travellocal": travellocal,
    "travelabroad": travelabroad
  };
}