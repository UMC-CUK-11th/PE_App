import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 회원별 평점 CRUD(v6). 조회는 직접 배열, 등록·수정은 공통 형식, 삭제는 204 본문 없음.
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 200 + 직접 배열. 빈 배열은 실패가 아니라 Empty입니다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    return (response.data as List<dynamic>)
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 201 + 공통 형식(result: ratingId). 성공 뒤 목록은 GET으로 다시 읽습니다.
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// PATCH지만 전체 교체입니다. comment를 빼면 기존 후기가 null로 덮이므로 항상 보냅니다.
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
  }

  /// 204는 body가 없으므로 response.data를 파싱하지 않습니다.
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 조회 실패 문구. v6 오류는 공통 형식이라 서버 message를 우선 씁니다.
String writeMyRatingsErrorMessage(DioException error) {
  final message = CommonResponse.fromError(error)?.message;
  if (message != null) return message;
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 쓰기 실패 문구. 같은 COMMON404라도 등록은 "유저", 수정·삭제는 "평점"이라 서버 message를 그대로 씁니다.
String writeErrorMessage(DioException error) {
  return CommonResponse.fromError(error)?.message ??
      '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 403·404는 화면 목록이 서버와 어긋났다는 뜻이라 다시 조회합니다. 400·409는 값만 고치면 됩니다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = CommonResponse.fromError(error)?.code;
  return code == 'COMMON403' || code == 'COMMON404';
}
