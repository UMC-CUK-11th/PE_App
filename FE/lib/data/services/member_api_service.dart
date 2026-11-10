import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/member_rating.dart';
import '../models/common_response.dart';
import '../models/rating_requests.dart';
import '../models/sign_up_models.dart';
import 'learning_member_session.dart';

class MemberApiService {
  MemberApiService(this._dio, {LearningMemberSession? authSession})
    : _session = authSession;

  factory MemberApiService.fromEnvironment({LearningMemberSession? session}) {
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
      authSession: session,
    );
  }

  final Dio _dio;
  LearningMemberSession? _session;

  void bindSession(LearningMemberSession session) {
    _session = session;
  }

  Options? _authenticatedOptions() {
    final token = _session?.accessToken;
    return token == null || token.isEmpty
        ? null
        : Options(headers: {'Authorization': 'Bearer $token'});
  }

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

  Future<CommonResponse<LoginResult>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    return CommonResponse<LoginResult>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => LoginResult.fromJson(value as Map<String, dynamic>),
    );
  }

  Future<CommonResponse<int>> createRating({
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ratings',
      data: request.toJson(),
      options: _authenticatedOptions(),
    );
    return CommonResponse<int>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => (value as num).toInt(),
    );
  }

  Future<CommonResponse<Object?>> updateRating({
    required int ratingId,
    required UpdateRatingRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/ratings/$ratingId',
      data: request.toJson(),
      options: _authenticatedOptions(),
    );
    return CommonResponse<Object?>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => value,
    );
  }

  Future<void> deleteRating({required int ratingId}) async {
    await _dio.delete<void>(
      '/ratings/$ratingId',
      options: _authenticatedOptions(),
    );
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
