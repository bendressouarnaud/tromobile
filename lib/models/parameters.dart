class Parameters {

  // A t t r i b u t e s  :
  final int id;
  final String state;
  final int travellocal;
  final int travelabroad;
  final int notification;
  final int epochdebut;
  final int epochfin;
  final int comptevalide;
  final int deviceregistered;
  final int privacypolicy;

  // M e t h o d s  :
  Parameters({required this.id, required this.state, required this.travellocal, required this.travelabroad
  , required this.notification, required this.epochdebut, required this.epochfin, required this.comptevalide
    , required this.deviceregistered, required this.privacypolicy});
  factory Parameters.fromDatabaseJson(Map<String, dynamic> data) => Parameters(
    //This will be used to convert JSON objects that
    //are coming from querying the database and converting
    //it into a Todo object
      id: data['id'],
      state: data['state'],
      travellocal: data['travellocal'],
      travelabroad: data['travelabroad'],
      notification: data['notification'],
      epochdebut: data['epochdebut'],
      epochfin: data['epochfin'],
      comptevalide: data['comptevalide'],
      deviceregistered: data['deviceregistered'],
      privacypolicy: data['privacypolicy']
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": id,
    "state": state,
    "travellocal": travellocal,
    "travelabroad": travelabroad,
    "notification": notification,
    "epochdebut": epochdebut,
    "epochfin": epochfin,
    "comptevalide": comptevalide,
    "deviceregistered": deviceregistered,
    "privacypolicy": privacypolicy
  };
}