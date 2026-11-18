import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/login_models.dart';

/// 로그인(v7). 공개 Client를 사용합니다.
class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;

  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post('/v7/auth/login', data: request.toJson());
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('로그인 응답 형식이 올바르지 않습니다.');
    }
    final result = CommonResponse<LoginResult>.fromJson(
      data,
      (value) => LoginResult.fromJson(value as Map<String, dynamic>),
    ).result;
    if (result == null) throw StateError('로그인 result가 없습니다.');
    return result;
  }
}
