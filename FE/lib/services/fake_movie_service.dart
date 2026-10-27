import '../data/mock_movies.dart';
import '../models/movie.dart';

enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

abstract interface class MovieService {
  Future<List<Movie>> fetchMovies({MovieLoadMode? mode});
}

class FakeMovieService implements MovieService {
  const FakeMovieService({
    this.delay = const Duration(seconds: 10),
    this.defaultMode = MovieLoadMode.success,
  });

  final Duration delay;
  final MovieLoadMode defaultMode;

  @override
  Future<List<Movie>> fetchMovies({MovieLoadMode? mode}) async {
    // TODO(5주차 유저별 평점 조회 API): 실제 API Service 호출로 교체합니다.
    await Future<void>.delayed(delay);

    return switch (mode ?? defaultMode) {
      MovieLoadMode.success => mockMovies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
    };
  }
}
