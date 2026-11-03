import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'tmdb_logging_interceptor.dart';

Dio createTmdbClient() {
  var token = '';
  try {
    token = dotenv.maybeGet('TMDB_ACCESS_TOKEN')?.trim() ?? '';
  } on Object {
    // Widget tests can build routes without loading an asset-backed .env.
  }

  return Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ),
  )..interceptors.add(TmdbLoggingInterceptor());
}
