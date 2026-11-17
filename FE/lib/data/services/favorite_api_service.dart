import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_models.dart';

/// 즐겨찾기(/v8/favorites). 보호 Client로 보내 JWT로 회원을 식별합니다.
class FavoriteApiService {
  FavoriteApiService(this._dio);

  final Dio _dio;

  /// 201, result에 FavoriteResponseDto.
  Future<FavoriteResponseDto> addFavorite(int movieId) async {
    final response = await _dio.post(
      '/v8/favorites',
      data: {'movieId': movieId},
    );
    final result = CommonResponse<FavoriteResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      FavoriteResponseDto.fromJson,
    ).result;
    if (result == null) throw StateError('즐겨찾기 result가 없습니다.');
    return result;
  }

  /// 200, result가 배열이고 없으면 [].
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get('/v8/favorites');
    return CommonResponse<List<FavoriteResponseDto>>.fromJson(
          response.data as Map<String, dynamic>,
          (value) => (value as List<dynamic>)
              .map(FavoriteResponseDto.fromJson)
              .toList(),
        ).result ??
        const [];
  }

  /// 200, result { isFavorite }. 응답에 movieId가 없어 bool만 돌려줍니다.
  Future<bool> checkFavorite(int movieId) async {
    final response = await _dio.get('/v8/favorites/$movieId');
    final result = (response.data as Map<String, dynamic>)['result'];
    if (result is! Map<String, dynamic> || result['isFavorite'] is! bool) {
      throw const FormatException('isFavorite must be a boolean.');
    }
    return result['isFavorite'] as bool;
  }

  /// 200 + result null. 평점 삭제(204)와 달리 body를 파싱하지 않고 예외가 없으면 성공입니다.
  Future<void> deleteFavorite(int movieId) async {
    await _dio.delete('/v8/favorites/$movieId');
  }
}
