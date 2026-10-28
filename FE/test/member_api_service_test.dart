import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/member_api_service.dart';

void main() {
  test('닉네임과 이메일 available 응답을 읽는다', () async {
    final service = MemberApiService(
      _fakeDio((options) {
        return {'available': options.path.contains('nickname') ? false : true};
      }),
    );

    expect(await service.isNicknameAvailable('수현'), isFalse);
    expect(await service.isEmailAvailable('new@umc.com'), isTrue);
  });

  test('평점 목록을 DTO로 변환한다', () async {
    RequestOptions? capturedRequest;
    final service = MemberApiService(
      _fakeDio((options) {
        capturedRequest = options;
        return [
          {
            'ratingId': 1,
            'movieId': 550,
            'score': 5,
            'comment': '최고의 영화!',
            'createdAt': '2026-10-27T12:00:00',
            'updatedAt': '2026-10-27T12:00:00',
          },
        ];
      }),
    );

    final ratings = await service.fetchRatings(1);

    expect(ratings, hasLength(1));
    expect(ratings.single.movieId, 550);
    expect(ratings.single.score, 5);
    expect(capturedRequest?.path, '/members/1/ratings');
    expect(capturedRequest?.queryParameters, {'page': 0, 'size': 10});
  });
}

Dio _fakeDio(dynamic Function(RequestOptions) responseBuilder) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: responseBuilder(options),
          ),
        );
      },
    ),
  );
  return dio;
}
