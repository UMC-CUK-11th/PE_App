import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/models/tmdb_genre_dto.dart';
import 'package:movielog/models/tmdb_movie_dto.dart';
import 'package:movielog/services/movie_catalog_service.dart';
import 'package:movielog/viewmodels/home_view_model.dart';
import 'package:movielog/viewmodels/movie_list_view_model.dart';

void main() {
  test('HomeViewModel은 Popular 요청을 한 번만 하고 최대 5개를 보관한다', () async {
    final service = _FakeCatalogService(
      movies: [for (var id = 1; id <= 8; id++) _movie(id)],
    );
    final viewModel = HomeViewModel(service);

    await viewModel.loadPopular();
    await viewModel.loadPopular();

    expect(service.popularCallCount, 1);
    expect(viewModel.movies, hasLength(5));
    expect(viewModel.state, ViewLoadState.success);
  });

  test('장르 다중 선택은 ID 목록을 그대로 Discover 요청에 전달한다', () async {
    final service = _FakeCatalogService(movies: [_movie(1)]);
    final viewModel = MovieListViewModel(service);
    await viewModel.loadInitial();

    await viewModel.applyGenres([28, 12]);

    expect(viewModel.selectedGenreIds, [12, 28]);
    expect(service.lastGenreIds, [12, 28]);
  });

  test('새로고침 실패 시 최근 성공 목록을 유지하고 오류 이벤트를 만든다', () async {
    final service = _FakeCatalogService(movies: [_movie(7)]);
    final viewModel = MovieListViewModel(service);
    await viewModel.loadInitial();
    service.shouldFail = true;

    await viewModel.refresh();

    expect(viewModel.movies.single.id, 7);
    expect(viewModel.state, ViewLoadState.success);
    expect(viewModel.errorVersion, 1);
    expect(viewModel.errorMessage, contains('의도한 실패'));
  });

  test('Discover 로딩 중에는 장르 변경 요청을 추가로 시작하지 않는다', () async {
    final service = _FakeCatalogService(movies: [_movie(1)]);
    final viewModel = MovieListViewModel(service);
    await viewModel.loadInitial();
    service.pending = Completer<List<TmdbMovieDto>>();

    final first = viewModel.applyGenres([28]);
    await Future<void>.delayed(Duration.zero);
    await viewModel.applyGenres([12]);

    expect(service.discoverCallCount, 2);
    expect(viewModel.selectedGenreIds, [28]);
    service.pending!.complete([_movie(2)]);
    await first;
  });
}

class _FakeCatalogService implements MovieCatalogService {
  _FakeCatalogService({required this.movies});

  final List<TmdbMovieDto> movies;
  bool shouldFail = false;
  int popularCallCount = 0;
  int discoverCallCount = 0;
  List<int>? lastGenreIds;
  Completer<List<TmdbMovieDto>>? pending;

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    return const [
      TmdbGenreDto(id: 12, name: '모험'),
      TmdbGenreDto(id: 28, name: '액션'),
    ];
  }

  @override
  Future<List<TmdbMovieDto>> fetchPopular() async {
    popularCallCount++;
    return movies;
  }

  @override
  Future<List<TmdbMovieDto>> fetchDiscover({List<int>? genreIds}) async {
    discoverCallCount++;
    lastGenreIds = genreIds == null ? null : List<int>.of(genreIds);
    if (shouldFail) throw Exception('의도한 실패');
    if (pending != null) return pending!.future;
    return movies;
  }
}

TmdbMovieDto _movie(int id) {
  return TmdbMovieDto(
    id: id,
    title: '영화 $id',
    genreIds: const [28],
    voteAverage: 8,
    overview: '줄거리',
    releaseDate: '2026-01-01',
  );
}
