import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import '../services/movie_catalog_service.dart';

enum ViewLoadState { loading, empty, error, success }

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._service);

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
      final dtos = await _service.fetchPopular();
      movies = dtos
          .take(5)
          .map((dto) => dto.toMovie(const {}))
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
