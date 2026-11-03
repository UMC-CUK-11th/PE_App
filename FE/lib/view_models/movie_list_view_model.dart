import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import '../models/tmdb_movie_dto.dart';
import '../services/movie_list_preferences.dart';
import '../services/tmdb_client.dart';
import '../services/tmdb_movie_service.dart';
import 'movie_home_view_model.dart';

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(
    this._service, {
    this.preferences = const SharedPreferencesMovieListPreferences(),
  });
  final TmdbMovieService _service;
  final MovieListPreferences preferences;
  final CancelToken _cancelToken = CancelToken();
  bool _disposed = false;
  bool _initialized = false;
  MovieLoadStatus status = MovieLoadStatus.idle;
  List<Movie> movies = const [];
  List<TmdbGenreDto> genres = const [];
  List<int>? selectedGenreIds;
  MovieSortOption sortOption = MovieSortOption.latest;
  String? errorMessage;
  int failureRevision = 0;
  bool get isLoading => status == MovieLoadStatus.loading;

  List<Movie> get visibleMovies {
    final result = [...movies];
    switch (sortOption) {
      case MovieSortOption.latest:
        result.sort((a, b) => b.year.compareTo(a.year));
      case MovieSortOption.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case MovieSortOption.title:
        result.sort((a, b) => a.title.compareTo(b.title));
    }
    return result;
  }

  Future<void> initialize({List<int>? genreIds}) async {
    if (_initialized || _disposed) return;
    _initialized = true;
    status = MovieLoadStatus.loading;
    notifyListeners();
    try {
      final saved = await preferences.read();
      if (_disposed) return;
      sortOption = saved.sortOption;
      final restored = saved.genres.map(int.tryParse).whereType<int>().toList();
      selectedGenreIds = _normalize(genreIds ?? restored);
    } catch (_) {
      selectedGenreIds = _normalize(genreIds);
    }
    if (_disposed) return;
    status = MovieLoadStatus.idle;
    await load();
  }

  List<int>? _normalize(List<int>? ids) => ids == null || ids.isEmpty
      ? null
      : List.unmodifiable(ids.where((id) => id > 0).toSet().toList()..sort());

  Future<void> selectGenres(List<int>? ids) async {
    if (isLoading || _disposed) return;
    selectedGenreIds = _normalize(ids);
    // 필터가 바뀔 때 화면은 초기화하되, 실패하면 마지막 성공 목록을 복구한다.
    final request = load(clearWhileLoading: true);
    try {
      await preferences.saveGenres(
        selectedGenreIds?.map((id) => '$id').toSet() ?? {},
      );
    } catch (_) {
      /* 저장 실패는 API 요청 결과에 영향을 주지 않는다. */
    }
    await request;
  }

  Future<void> setSortOption(MovieSortOption option) async {
    sortOption = option;
    notifyListeners();
    try {
      await preferences.saveSortOption(option);
    } catch (_) {
      /* 현재 정렬 유지 */
    }
  }

  Future<void> load({bool clearWhileLoading = false}) async {
    if (isLoading || _disposed) return;
    final previous = movies;
    final requestedGenres = selectedGenreIds;
    if (clearWhileLoading) movies = const [];
    status = MovieLoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      genres = await _service.fetchGenres(cancelToken: _cancelToken);
      final unique = <int, TmdbMovieDto>{};
      var page = 1;
      while (unique.length < 30) {
        final response = await _service.discoverMovies(
          page: page,
          genreIds: requestedGenres,
          cancelToken: _cancelToken,
        );
        if (_disposed) return;
        for (final movie in response.results) {
          unique.putIfAbsent(movie.id, () => movie);
          if (unique.length == 30) break;
        }
        if (response.results.isEmpty ||
            page >= response.totalPages ||
            page >= 500) {
          break;
        }
        page++;
      }
      if (_disposed) return;
      movies = List.unmodifiable(unique.values.map((m) => m.toMovie(genres)));
      status = movies.isEmpty ? MovieLoadStatus.empty : MovieLoadStatus.success;
    } catch (error) {
      if (_disposed) return;
      movies = previous;
      errorMessage = tmdbErrorMessage(error);
      status = MovieLoadStatus.error;
      failureRevision++;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken.cancel();
    super.dispose();
  }
}
