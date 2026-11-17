import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

/// TMDB Discover/Search를 한 page씩 불러옵니다. 영화 목록과 검색 화면이 각자 인스턴스를 씁니다.
class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel({required this.tmdbApi});

  /// TMDB는 1~500 page만 조회할 수 있습니다.
  static const maxTmdbPage = 500;

  final TmdbMovieService tmdbApi;

  LoadPhase phase = LoadPhase.idle;
  final List<TmdbMovieDto> movies = [];

  /// 다음에 요청할 page. 성공했을 때만 올려 실패하면 같은 page를 다시 요청합니다.
  int nextPage = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  String? errorMessage;
  String? loadMoreError;

  int _requestGeneration = 0;
  ({List<int>? genreIds, String query}) _condition = (
    genreIds: null,
    query: '',
  );

  bool get hasMore => nextPage <= totalPages;
  String get query => _condition.query;

  /// 조건(장르·검색어)이 바뀌거나 새로고침하면 목록·page·추가 로딩 상태를 모두 비우고 page 1부터.
  Future<void> loadInitial({List<int>? genreIds, String query = ''}) async {
    if (isDisposed) return;
    _condition = (genreIds: genreIds, query: query.trim());
    final generation = ++_requestGeneration; // 이전 조건의 늦은 응답을 버립니다.
    phase = LoadPhase.loading;
    errorMessage = null;
    loadMoreError = null;
    isLoadingMore = false;
    movies.clear();
    nextPage = 1;
    totalPages = 1;
    notifyIfAlive();

    try {
      final page = await _fetchPage(1);
      if (generation != _requestGeneration || isDisposed) return;
      movies.addAll(_dedupe(page.results));
      _advance(page);
      phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      phase = LoadPhase.error;
      errorMessage = _condition.query.isEmpty
          ? '영화 목록을 불러오지 못했습니다.'
          : '검색 결과를 불러오지 못했습니다.';
    }
    notifyIfAlive();
  }

  Future<void> loadNextPage() async {
    if (isDisposed || isLoadingMore || !hasMore || phase != LoadPhase.ready) {
      return;
    }
    final generation = _requestGeneration;
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();

    try {
      final page = await _fetchPage(nextPage);
      if (generation != _requestGeneration || isDisposed) return;
      movies.addAll(_dedupe(page.results));
      _advance(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      loadMoreError = '다음 페이지를 불러오지 못했습니다.';
    } finally {
      if (generation == _requestGeneration && !isDisposed) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  Future<TmdbMoviePageDto> _fetchPage(int page) async {
    final condition = _condition;
    final result = condition.query.isNotEmpty
        ? await tmdbApi.searchMovies(page: page, query: condition.query)
        : await tmdbApi.discoverMovies(
            page: page,
            genreIds: condition.genreIds,
          );
    if (result.page != page) {
      throw const FormatException('TMDB page metadata is inconsistent.');
    }
    return result;
  }

  void _advance(TmdbMoviePageDto page) {
    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;
    nextPage = page.page + 1;
  }

  /// TMDB는 page가 바뀌어도 같은 영화를 다시 줄 수 있어 이미 가진 id는 뺍니다.
  List<TmdbMovieDto> _dedupe(List<TmdbMovieDto> incoming) {
    final seen = movies.map((movie) => movie.id).toSet();
    return incoming.where((movie) => seen.add(movie.id)).toList();
  }
}
