class ReservationResponse {
  final int id;
  final String nom;
  final String prenom;
  final String adresse;
  final String nationnalite;
  final String channelid;

  const ReservationResponse({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.adresse,
    required this.nationnalite,
    required this.channelid
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
        id: json['id'],
        nom: json['nom'],
        prenom: json['prenom'],
        adresse: json['adresse'],
        nationnalite: json['nationnalite'],
        channelid: json['channelid']
    );
  }
}