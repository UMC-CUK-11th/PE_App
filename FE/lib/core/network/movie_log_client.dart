import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// 워크북 자체 백엔드 주소. 로컬 백엔드는 .env의 MOVIELOG_API_BASE_URL로 바꿉니다.
String movieLogBaseUrl() {
  final override = dotenv.isInitialized
      ? dotenv.env['MOVIELOG_API_BASE_URL'] ?? ''
      : '';
  return override.isEmpty ? 'https://workbook.devnoco.com' : override;
}

Dio _createClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: movieLogBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  if (kDebugMode) {
    // 요청 body(비밀번호)와 Header(JWT)는 로그에 남기지 않습니다.
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        logPrint: (log) => debugPrint('[MovieLog API] $log'),
      ),
    );
  }
  return dio;
}

/// 공개 요청용: 로그인·회원가입·중복 확인·유저별 평점 조회. Interceptor가 없어 토큰이 붙지 않습니다.
/// TMDB Client와는 baseUrl·헤더가 달라 절대 합치지 않습니다.
Dio createMovieLogClient() => _createClient();

/// 보호 요청용: 내 정보·평점 등록/수정/삭제. AuthInterceptor가 Bearer를 붙입니다.
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = _createClient();
  dio.interceptors.insert(
    0,
    AuthInterceptor(storage, host: Uri.parse(movieLogBaseUrl()).host),
  );
  return dio;
}
