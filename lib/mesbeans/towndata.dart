class TownData {
  final String name, countryiso3;

  const TownData({
    required this.name,
    required this.countryiso3
  });

  factory TownData.fromJson(Map<String, dynamic> json) {
    return TownData(
        name: json['name'],
        countryiso3: json['countryiso3']
    );
  }
}