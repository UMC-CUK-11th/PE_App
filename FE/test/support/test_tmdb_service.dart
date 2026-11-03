import 'package:dio/dio.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/models/tmdb_movie_dto.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/services/movie_list_preferences.dart';

class TestTmdbService extends TmdbMovieService {
  TestTmdbService() : super(Dio());
  static const genreMap = {
    '드라마': 18,
    'SF': 878,
    '애니메이션': 16,
    '스릴러': 53,
    '로맨스': 10749,
    '다큐멘터리': 99,
    '액션': 28,
  };
  int calls = 0;
  int popularCalls = 0;
  bool fail = false;
  bool empty = false;
  Duration delay = Duration.zero;
  final requestedPages = <int>[];
  final requestedGenres = <List<int>?>[];

  List<TmdbMovieDto> get fixtures => mockMovies
      .map(
        (movie) => TmdbMovieDto(
          id: movie.id,
          title: movie.title,
          genreIds: movie.genres.map((g) => genreMap[g]!).toList(),
          overview: movie.synopsis,
          releaseDate: '${movie.year}-01-01',
          voteAverage: movie.rating * 2,
          runtime: movie.durationMinutes,
        ),
      )
      .toList();

  @override
  Future<List<TmdbGenreDto>> fetchGenres({CancelToken? cancelToken}) async =>
      genreMap.entries
          .map((g) => TmdbGenreDto(id: g.value, name: g.key))
          .toList();

  @override
  Future<TmdbMoviePageDto> fetchPopular({CancelToken? cancelToken}) async {
    popularCalls++;
    return TmdbMoviePageDto(
      page: 1,
      totalPages: 1,
      results: empty ? [] : fixtures,
    );
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
    CancelToken? cancelToken,
  }) async {
    calls++;
    requestedPages.add(page);
    requestedGenres.add(genreIds);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (fail) throw Exception('controlled request failure');
    return TmdbMoviePageDto(
      page: page,
      totalPages: 1,
      results: empty
          ? []
          : fixtures
                .where(
                  (m) =>
                      genreIds == null ||
                      genreIds.isEmpty ||
                      m.genreIds.any(genreIds.contains),
                )
                .toList(),
    );
  }

  @override
  Future<TmdbMovieDto> fetchDetail(int id, {CancelToken? cancelToken}) async =>
      fixtures.firstWhere((m) => m.id == id);
}

class MemoryMovieListPreferences implements MovieListPreferences {
  Set<String> genres = {};
  MovieSortOption sortOption = MovieSortOption.latest;
  @override
  Future<MovieListPreferencesData> read() async =>
      MovieListPreferencesData(genres: genres, sortOption: sortOption);
  @override
  Future<void> saveGenres(Set<String> value) async {
    genres = value;
  }

  @override
  Future<void> saveSortOption(MovieSortOption value) async {
    sortOption = value;
  }
}
