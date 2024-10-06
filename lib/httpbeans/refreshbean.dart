class RefreshReserveBean {
  final int idpub;
  final int iduser;
  final int reserve;

  const RefreshReserveBean({
    required this.idpub,
    required this.iduser,
    required this.reserve
  });

  factory RefreshReserveBean.fromJson(Map<String, dynamic> json) {
    return RefreshReserveBean(
        idpub: json['idpub'],
        iduser: json['iduser'],
        reserve: json['reserve']
    );
  }
}