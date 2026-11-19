import 'package:dio/dio.dart';

import '../models/auth_models.dart';
import '../models/common_response.dart';

class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;

  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v7/auth/login',
      data: request.toJson(),
    );
    return _result(response, LoginResult.fromJson);
  }

  Future<MemberInfo> getMember() async {
    final response = await _dio.get<Map<String, dynamic>>('/v7/members/me');
    return _result(response, MemberInfo.fromJson);
  }

  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v7/members/me',
      data: {'nickname': nickname.trim()},
    );
    return _result(response, MemberInfo.fromJson);
  }

  T _result<T>(
    Response<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) decode,
  ) {
    final body = response.data;
    if (body == null) throw const FormatException('Missing response');
    final parsed = CommonResponse<T>.fromJson(
      body,
      (value) => decode(value as Map<String, dynamic>),
    );
    if (response.statusCode != 200 || parsed.result == null) {
      throw const FormatException('Unexpected response');
    }
    return parsed.result!;
  }
}
