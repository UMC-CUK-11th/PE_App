import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 워크북 자체 백엔드 Client. TMDB Client와 baseUrl·헤더가 달라 절대 합치지 않습니다.
/// 로컬 백엔드로 바꿔 볼 때는 .env의 MOVIELOG_API_BASE_URL을 지정합니다.
Dio createMovieLogClient() {
  final override = dotenv.isInitialized
      ? dotenv.env['MOVIELOG_API_BASE_URL'] ?? ''
      : '';

  final dio = Dio(
    BaseOptions(
      baseUrl: override.isEmpty ? 'https://workbook.devnoco.com' : override,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        logPrint: (log) => debugPrint('[MovieLog API] $log'),
      ),
    );
  }

  return dio;
}
