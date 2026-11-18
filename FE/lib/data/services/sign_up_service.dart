import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// 회원가입·중복 확인(v8 공개 API). 토큰이 필요 없어 공개 Client를 씁니다.
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// 성공한 중복 확인은 공통 형식 없이 { "available": bool }이 그대로 옵니다.
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v8/members/nickname/$encoded');
    return CheckResult.fromJson(
      response.data as Map<String, dynamic>,
    ).available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v8/members/email/$encoded');
    return CheckResult.fromJson(
      response.data as Map<String, dynamic>,
    ).available;
  }

  /// 201 + `CommonResponse<SignUpResult>`. 400·409는 DioException으로 옵니다.
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v8/members', data: request.toJson());
    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 가입 400·409의 message는 이미 사용자에게 보여줄 문장이라 그대로 씁니다.
String writeSignUpErrorMessage(DioException error) {
  return CommonResponse.fromError(error)?.message ??
      '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
