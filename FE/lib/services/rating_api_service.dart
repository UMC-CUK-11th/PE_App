import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/common_response.dart';
import '../models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get(_path(memberId));
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String _path(int memberId) => '/v6/members/$memberId/ratings';

  Future<void> create(int memberId, CreateRatingRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path(memberId),
      data: request.toJson(),
    );
    _confirmWrite(response, 201);
  }

  Future<void> update(
    int memberId,
    int ratingId,
    UpdateRatingRequest request,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${_path(memberId)}/$ratingId',
      data: request.toJson(),
    );
    _confirmWrite(response, 200);
  }

  Future<void> delete(int memberId, int ratingId) async {
    final response = await _dio.delete<void>('${_path(memberId)}/$ratingId');
    if (response.statusCode != 204) {
      throw const FormatException('Expected 204 for deletion');
    }
  }

  void _confirmWrite(Response<Map<String, dynamic>> response, int status) {
    final body = response.data;
    if (body == null) throw const FormatException('Missing write response');
    CommonResponse<Object>.fromJson(body, (value) => value);
    if (response.statusCode != status) {
      throw const FormatException('Unexpected write status');
    }
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  if (error.response?.data is Map) {
    return ApiFailure.from(error, '평점을 불러오지 못했습니다.').message;
  }
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
