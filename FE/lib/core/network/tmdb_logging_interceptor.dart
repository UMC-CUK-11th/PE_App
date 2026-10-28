import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final sanitizedHeaders = Map<String, dynamic>.of(options.headers);
      final authorizationKeys = sanitizedHeaders.keys
          .where((key) => key.toLowerCase() == 'authorization')
          .toList(growable: false);
      for (final key in authorizationKeys) {
        sanitizedHeaders[key] = 'Bearer ***';
      }
      debugPrint(
        '[TMDB] ${options.method} ${options.uri} headers=$sanitizedHeaders',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[TMDB] ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[TMDB] ERROR ${err.requestOptions.uri} '
        'status=${err.response?.statusCode} message=${err.message}',
      );
    }
    handler.next(err);
  }
}
