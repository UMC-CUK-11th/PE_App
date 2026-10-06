import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  const service = FakeMovieService(delay: Duration.zero);

  test('성공 모드는 기존 Mock 영화 목록을 반환한다', () async {
    final movies = await service.fetchMovies();

    expect(movies, same(mockMovies));
  });

  test('빈 목록 모드는 빈 영화 목록을 반환한다', () async {
    final movies = await service.fetchMovies(mode: MovieLoadMode.empty);

    expect(movies, isEmpty);
  });

  test('실패 모드는 MovieLoadException을 전달한다', () async {
    expect(
      service.fetchMovies(mode: MovieLoadMode.failure),
      throwsA(isA<MovieLoadException>()),
    );
  });
}
