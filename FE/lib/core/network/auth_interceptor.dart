import 'package:dio/dio.dart';

import '../../data/services/learning_member_session.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session, {this.onSessionExpired});

  final LearningMemberSession _session;
  void Function()? onSessionExpired;

  static bool isProtectedPath(String path) {
    return path.startsWith('/v8/members/me') ||
        path.startsWith('/v8/ratings') ||
        path.startsWith('/v8/favorites') ||
        path.startsWith('/v8/movie-records');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.accessToken;
    if (token != null && token.isNotEmpty && isProtectedPath(options.path)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    final code = data is Map<String, dynamic> ? data['code'] as String? : null;
    final isExpired =
        code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
    final requestToken = _bearerToken(err.requestOptions.headers);
    final currentToken = _session.accessToken;
    if (err.response?.statusCode == 401 &&
        isExpired &&
        isProtectedPath(err.requestOptions.path) &&
        requestToken != null &&
        requestToken == currentToken) {
      onSessionExpired?.call();
    }
    handler.next(err);
  }

  String? _bearerToken(Map<String, dynamic> headers) {
    Object? authorization;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        authorization = entry.value;
        break;
      }
    }
    if (authorization is! String || !authorization.startsWith('Bearer ')) {
      return null;
    }
    final token = authorization.substring('Bearer '.length).trim();
    return token.isEmpty ? null : token;
  }
}
