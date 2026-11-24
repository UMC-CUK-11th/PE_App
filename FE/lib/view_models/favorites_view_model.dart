import 'package:flutter/foundation.dart';

import '../data/services/member_api_service.dart';
import '../data/services/movie_catalog_service.dart';
import '../models/movie.dart';
import 'movie_home_view_model.dart';

class FavoriteMovieItem {
  const FavoriteMovieItem({
    required this.movieId,
    this.movie,
    this.hasError = false,
  });

  final int movieId;
  final Movie? movie;
  final bool hasError;
}

class FavoritesViewModel extends ChangeNotifier {
  FavoritesViewModel({required this.api, required this.movies});

  final MemberApiService api;
  final PagedMovieCatalogService movies;
  ViewLoadState state = ViewLoadState.loading;
  List<FavoriteMovieItem> items = const [];
  String? errorMessage;
  int _generation = 0;
  bool _disposed = false;

  Future<void> load() async {
    final generation = ++_generation;
    state = ViewLoadState.loading;
    errorMessage = null;
    _notify();
    try {
      final favorites = await api.fetchFavorites();
      if (!_isCurrent(generation)) return;
      if (favorites.isEmpty) {
        items = const [];
        state = ViewLoadState.empty;
        _notify();
        return;
      }
      final loaded = <FavoriteMovieItem>[];
      const batchSize = 5;
      for (var start = 0; start < favorites.length; start += batchSize) {
        final batch = favorites.skip(start).take(batchSize);
        final results = await Future.wait(
          batch.map((favorite) async {
            try {
              final dto = await movies.fetchMovieById(favorite.movieId);
              return FavoriteMovieItem(
                movieId: favorite.movieId,
                movie: dto.toMovie(const {}),
              );
            } on Object {
              return FavoriteMovieItem(
                movieId: favorite.movieId,
                hasError: true,
              );
            }
          }),
        );
        if (!_isCurrent(generation)) return;
        loaded.addAll(results);
      }
      items = loaded;
      state = ViewLoadState.success;
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      errorMessage = error.toString();
      state = ViewLoadState.error;
    }
    _notify();
  }

  bool _isCurrent(int value) => !_disposed && value == _generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
