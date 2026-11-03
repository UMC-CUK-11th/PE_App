import 'package:flutter/foundation.dart';

import '../data/services/movie_catalog_service.dart';
import '../models/movie.dart';

enum ViewLoadState { loading, empty, error, success }

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  final MovieCatalogService _service;

  ViewLoadState state = ViewLoadState.loading;
  List<Movie> movies = const [];
  String? errorMessage;
  bool _hasRequested = false;

  Future<void> loadPopular() async {
    if (_hasRequested) return;
    _hasRequested = true;
    state = ViewLoadState.loading;
    notifyListeners();
    try {
      final popularFuture = _service.fetchPopular();
      final genreNamesFuture = _loadGenreNames();
      final dtos = await popularFuture;
      movies = dtos
          .take(5)
          .map((dto) => dto.toMovie(const {}))
          .toList(growable: false);
      state = movies.isEmpty ? ViewLoadState.empty : ViewLoadState.success;
      notifyListeners();

      final genreNames = await genreNamesFuture;
      if (genreNames.isNotEmpty) {
        movies = dtos
            .take(5)
            .map((dto) => dto.toMovie(genreNames))
            .toList(growable: false);
      }
    } on Object catch (error) {
      errorMessage = error.toString();
      state = ViewLoadState.error;
    }
    notifyListeners();
  }

  Future<Map<int, String>> _loadGenreNames() async {
    try {
      final genres = await _service.fetchGenres();
      return {for (final genre in genres) genre.id: genre.name};
    } on Object {
      return const {};
    }
  }

  Future<void> retry() async {
    _hasRequested = false;
    await loadPopular();
  }
}
