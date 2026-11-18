import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// 보호용 MovieLog Client에만 등록합니다. 워크북 서버의 보호 path에만 Bearer를 붙이고,
/// TMDB·외부 이미지 등 다른 host에는 절대 MovieLog JWT를 보내지 않습니다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {required this.host});

  final TokenStorage _storage;

  /// MovieLog API host. 이 host의 보호 path에만 토큰을 붙입니다.
  final String host;

  bool isProtected(Uri uri) {
    final path = uri.path;
    return uri.host == host &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 이전 요청의 토큰을 재사용하지 않습니다.
    options.headers.remove('Authorization');
    if (!isProtected(options.uri)) {
      handler.next(options);
      return;
    }
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 서버 401과 기기 저장소 실패는 다른 오류입니다.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
