import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/member_rating.dart';

class MemberApiService {
  MemberApiService(this._dio);

  factory MemberApiService.fromEnvironment() {
    final baseUrl = dotenv.env['MOVIE_API_BASE_URL']?.trim();
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
}
