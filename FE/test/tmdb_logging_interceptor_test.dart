import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/tmdb_logging_interceptor.dart';

void main() {
  test('TMDB 요청 로그에서 Authorization 원문을 마스킹한다', () async {
    const secret = 'do-not-print-this-token';
    final messages = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = originalDebugPrint);

    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.themoviedb.org/3',
        headers: const {'authorization': 'Bearer $secret'},
      ),
    );
    dio.interceptors.addAll([
      TmdbLoggingInterceptor(),
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: const {'results': []},
          ),
        ),
      ),
    ]);

    await dio.get<Map<String, dynamic>>('/movie/popular');

    expect(messages.join('\n'), contains('Bearer ***'));
    expect(messages.join('\n'), isNot(contains(secret)));
  });
}
