import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/services/movie_catalog_service.dart';
import '../models/movie.dart';
import 'movie_home_view_model.dart';

class MovieSearchViewModel extends ChangeNotifier {
  MovieSearchViewModel(this._service);

  final PagedMovieCatalogService _service;
  ViewLoadState state = ViewLoadState.empty;
  List<Movie> movies = const [];
  bool isLoadingMore = false;
  bool hasMore = false;
  String? errorMessage;
  String? loadMoreError;
  String query = '';
  int _nextPage = 1;
  int _generation = 0;
  Timer? _debounce;
  bool _disposed = false;

  void searchAsYouType(String value) {
    _debounce?.cancel();
    final normalized = value.trim();
    if (normalized.isEmpty) {
      _generation++;
      query = '';
      movies = const [];
      state = ViewLoadState.empty;
      hasMore = false;
      notifyListeners();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => search(normalized),
    );
  }

  Future<void> search(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final generation = ++_generation;
    query = normalized;
    state = ViewLoadState.loading;
    movies = const [];
    errorMessage = null;
    loadMoreError = null;
    _notify();
    try {
      final page = await _service.searchMovies(query: normalized, page: 1);
      if (generation != _generation || _disposed) return;
      movies = page.results.map((dto) => dto.toMovie(const {})).toList();
      _nextPage = 2;
      hasMore = page.page < page.totalPages;
      state = movies.isEmpty ? ViewLoadState.empty : ViewLoadState.success;
    } on Object catch (error) {
      if (generation != _generation || _disposed) return;
      errorMessage = error.toString();
      state = ViewLoadState.error;
    }
    _notify();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || query.isEmpty) return;
    final generation = _generation;
    final pageNumber = _nextPage;
    isLoadingMore = true;
    loadMoreError = null;
    _notify();
    try {
      final page = await _service.searchMovies(query: query, page: pageNumber);
      if (generation != _generation || _disposed) return;
      final ids = movies.map((movie) => movie.id).toSet();
      movies = [
        ...movies,
        ...page.results
            .map((dto) => dto.toMovie(const {}))
            .where((movie) => ids.add(movie.id)),
      ];
      _nextPage = pageNumber + 1;
      hasMore = page.page < page.totalPages;
    } on Object catch (error) {
      if (generation != _generation || _disposed) return;
      loadMoreError = error.toString();
    } finally {
      if (generation == _generation && !_disposed) {
        isLoadingMore = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }
}
