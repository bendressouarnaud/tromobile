import 'countrydata.dart';

class CountryDataUnicodeList {
  final bool error;
  final String msg;
  final List<CountryData> data;

  const CountryDataUnicodeList({
    required this.error,
    required this.msg,
    required this.data
  });

  factory CountryDataUnicodeList.fromJson(Map<String, dynamic> json) {
    return CountryDataUnicodeList(
        error: json['error'],
        msg: json['msg'],
        data: List<dynamic>.from(json['data']).map((i) => CountryData.fromJson(i)).toList()
    );
  }
}