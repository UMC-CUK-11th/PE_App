import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import '../models/tmdb_genre_dto.dart';
import '../services/movie_catalog_service.dart';
import 'home_view_model.dart';

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

  bool get hasMovies => movies.isNotEmpty;

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
  }

  Future<void> applyGenres(List<int> genreIds) async {
    if (isDiscoverLoading) return;
    final normalized = genreIds.toSet().toList(growable: false)..sort();
    selectedGenreIds = normalized.isEmpty ? null : normalized;
    await _loadDiscover(genreIds: selectedGenreIds, clearWhileLoading: true);
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
    await _loadDiscover(
      genreIds: selectedGenreIds,
      clearWhileLoading: movies.isEmpty,
    );
  }

  Future<void> _loadDiscover({
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
      if (requestVersion != _requestVersion) return;
      final converted = dtos
          .map((dto) => dto.toMovie(_genreNames))
          .toList(growable: false);
      movies = converted;
      state = converted.isEmpty ? ViewLoadState.empty : ViewLoadState.success;
    } on Object catch (error) {
      if (requestVersion != _requestVersion) return;
      _handleFailure(error, fallback: previousMovies);
    } finally {
      if (requestVersion == _requestVersion) {
        isDiscoverLoading = false;
        notifyListeners();
      }
    }
  }

  void _handleFailure(Object error, {required List<Movie> fallback}) {
    errorMessage = error.toString();
    errorVersion++;
    movies = fallback;
    state = fallback.isEmpty ? ViewLoadState.error : ViewLoadState.success;
    notifyListeners();
  }
}
