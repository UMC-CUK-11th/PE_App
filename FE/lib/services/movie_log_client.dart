import 'package:dio/dio.dart';

import '../view_models/auth_session.dart';

const _workbookHost = 'workbook.devnoco.com';
const _generationKey = 'movieLogSessionGeneration';

void attachMovieLogAuth(Dio dio, AuthSession session) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        if (_requiresAuthentication(request)) {
          final token = session.token;
          if (token == null) {
            handler.reject(
              DioException(requestOptions: request, message: '로그인이 필요한 요청입니다.'),
            );
            return;
          }
          request.headers['Authorization'] = 'Bearer $token';
          request.extra[_generationKey] = session.generation;
          request.followRedirects = false;
        }
        handler.next(request);
      },
      onError: (error, handler) async {
        final response = error.response;
        final body = response?.data;
        final generation = error.requestOptions.extra[_generationKey];
        if (response?.statusCode == 401 &&
            body is Map &&
            const {
              'AUTH401_2',
              'AUTH401_3',
              'AUTH401_4',
            }.contains(body['code']) &&
            generation is int) {
          try {
            await session.expire(generation);
          } catch (_) {
            // Keep the API error available if clearing secure storage fails.
          }
        }
        handler.next(error);
      },
    ),
  );
}

bool _requiresAuthentication(RequestOptions request) {
  final uri = request.uri;
  if (uri.scheme != 'https' || uri.host != _workbookHost || uri.port != 443) {
    return false;
  }
  final method = request.method;
  if (uri.path == '/v7/members/me') return method == 'GET' || method == 'PATCH';
  if (uri.path == '/v7/ratings') return method == 'POST';
  return RegExp(r'^/v7/ratings/[0-9]+$').hasMatch(uri.path) &&
      (method == 'PATCH' || method == 'DELETE');
}

// TMDB 토큰을 이 클라이언트에 넣지 않습니다.
Dio createMovieLogClient() => Dio(
  BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'accept': 'application/json'},
  ),
);
