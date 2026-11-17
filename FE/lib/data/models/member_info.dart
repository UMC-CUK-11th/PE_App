import 'common_response.dart';

class MemberInfo {
  const MemberInfo({
    required this.email,
    required this.nickname,
    required this.createdAt,
    this.memberId,
  });

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      memberId: (json['memberId'] as num?)?.toInt(),
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int? memberId;
  final String email;
  final String nickname;
  final DateTime createdAt;

  MemberInfo copyWith({String? nickname}) {
    return MemberInfo(
      memberId: memberId,
      email: email,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt,
    );
  }
}

MemberInfo parseMemberInfo(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw const FormatException('내 정보 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<MemberInfo>.fromJson(
    data,
    (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
  );
  final member = common.result;
  if (member == null) {
    throw const FormatException('내 정보 result가 없습니다.');
  }
  return member;
}
