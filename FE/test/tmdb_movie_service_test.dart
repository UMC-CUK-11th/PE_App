import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

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

  test('Discover는 중복 결과가 계속되어도 5페이지에서 요청을 멈춘다', () async {
    var callCount = 0;
    final dio = _fakeDio((options) {
      callCount++;
      return {
        'page': options.queryParameters['page'],
        'total_pages': 100,
        'results': [_movieJson(1)],
      };
    });

    final movies = await TmdbMovieService(dio).fetchDiscover();

    expect(movies, hasLength(1));
    expect(callCount, 5);
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

  test('빈 poster_path는 포스터 URL을 만들지 않는다', () async {
    final dto = TmdbMovieDto.fromJson(_movieJson(1, posterPath: '   '));

    expect(dto.toMovie(const {}).posterUrl, isNull);
  });

  test('유효한 poster_path는 TMDB 이미지 URL로 변환한다', () async {
    final dto = TmdbMovieDto.fromJson(_movieJson(1));

    expect(
      dto.toMovie(const {}).posterUrl,
      'https://image.tmdb.org/t/p/w500/poster.jpg',
    );
  });

  test('DTO 타입 캐스트 오류를 사용자용 TMDB 예외로 변환한다', () async {
    final dio = _fakeDio((options) {
      return {
        'page': 1,
        'total_pages': 1,
        'results': [
          {..._movieJson(1), 'id': '잘못된 ID'},
        ],
      };
    });

    expect(
      () => TmdbMovieService(dio).fetchPopular(),
      throwsA(
        isA<TmdbApiException>().having(
          (error) => error.message,
          'message',
          contains('응답 형식이 올바르지 않습니다'),
        ),
      ),
    );
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
