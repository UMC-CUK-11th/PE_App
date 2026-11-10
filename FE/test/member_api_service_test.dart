import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/rating_requests.dart';

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

  test('회원가입 성공 응답에서 memberId를 읽는다', () async {
    RequestOptions? request;
    final service = MemberApiService(
      _fakeDio((options) {
        request = options;
        return {
          'isSuccess': true,
          'code': 'COMMON201',
          'message': '회원가입에 성공했습니다.',
          'result': {
            'memberId': 7,
            'email': 'nova@example.com',
            'nickname': '노바',
          },
        };
      }),
    );

    final response = await service.signUp(
      const CreateMemberRequest(
        email: 'nova@example.com',
        password: 'Password1!',
        nickname: '노바',
      ),
    );

    expect(response.result?.memberId, 7);
    expect(request?.method, 'POST');
    expect(request?.path, '/members');
  });

  test('평점 등록·수정·삭제는 movieId와 ratingId를 구분한다', () async {
    final requests = <RequestOptions>[];
    final service = MemberApiService(
      _fakeDio((options) {
        requests.add(options);
        if (options.method == 'POST') {
          return {
            'isSuccess': true,
            'code': 'COMMON201',
            'message': '등록 성공',
            'result': 31,
          };
        }
        if (options.method == 'PATCH') {
          return {
            'isSuccess': true,
            'code': 'COMMON200',
            'message': '수정 성공',
            'result': null,
          };
        }
        return null;
      }),
    );

    await service.createRating(
      memberId: 7,
      request: const CreateRatingRequest(movieId: 550, score: 5, comment: '최고'),
    );
    await service.updateRating(
      memberId: 7,
      ratingId: 31,
      request: const UpdateRatingRequest(score: 4, comment: ''),
    );
    await service.deleteRating(memberId: 7, ratingId: 31);

    expect(requests[0].path, '/members/7/ratings');
    expect(requests[0].data, containsPair('movieId', 550));
    expect(requests[1].path, '/members/7/ratings/31');
    expect(requests[1].data, containsPair('comment', null));
    expect(requests[2].method, 'DELETE');
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
