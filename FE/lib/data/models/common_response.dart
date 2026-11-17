import 'package:dio/dio.dart';

/// v6 공통 응답. 쓰기 API 성공과 모든 v6 오류가 이 형식으로 감싸집니다.
/// result는 API마다 다르므로 제네릭 T로 받고, 없거나 실패면 null입니다.
class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  final bool isSuccess;
  final String code;
  final String message;
  final T? result;

  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }

  /// 오류 응답 body를 공통 형식으로 읽습니다. body가 없거나 형식이 다르면 null입니다.
  static CommonResponse<Object?>? fromError(DioException error) {
    final data = error.response?.data;
    if (data is! Map<String, dynamic>) return null;
    try {
      return CommonResponse<Object?>.fromJson(data, (value) => value);
    } on TypeError {
      return null;
    }
  }
}
