import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/services/tmdb_movie_service.dart';

void main() {
  test('Popular 응답이 5개보다 적어도 범위 오류 없이 모두 반환한다', () async {
    final dio = _fakeDio((options) {
      return {
        'page': 1,
        'total_pages': 1,
        'results': [
          _movieJson(1),
          _movieJson(2, posterPath: null),
          _movieJson(3),
        ],
      };
    });

    final movies = await TmdbMovieService(dio).fetchPopular();

    expect(movies.map((movie) => movie.id), [1, 2, 3]);
    expect(movies[1].posterPath, isNull);
  });

  test('Discover는 OR 장르 조건을 유지하고 ID 중복 없이 최대 30개를 만든다', () async {
    final requestedPages = <int>[];
    final requestedGenres = <String?>[];
    final dio = _fakeDio((options) {
      requestedPages.add(options.queryParameters['page'] as int);
      requestedGenres.add(options.queryParameters['with_genres'] as String?);
      final page = options.queryParameters['page'] as int;
      return {
        'page': page,
        'total_pages': 2,
        'results': page == 1
            ? [for (var id = 1; id <= 20; id++) _movieJson(id)]
            : [for (var id = 20; id <= 40; id++) _movieJson(id)],
      };
    });

    final movies = await TmdbMovieService(dio)
        .fetchDiscover(genreIds: [12, 16]);

    expect(movies, hasLength(30));
    expect(movies.map((movie) => movie.id).toSet(), hasLength(30));
    expect(requestedPages, [1, 2]);
    expect(requestedGenres, ['12|16', '12|16']);
  });

  test('Genre 응답의 id와 name을 변환한다', () async {
    final dio = _fakeDio((options) {
      return {
        'genres': [
          {'id': 28, 'name': '액션'},
          {'id': 35, 'name': '코미디'},
        ],
      };
    });

    final genres = await TmdbMovieService(dio).fetchGenres();

    expect(genres.map((genre) => genre.id), [28, 35]);
    expect(genres.map((genre) => genre.name), ['액션', '코미디']);
  });
}

Dio _fakeDio(Map<String, dynamic> Function(RequestOptions) responseBuilder) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: responseBuilder(options),
          ),
        );
      },
    ),
  );
  return dio;
}

Map<String, dynamic> _movieJson(int id, {String? posterPath = '/poster.jpg'}) {
  return {
    'id': id,
    'title': '영화 $id',
    'genre_ids': [28],
    'vote_average': 8,
    'overview': '줄거리',
    'poster_path': posterPath,
    'release_date': '2026-01-01',
  };
}
