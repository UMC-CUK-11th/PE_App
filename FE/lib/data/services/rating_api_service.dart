import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final rating = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  ).result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

/// 평점(v7). 조회는 공개 Client, 등록·수정·삭제는 보호 Client로 보냅니다.
/// 보호 요청에는 memberId가 없고 Authorization 헤더로 회원을 식별합니다.
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  /// 공개 유저별 조회: 200 + 직접 배열, 토큰 없음.
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    final data = response.data;
    if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
    return data
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 201 + 공통 형식(result: Rating 객체).
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// PATCH지만 전체 교체입니다. comment를 빼면 기존 후기가 null로 덮이므로 항상 보냅니다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  /// v6의 204와 달리 200 + result null입니다.
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 쓰기 실패 문구. 서버 message가 있으면 그대로 씁니다.
String writeErrorMessage(DioException error) {
  return apiErrorMessage(error) ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
