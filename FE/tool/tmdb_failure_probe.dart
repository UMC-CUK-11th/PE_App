// 실제 TMDB 서버에 의도적으로 잘못된 토큰을 보내 401과 마스킹을 확인한다.
// 실행: flutter test tool/tmdb_failure_probe.dart --reporter expanded
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/services/tmdb_client.dart';
import 'package:movielog/services/tmdb_movie_service.dart';

void main() {
  test('실제 TMDB 401 응답과 마스킹 로그 확인', () async {
    final logs = <String>[];
    final client = createTmdbClient(
      token: 'umc-intentionally-invalid-token',
      logWriter: (line) {
        logs.add(line);
        // ignore: avoid_print
        print(line);
      },
    );
    addTearDown(client.close);
    await expectLater(
      TmdbMovieService(client).fetchPopular(),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(logs.join('\n'), contains('ERROR 401'));
    expect(logs.join('\n'), isNot(contains('umc-intentionally-invalid-token')));
  });
}
