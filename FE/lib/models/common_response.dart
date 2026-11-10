import 'package:dio/dio.dart';

class CommonResponse<T> {
  const CommonResponse(this.code, this.message, this.result);
  final String code, message;
  final T? result;

  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object) decode,
  ) {
    if (json['isSuccess'] != true) throw ApiFailure.fromJson(json);
    final result = json['result'];
    return CommonResponse(
      json['code'] as String,
      json['message'] as String,
      result == null ? null : decode(result),
    );
  }
}

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.code, this.status});
  final String message;
  final String? code;
  final int? status;

  factory ApiFailure.fromJson(Map json, {int? status}) => ApiFailure(
    json['message'] is String && (json['message'] as String).trim().isNotEmpty
        ? json['message'] as String
        : '요청을 처리하지 못했습니다.',
    code: json['code'] is String ? json['code'] as String : null,
    status: status,
  );

  bool matches(int value) => status == value || code == 'COMMON$value';

  static ApiFailure from(Object error, String fallback) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;
      return data is Map
          ? ApiFailure.fromJson(data, status: response?.statusCode)
          : ApiFailure(fallback, status: response?.statusCode);
    }
    return ApiFailure(fallback);
  }
}
