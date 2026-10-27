import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Dio createTmdbClient({String? token, void Function(String)? logWriter}) {
  final accessToken =
      (token ??
              (dotenv.isInitialized
                  ? dotenv.env['TMDB_READ_ACCESS_TOKEN']
                  : '') ??
              '')
          .trim();
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
      queryParameters: {'language': 'ko-KR'},
    ),
  );
  dio.interceptors.add(TmdbLoggingInterceptor(writer: logWriter));
  // 토큰 누락도 화면의 Error 상태로 전달한다.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (accessToken.isEmpty) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: '프로젝트 .env에 TMDB_READ_ACCESS_TOKEN을 입력해 주세요.',
            ),
          );
        } else {
          handler.next(options);
        }
      },
    ),
  );
  return dio;
}

class TmdbLoggingInterceptor extends Interceptor {
  TmdbLoggingInterceptor({
    void Function(String)? writer,
    this.enabled = kDebugMode,
  }) : _writer = writer ?? debugPrint;
  final void Function(String) _writer;
  final bool enabled;

  String _redact(String value, RequestOptions request) {
    var safe = value;
    for (final entry in request.headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        final secret = entry.value.toString().replaceFirst(
          RegExp(r'^Bearer\s+', caseSensitive: false),
          '',
        );
        if (secret.isNotEmpty) safe = safe.replaceAll(secret, '***');
      }
    }
    return safe;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode && enabled) {
      _writer(
        '[TMDB] REQUEST ${options.method} ${options.uri} Authorization: Bearer ***',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode && enabled) {
      _writer(
        '[TMDB] RESPONSE ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && enabled) {
      final message = err.message ?? err.error?.toString() ?? err.type.name;
      _writer(
        _redact(
          '[TMDB] ERROR ${err.response?.statusCode ?? '-'} ${err.requestOptions.uri} $message',
          err.requestOptions,
        ),
      );
    }
    handler.next(err);
  }
}

String tmdbErrorMessage(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 401) {
      return 'TMDB 인증에 실패했습니다. .env의 토큰을 확인해 주세요.';
    }
    if (error.error is String &&
        (error.error as String).startsWith('프로젝트 .env')) {
      return error.error as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return '요청 시간이 초과되었습니다. 다시 시도해 주세요.';
    }
  }
  return '영화를 불러오지 못했습니다. 네트워크 연결을 확인해 주세요.';
}
