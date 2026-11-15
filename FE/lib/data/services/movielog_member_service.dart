import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

/// MovieLog 백엔드의 회원·평점 API를 호출하고 DTO로 변환합니다.
class MovieLogMemberService {
  MovieLogMemberService(this._dio);

  final Dio _dio;

  Future<bool> isNicknameAvailable(String nickname) =>
      _available('/members/nickname/${Uri.encodeComponent(nickname)}');

  Future<bool> isEmailAvailable(String email) =>
      _available('/members/email/${Uri.encodeComponent(email)}');

  Future<List<RatingDto>> fetchRatings(int memberId) async {
    final response = await _dio.get('/members/$memberId/ratings');
    return (response.data as List<dynamic>)
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> _available(String path) async {
    final response = await _dio.get(path);
    return (response.data as Map<String, dynamic>)['available'] as bool;
  }
}
