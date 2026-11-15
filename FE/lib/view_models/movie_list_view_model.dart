import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/genre_preference.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, this._genrePreference);

  static const maxMovies = 30;

  final TmdbMovieService _service;
  final GenrePreference _genrePreference;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// null이면 "전체"이며 with_genres를 보내지 않습니다.
  List<int>? selectedGenreIds;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  bool isRefreshing = false;
  String? message;

  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading => status == MovieListLoadStatus.loading;

  /// Discover 요청 중에는 장르를 바꾸지 못하게 합니다.
  bool get canChangeGenre => !isLoading && !isRefreshing;

  String genreNamesOf(TmdbMovieDto movie) {
    final names = {for (final genre in genres) genre.id: genre.name};
    return movie.genreIds.map((id) => names[id]).nonNulls.take(2).join('/');
  }

  /// 결과가 30개가 되거나 마지막 페이지까지 page 1부터 요청합니다.
  /// TMDB id를 key로 써서 페이지 사이 중복은 하나만 남깁니다.
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    List<int>? genreIds,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovies && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == maxMovies) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.toList();
  }

  /// Genre API로 Chip을 구성하고 저장된 장르를 복원한 뒤 첫 목록을 불러옵니다.
  Future<void> loadInitial() async {
    final version = _startLoading();

    try {
      final (fetchedGenres, savedIds) = await (
        _service.fetchGenres(),
        _genrePreference.read(),
      ).wait;
      if (!_isCurrent(version)) return;

      genres = fetchedGenres;
      final validIds = {for (final genre in genres) genre.id};
      final restored = savedIds.where(validIds.contains).toList();
      selectedGenreIds = restored.isEmpty ? null : restored;
      // 영화 목록을 기다리는 동안에도 장르 Chip이 보이도록 알립니다.
      notifyListeners();
    } on ParallelWaitError<dynamic, dynamic> catch (error) {
      if (!_isCurrent(version)) return;
      debugPrint('장르 로드 실패: ${error.errors}');
      _fail('장르를 불러오지 못했어요. 다시 시도해 주세요.');
      return;
    }

    await _loadMovies(version);
  }

  /// 확인 버튼·Chip으로 바뀐 장르를 받아 목록을 비우고 page 1부터 다시 조회합니다.
  Future<void> selectGenres(List<int>? genreIds) async {
    if (!canChangeGenre) return;

    selectedGenreIds = (genreIds == null || genreIds.isEmpty)
        ? null
        : genres.map((genre) => genre.id).where(genreIds.contains).toList();
    movies = const [];
    final version = _startLoading();
    await _genrePreference.save(selectedGenreIds ?? const []);
    await _loadMovies(version);
  }

  /// Error 화면의 재시도. 장르 목록이 없으면 처음부터 다시 불러옵니다.
  Future<void> retry() {
    if (genres.isEmpty) return loadInitial();
    return _loadMovies(_startLoading());
  }

  /// 기존 목록을 유지한 채 같은 장르로 page 1부터 다시 조회합니다.
  /// 실패하면 목록을 그대로 두고 false를 돌려 화면이 재시도 Dialog를 띄우게 합니다.
  Future<bool> refresh() async {
    if (!canChangeGenre) return true;

    final version = ++_requestVersion;
    isRefreshing = true;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreIds: selectedGenreIds);
      if (!_isCurrent(version)) return true;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
      return true;
    } on DioException {
      message = '영화를 새로 불러오지 못했어요.';
      return false;
    } finally {
      if (!_disposed) {
        isRefreshing = false;
        notifyListeners();
      }
    }
  }

  int _startLoading() {
    status = MovieListLoadStatus.loading;
    notifyListeners();
    return ++_requestVersion;
  }

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  Future<void> _loadMovies(int version) async {
    try {
      final result = await fetchUpToThirtyMovies(genreIds: selectedGenreIds);
      // 더 늦게 시작한 요청이 있으면 이전 장르 결과는 버립니다.
      if (!_isCurrent(version)) return;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
      notifyListeners();
    } on DioException {
      if (!_isCurrent(version)) return;
      _fail('영화를 불러오지 못했어요. 다시 시도해 주세요.');
    }
  }

  void _fail(String text) {
    status = MovieListLoadStatus.error;
    message = text;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
