import 'movie.dart';

/// 4주차 Mock 응답 모드. 화면에서 Loading·Empty·Error·Success를 재현할 때 사용합니다.
enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;

  @override
  String toString() => 'MovieLoadException: $message';
}

class FakeMovieService {
  const FakeMovieService({this.delay = const Duration(seconds: 1)});

  /// Loading 화면이 최소 800ms 이상 보이도록 기본 1초 지연합니다.
  final Duration delay;

  // TODO(5주차 유저별 평점 조회 API): Swagger v5 API Service로 교체합니다.
  // 화면은 Future<List<Movie>>만 기다리므로 호출 경계는 그대로 유지됩니다.
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(delay);

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure =>
        throw const MovieLoadException('영화를 불러오지 못했습니다.'),
    };
  }
}
