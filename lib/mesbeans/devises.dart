class Devises {
  final String libelle;
  final int id;

  const Devises({
    required this.libelle,
    required this.id
  });

  factory Devises.fromJson(Map<String, dynamic> json) {
    return Devises(
        libelle: json['libelle'],
        id: json['id']
    );
  }
}