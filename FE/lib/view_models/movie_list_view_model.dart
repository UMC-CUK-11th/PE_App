import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/services/movie_catalog_service.dart';
import '../models/movie.dart';
import 'movie_home_view_model.dart';

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, {List<int>? initialGenreIds})
    : selectedGenreIds = initialGenreIds == null
          ? null
          : List<int>.of(initialGenreIds);

  final MovieCatalogService _service;

  ViewLoadState state = ViewLoadState.loading;
  List<TmdbGenreDto> genres = const [];
  List<int>? selectedGenreIds;
  List<Movie> movies = const [];
  String? errorMessage;
  bool isRefreshing = false;
  bool isDiscoverLoading = false;
  int errorVersion = 0;
  int _requestVersion = 0;
  List<int>? _pendingGenreIds;
  bool _hasPendingGenreSelection = false;

  bool get hasMovies => movies.isNotEmpty;
  bool get isGenreSelectionLocked =>
      isDiscoverLoading || state == ViewLoadState.loading;

  Map<int, String> get _genreNames => {
    for (final genre in genres) genre.id: genre.name,
  };

  Future<void> loadInitial() async {
    if (isDiscoverLoading) return;
    state = ViewLoadState.loading;
    notifyListeners();
    try {
      genres = await _service.fetchGenres();
      await _loadDiscover(genreIds: selectedGenreIds, clearWhileLoading: true);
    } on Object catch (error) {
      _handleFailure(error, fallback: const []);
    }
    await _applyPendingGenresIfNeeded();
  }

  Future<bool> applyGenres(List<int> genreIds) async {
    final normalized = _normalizeGenres(genreIds);
    if (isGenreSelectionLocked) {
      _pendingGenreIds = normalized;
      _hasPendingGenreSelection = true;
      return false;
    }

    final previousGenreIds = selectedGenreIds == null
        ? null
        : List<int>.of(selectedGenreIds!);
    selectedGenreIds = normalized;
    final succeeded = await _loadDiscover(
      genreIds: selectedGenreIds,
      clearWhileLoading: true,
    );
    if (!succeeded) {
      selectedGenreIds = previousGenreIds;
      notifyListeners();
    }
    await _applyPendingGenresIfNeeded();
    return succeeded;
  }

  Future<void> refresh() async {
    if (isDiscoverLoading || state == ViewLoadState.loading) return;
    isRefreshing = true;
    notifyListeners();
    await _loadDiscover(genreIds: selectedGenreIds, clearWhileLoading: false);
    isRefreshing = false;
    notifyListeners();
  }

  Future<void> retry() async {
    if (isDiscoverLoading) return;
    if (genres.isEmpty) {
      await loadInitial();
      return;
    }
    await _loadDiscover(
      genreIds: selectedGenreIds,
      clearWhileLoading: movies.isEmpty,
    );
  }

  Future<bool> _loadDiscover({
    required List<int>? genreIds,
    required bool clearWhileLoading,
  }) async {
    final requestVersion = ++_requestVersion;
    final previousMovies = movies;
    isDiscoverLoading = true;
    errorMessage = null;
    if (clearWhileLoading) {
      movies = const [];
      state = ViewLoadState.loading;
    }
    notifyListeners();

    try {
      final dtos = await _service.fetchDiscover(genreIds: genreIds);
      if (requestVersion != _requestVersion) return false;
      final converted = dtos
          .map((dto) => dto.toMovie(_genreNames))
          .toList(growable: false);
      movies = converted;
      state = converted.isEmpty ? ViewLoadState.empty : ViewLoadState.success;
      return true;
    } on Object catch (error) {
      if (requestVersion != _requestVersion) return false;
      _handleFailure(error, fallback: previousMovies);
      return false;
    } finally {
      if (requestVersion == _requestVersion) {
        isDiscoverLoading = false;
        notifyListeners();
      }
    }
  }

  List<int>? _normalizeGenres(Iterable<int> genreIds) {
    final normalized = genreIds.toSet().toList(growable: false)..sort();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> _applyPendingGenresIfNeeded() async {
    if (!_hasPendingGenreSelection) return;
    final pending = _pendingGenreIds;
    _pendingGenreIds = null;
    _hasPendingGenreSelection = false;
    if (listEquals(pending, selectedGenreIds)) return;
    await applyGenres(pending ?? const []);
  }

  void _handleFailure(Object error, {required List<Movie> fallback}) {
    errorMessage = error.toString();
    errorVersion++;
    movies = fallback;
    state = fallback.isEmpty ? ViewLoadState.error : ViewLoadState.success;
    notifyListeners();
  }
}
