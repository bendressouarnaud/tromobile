class Destinataires {
  final String nom;
  final String prenom;
  final String identifiant;
  final String date;
  final String derniermessage;
  final String token;
  final String userid;

  const Destinataires({
    required this.nom,
    required this.prenom,
    required this.identifiant,
    required this.date,
    required this.derniermessage,
    required this.token,
    required this.userid,
  });

  factory Destinataires.fromJson(Map<String, dynamic> json) {
    return Destinataires(
        nom: json['nom'],
        prenom: json['prenom'],
      identifiant: json['identifiant'],
      date: json['date'],
      derniermessage: json['derniermessage'],
        token: json['token'],
        userid: json['userid']
    );
  }
}