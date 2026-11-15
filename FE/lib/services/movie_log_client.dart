import 'package:dio/dio.dart';

// TMDB 토큰을 이 클라이언트에 넣지 않습니다.
Dio createMovieLogClient() => Dio(
  BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'accept': 'application/json'},
  ),
);
