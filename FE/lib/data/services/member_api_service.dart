import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/member_rating.dart';
import '../models/common_response.dart';
import '../models/rating_requests.dart';
import '../models/sign_up_models.dart';

class MemberApiService {
  MemberApiService(this._dio);

  factory MemberApiService.fromEnvironment() {
    String? baseUrl;
    try {
      baseUrl = dotenv.maybeGet('MOVIE_API_BASE_URL')?.trim();
    } on Object {
      // Widget tests can build routes without loading an asset-backed .env.
    }
    return MemberApiService(
      Dio(
        BaseOptions(
          baseUrl: baseUrl == null || baseUrl.isEmpty
              ? 'http://localhost:8080'
              : baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: const {'accept': 'application/json'},
        ),
      ),
    );
  }

  final Dio _dio;

  Future<bool> isNicknameAvailable(String nickname) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/members/nickname/${Uri.encodeComponent(nickname)}',
    );
    return response.data?['available'] as bool? ?? false;
  }

  Future<bool> isEmailAvailable(String email) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/members/email/${Uri.encodeComponent(email)}',
    );
    return response.data?['available'] as bool? ?? false;
  }

  Future<List<MemberRating>> fetchRatings(
    int memberId, {
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/members/$memberId/ratings',
      queryParameters: {'page': page, 'size': size},
    );
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MemberRating.fromJson)
        .toList(growable: false);
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/members',
      data: request.toJson(),
    );
    return CommonResponse<SignUpResult>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }

  Future<CommonResponse<int>> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/members/$memberId/ratings',
      data: request.toJson(),
    );
    return CommonResponse<int>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => (value as num).toInt(),
    );
  }

  Future<CommonResponse<Object?>> updateRating({
    required int memberId,
    required int ratingId,
    required UpdateRatingRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/members/$memberId/ratings/$ratingId',
      data: request.toJson(),
    );
    return CommonResponse<Object?>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => value,
    );
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    await _dio.delete<void>('/members/$memberId/ratings/$ratingId');
  }
}

String memberApiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    return CommonResponse<Object?>.fromJson(data, (value) => value).message;
  }
  return '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

String? memberApiErrorCode(DioException error) {
  final data = error.response?.data;
  return data is Map<String, dynamic> ? data['code'] as String? : null;
}
