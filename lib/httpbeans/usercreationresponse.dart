class UserCreationResponse {
  final int userid;
  final int cibleid;
  final String typepiece;

  const UserCreationResponse({
    required this.userid,
    required this.typepiece,
    required this.cibleid
  });

  factory UserCreationResponse.fromJson(Map<String, dynamic> json) {
    return UserCreationResponse(
        userid: json['userid'],
        typepiece: json['typepiece'],
        cibleid: json['cibleid']
    );
  }
}