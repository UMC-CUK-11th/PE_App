import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// MovieLog 자체 백엔드 Client. TMDB Client와 인증·주소가 달라 따로 둡니다.
Dio createMovieLogClient() {
  final baseUrl = dotenv.env['MOVIELOG_API_BASE_URL'] ?? '';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.isEmpty ? 'http://localhost:8080' : baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
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
