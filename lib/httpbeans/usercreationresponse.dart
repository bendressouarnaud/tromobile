class UserCreationResponse {
  final int userid;
  final int cibleid;
  final String typepiece;
  final String codeparrainage;
  final String streamchatoken;

  const UserCreationResponse({
    required this.userid,
    required this.typepiece,
    required this.cibleid,
    required this.codeparrainage,
    required this.streamchatoken
  });

  factory UserCreationResponse.fromJson(Map<String, dynamic> json) {
    return UserCreationResponse(
        userid: json['userid'],
        typepiece: json['typepiece'],
        cibleid: json['cibleid'],
        codeparrainage: json['codeparrainage'],
        streamchatoken: json['streamchatoken']
    );
  }
}