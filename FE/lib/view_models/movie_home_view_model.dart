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
      var genreNames = <int, String>{};
      try {
        final genres = await _service.fetchGenres();
        genreNames = {for (final genre in genres) genre.id: genre.name};
      } on Object {
        // Popular 목록은 장르 조회가 실패해도 표시한다.
      }
      final dtos = await _service.fetchPopular();
      movies = dtos
          .take(5)
          .map((dto) => dto.toMovie(genreNames))
          .toList(growable: false);
      state = movies.isEmpty ? ViewLoadState.empty : ViewLoadState.success;
    } on Object catch (error) {
      errorMessage = error.toString();
      state = ViewLoadState.error;
    }
    notifyListeners();
  }

  Future<void> retry() async {
    _hasRequested = false;
    await loadPopular();
  }
}
