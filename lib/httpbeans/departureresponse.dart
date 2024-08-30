class DepartureResponse {
  final int id;
  final String date;
  final String identifiant;

  const DepartureResponse({
    required this.id,
    required this.date,
    required this.identifiant
  });

  factory DepartureResponse.fromJson(Map<String, dynamic> json) {
    return DepartureResponse(
        id: json['id'],
        date: json['date'],
        identifiant: json['identifiant']
    );
  }
}