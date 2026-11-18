import 'package:dio/dio.dart';

/// 오류 응답 body의 code. body가 공통 형식이 아니면 null입니다.
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 오류 응답 body의 message. 사용자에게 바로 보여줄 수 있는 문장입니다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청에서 토큰이 없거나(2)·무효거나(3)·만료된(4) 경우입니다.
/// 로그인 실패 AUTH401_1은 Form 오류라 여기에 넣지 않습니다.
bool isSessionExpiredError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}
