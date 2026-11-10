class CreateMemberRequest {
  const CreateMemberRequest(this.email, this.nickname, this.password);
  final String email, nickname, password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'nickname': nickname.trim(),
    'password': password,
  };
}

class SignUpResult {
  const SignUpResult(this.memberId);
  final int memberId;

  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    final id = json['memberId'];
    if (id is! int || id <= 0) throw const FormatException('Invalid memberId');
    return SignUpResult(id);
  }
}
