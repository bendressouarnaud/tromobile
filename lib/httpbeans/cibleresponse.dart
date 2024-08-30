class CibleResponse {
  final int idcible;
  final String champ;

  const CibleResponse({
    required this.idcible,
    required this.champ
  });

  factory CibleResponse.fromJson(Map<String, dynamic> json) {
    return CibleResponse(
        idcible: json['idcible'],
        champ: json['champ']
    );
  }
}