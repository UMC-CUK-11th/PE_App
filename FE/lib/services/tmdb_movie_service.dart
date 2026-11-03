import 'package:dio/dio.dart';

import '../models/tmdb_movie_dto.dart';

class TmdbMovieService {
  TmdbMovieService(this.client);
  final Dio client;
  List<TmdbGenreDto>? _genres;

  Future<TmdbMoviePageDto> fetchPopular({CancelToken? cancelToken}) async {
    final response = await client.get<Map<String, dynamic>>(
      '/movie/popular',
      queryParameters: {'page': 1},
      cancelToken: cancelToken,
    );
    return TmdbMoviePageDto.fromJson(response.data!);
  }

  Future<List<TmdbGenreDto>> fetchGenres({CancelToken? cancelToken}) async {
    if (_genres != null) return _genres!;
    final response = await client.get<Map<String, dynamic>>(
      '/genre/movie/list',
      cancelToken: cancelToken,
    );
    final result = (response.data!['genres'] as List)
        .map((g) => TmdbGenreDto.fromJson(Map<String, dynamic>.from(g as Map)))
        .toList();
    _genres = List.unmodifiable(result);
    return _genres!;
  }

  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
    CancelToken? cancelToken,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/discover/movie',
      queryParameters: {
        'page': page,
        'include_adult': false,
        'sort_by': 'popularity.desc',
        if (genreIds != null && genreIds.isNotEmpty)
          'with_genres': genreIds.join('|'),
      },
      cancelToken: cancelToken,
    );
    return TmdbMoviePageDto.fromJson(response.data!);
  }

  Future<TmdbMovieDto> fetchDetail(int id, {CancelToken? cancelToken}) async {
    final response = await client.get<Map<String, dynamic>>(
      '/movie/$id',
      cancelToken: cancelToken,
    );
    return TmdbMovieDto.fromJson(response.data!);
  }
}
