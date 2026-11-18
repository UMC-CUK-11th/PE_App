/// POST /v6/members 요청 body. 비밀번호는 로그·저장소에 남기지 않습니다.
class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;
  final String password;
  final String nickname;

  /// 이메일·닉네임은 앞뒤 공백만 정리하고, 비밀번호는 한 글자도 바꾸지 않습니다.
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };
}
