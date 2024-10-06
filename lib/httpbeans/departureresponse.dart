import 'package:tro/httpbeans/refreshbean.dart';

class DepartureResponse {
  final int id;
  final String date;
  final String identifiant;
  final List<RefreshReserveBean> reserveBean;

  const DepartureResponse({
    required this.id,
    required this.date,
    required this.identifiant,
    required this.reserveBean,
  });

  factory DepartureResponse.fromJson(Map<String, dynamic> json) {
    return DepartureResponse(
        id: json['id'],
        date: json['date'],
        identifiant: json['identifiant'],
        reserveBean: List<dynamic>.from(json['reserveBean']).map((i) => RefreshReserveBean.fromJson(i)).toList()
    );
  }
}