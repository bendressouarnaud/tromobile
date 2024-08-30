class Cible {

  // A t t r i b u t e s  :
  final int id;
  final int villedepartid;
  final int paysdepartid;
  final int villedestid;
  final int paysdestid;
  final String topic;

  // M e t h o d s  :
  Cible({required this.id, required this.villedepartid, required this.paysdepartid, required this.villedestid
    , required this.paysdestid, required this.topic});
  factory Cible.fromDatabaseJson(Map<String, dynamic> data) => Cible(
    //This will be used to convert JSON objects that
    //are coming from querying the database and converting
    //it into a Todo object
      id: data['id'],
      villedepartid: data['villedepartid'],
      paysdepartid: data['paysdepartid'],
      villedestid: data['villedestid'],
      paysdestid: data['paysdestid'],
      topic: data['topic']
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": id,
    "villedepartid": villedepartid,
    "paysdepartid": paysdepartid,
    "villedestid": villedestid,
    "paysdestid": paysdestid,
    "topic": topic
  };
}