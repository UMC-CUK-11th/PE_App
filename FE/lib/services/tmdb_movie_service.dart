import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_dto.dart';
import 'movie_catalog_service.dart';
import 'tmdb_logging_interceptor.dart';

class TmdbApiException implements Exception {
  const TmdbApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TmdbMovieService implements MovieCatalogService {
  TmdbMovieService(this._dio);

  factory TmdbMovieService.fromEnvironment() {
    var token = '';
    try {
      token = dotenv.maybeGet('TMDB_ACCESS_TOKEN')?.trim() ?? '';
    } on Object {
      // Widget tests can build routes without loading an asset-backed .env.
    }
    final dio = Dio(
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
    return TmdbMovieService(dio);
  }

  final Dio _dio;

  @override
  Future<List<TmdbMovieDto>> fetchPopular() async {
    final page = await _fetchMoviePage('/movie/popular', page: 1);
    return page.results.take(5).toList(growable: false);
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/genre/movie/list',
        queryParameters: const {'language': 'ko-KR'},
      );
      final genres = response.data?['genres'] as List<dynamic>? ?? const [];
      return genres
          .whereType<Map<String, dynamic>>()
          .map(TmdbGenreDto.fromJson)
          .where((genre) => genre.name.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _convertError(error);
    }
  }

  @override
  Future<List<TmdbMovieDto>> fetchDiscover({List<int>? genreIds}) async {
    final uniqueMovies = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var totalPages = 1;

    do {
      final page = await _fetchMoviePage(
        '/discover/movie',
        page: pageNumber,
        genreIds: genreIds,
      );
      totalPages = page.totalPages;
      for (final movie in page.results) {
        uniqueMovies.putIfAbsent(movie.id, () => movie);
        if (uniqueMovies.length == 30) break;
      }
      pageNumber++;
    } while (uniqueMovies.length < 30 && pageNumber <= totalPages);

    return uniqueMovies.values.take(30).toList(growable: false);
  }

  Future<TmdbMoviePageDto> _fetchMoviePage(
    String path, {
    required int page,
    List<int>? genreIds,
  }) async {
    try {
      final withGenres = genreIds == null || genreIds.isEmpty
          ? null
          : genreIds.join('|');
      final queryParameters = <String, dynamic>{
        'language': 'ko-KR',
        'page': page,
        if (path == '/discover/movie') 'include_adult': false,
      };
      if (withGenres != null) queryParameters['with_genres'] = withGenres;
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return TmdbMoviePageDto.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw _convertError(error);
    } on FormatException catch (error) {
      throw TmdbApiException('TMDB 응답 형식이 올바르지 않습니다: $error');
    }
  }

  TmdbApiException _convertError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = switch (statusCode) {
      401 => 'TMDB 인증에 실패했습니다. .env의 토큰을 확인해 주세요.',
      _ when statusCode != null => 'TMDB 요청에 실패했습니다. (HTTP $statusCode)',
      _ => '네트워크 연결을 확인한 뒤 다시 시도해 주세요.',
    };
    return TmdbApiException(message, statusCode: statusCode);
  }
}
