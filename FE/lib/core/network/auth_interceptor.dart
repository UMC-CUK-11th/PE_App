import 'package:dio/dio.dart';

import '../../data/services/learning_member_session.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session);

  final LearningMemberSession _session;

  static bool isProtectedPath(String path) {
    return path.startsWith('/v7/members/me') || path.startsWith('/v7/ratings');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.accessToken;
    if (token != null && token.isNotEmpty && isProtectedPath(options.path)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
