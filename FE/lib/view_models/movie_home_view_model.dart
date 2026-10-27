import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import '../services/tmdb_client.dart';
import '../services/tmdb_movie_service.dart';

enum MovieLoadStatus { idle, loading, success, empty, error }

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);
  final TmdbMovieService _service;
  final CancelToken _cancelToken = CancelToken();
  bool _disposed = false;
  MovieLoadStatus status = MovieLoadStatus.idle;
  List<Movie> movies = const [];
  String? errorMessage;

  Future<void> load() async {
    if (status == MovieLoadStatus.loading || _disposed) return;
    status = MovieLoadStatus.loading;
    notifyListeners();
    try {
      final popular = await _service.fetchPopular(cancelToken: _cancelToken);
      final genres = await _service.fetchGenres(cancelToken: _cancelToken);
      if (_disposed) return;
      movies = List.unmodifiable(
        popular.results.take(5).map((m) => m.toMovie(genres)),
      );
      errorMessage = null;
      status = movies.isEmpty ? MovieLoadStatus.empty : MovieLoadStatus.success;
    } catch (error) {
      if (_disposed) return;
      errorMessage = tmdbErrorMessage(error);
      status = MovieLoadStatus.error;
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
