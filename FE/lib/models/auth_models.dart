class LoginRequest {
  const LoginRequest(this.email, this.password);

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

class LoginResult {
  const LoginResult(this.nickname, this.accessToken);

  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] as String;
    if (token.trim().isEmpty) throw const FormatException('Empty access token');
    return LoginResult(json['nickname'] as String, token);
  }
}

class MemberInfo {
  const MemberInfo(this.email, this.nickname, this.createdAt);

  final String email;
  final String nickname;
  final DateTime createdAt;

  factory MemberInfo.fromJson(Map<String, dynamic> json) => MemberInfo(
    json['email'] as String,
    json['nickname'] as String,
    DateTime.parse(json['createdAt'] as String),
  );
}
