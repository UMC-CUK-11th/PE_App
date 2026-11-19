import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/member_models.dart';

class SignUpService {
  SignUpService(this._dio, {String version = 'v6'})
    : _members = '/$version/members';
  final Dio _dio;
  final String _members;

  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('$_members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('$_members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _members,
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw const FormatException('Expected 201 for signup');
    }
    return CommonResponse.fromJson(
      response.data!,
      (data) => SignUpResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
