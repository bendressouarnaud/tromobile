class CountryData {
  final String name, iso2, iso3, unicodeFlag;

  const CountryData({
    required this.name,
    required this.iso2,
    required this.iso3,
    required this.unicodeFlag
  });

  factory CountryData.fromJson(Map<String, dynamic> json) {
    return CountryData(
        name: json['name'],
        iso2: json['iso2'],
        iso3: json['iso3'],
        unicodeFlag: json['unicodeFlag']
    );
  }
}