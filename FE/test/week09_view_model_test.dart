import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/movie_catalog_service.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/movie_search_view_model.dart';

void main() {
  test('다음 페이지 실패 후 같은 페이지를 다시 요청하고 중복 ID를 제거한다', () async {
    final service = _PagedCatalog()..failPageOnce = 2;
    final viewModel = MovieListViewModel(service);

    await viewModel.loadInitial();
    await viewModel.loadMore();
    expect(viewModel.loadMoreError, isNotNull);

    await viewModel.loadMore();
    expect(service.discoverPages, [1, 2, 2]);
    expect(viewModel.movies.map((movie) => movie.id), [1, 2]);
  });

  test('늦게 끝난 이전 검색 결과는 최신 검색을 덮어쓰지 않는다', () async {
    final service = _PagedCatalog();
    final viewModel = MovieSearchViewModel(service);

    final first = viewModel.search('이전');
    final second = viewModel.search('최신');
    service.completeSearch('최신', 20);
    await second;
    service.completeSearch('이전', 10);
    await first;

    expect(viewModel.query, '최신');
    expect(viewModel.movies.single.id, 20);
  });

  test('즐겨찾기 영화 하나의 TMDB 실패가 전체 목록을 비우지 않는다', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': true,
              'code': 'COMMON200',
              'message': '성공',
              'result': [
                {'favoriteId': 1, 'movieId': 1},
                {'favoriteId': 2, 'movieId': 999},
              ],
            },
          ),
        ),
      ),
    );
    final service = _PagedCatalog()..failedMovieId = 999;
    final viewModel = FavoritesViewModel(
      api: MemberApiService(dio),
      movies: service,
    );

    await viewModel.load();

    expect(viewModel.items, hasLength(2));
    expect(viewModel.items.first.movie?.id, 1);
    expect(viewModel.items.last.hasError, isTrue);
  });
}

class _PagedCatalog implements PagedMovieCatalogService {
  final discoverPages = <int>[];
  final _searches = <String, Completer<TmdbMoviePageDto>>{};
  int? failPageOnce;
  int? failedMovieId;

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [];

  @override
  Future<List<TmdbMovieDto>> fetchPopular() async => const [];

  @override
  Future<List<TmdbMovieDto>> fetchDiscover({List<int>? genreIds}) async =>
      (await fetchDiscoverPage(page: 1, genreIds: genreIds)).results;

  @override
  Future<TmdbMoviePageDto> fetchDiscoverPage({
    required int page,
    List<int>? genreIds,
  }) async {
    discoverPages.add(page);
    if (failPageOnce == page) {
      failPageOnce = null;
      throw StateError('일시적인 실패');
    }
    return TmdbMoviePageDto(page: page, totalPages: 2, results: [_dto(page)]);
  }

  @override
  Future<TmdbMovieDto> fetchMovieById(int id) async {
    if (id == failedMovieId) throw StateError('영화 조회 실패');
    return _dto(id);
  }

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required String query,
    required int page,
  }) => (_searches[query] ??= Completer<TmdbMoviePageDto>()).future;

  void completeSearch(String query, int id) {
    _searches[query]!.complete(
      TmdbMoviePageDto(page: 1, totalPages: 1, results: [_dto(id)]),
    );
  }

  TmdbMovieDto _dto(int id) => TmdbMovieDto(
    id: id,
    title: '영화 $id',
    genreIds: const [],
    voteAverage: 8,
    overview: '줄거리',
  );
}
