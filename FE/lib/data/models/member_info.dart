import 'common_response.dart';

/// GET·PATCH /v7/members/me result. memberId와 password는 담기지 않습니다.
class MemberInfo {
  const MemberInfo({
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  final String email;
  final String nickname;
  final DateTime createdAt;

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

MemberInfo parseMemberInfo(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('내 정보 응답 형식이 올바르지 않습니다.');
  }
  final member = CommonResponse<MemberInfo>.fromJson(
    data,
    (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
  ).result;
  if (member == null) throw StateError('내 정보 result가 없습니다.');
  return member;
}
