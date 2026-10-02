import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:movielog/services/movie_list_preferences.dart';

void main() {
  const preferences = _MemoryMovieListPreferences();

  Widget testApp({
    required MovieService service,
    Duration timeout = const Duration(seconds: 3),
  }) {
    return MaterialApp(
      home: MovieListScreen(
        selectedGenres: const {},
        movieService: service,
        preferences: preferences,
        timeout: timeout,
      ),
    );
  }

  testWidgets('비동기 작업 중 Loading 화면을 표시한다', (tester) async {
    await tester.pumpWidget(
      testApp(service: const FakeMovieService(delay: Duration(seconds: 1))),
    );

    expect(find.byKey(const ValueKey('genre-filter-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('genre-filter-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('movie-list-loading')), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('빈 결과는 Empty 화면으로 분기한다', (tester) async {
    await tester.pumpWidget(
      testApp(
        service: const FakeMovieService(
          delay: Duration.zero,
          defaultMode: MovieLoadMode.empty,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('movie-list-empty')), findsOneWidget);
  });

  testWidgets('실패 결과는 Error 화면으로 분기한다', (tester) async {
    await tester.pumpWidget(
      testApp(
        service: const FakeMovieService(
          delay: Duration.zero,
          defaultMode: MovieLoadMode.failure,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('movie-list-error')), findsOneWidget);
  });

  testWidgets('제한 시간을 넘기면 사용자용 Timeout 오류 화면을 표시한다', (tester) async {
    await tester.pumpWidget(
      testApp(
        service: const FakeMovieService(delay: Duration(seconds: 1)),
        timeout: const Duration(milliseconds: 100),
      ),
    );
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();

    expect(find.byKey(const ValueKey('movie-list-error')), findsOneWidget);
    expect(find.textContaining('TimeoutException'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('다시 시도할 때 새 Future를 만들고 성공 화면으로 전환한다', (tester) async {
    final service = _RetryMovieService();
    await tester.pumpWidget(testApp(service: service));
    await tester.pump();

    expect(find.byKey(const ValueKey('movie-list-error')), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    expect(find.byKey(const ValueKey('movie-list-loading')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
    expect(service.callCount, 2);
  });
}

class _MemoryMovieListPreferences implements MovieListPreferences {
  const _MemoryMovieListPreferences();

  @override
  Future<MovieListPreferencesData> read() async {
    return const MovieListPreferencesData(
      genres: {},
      sortOption: MovieSortOption.latest,
    );
  }

  @override
  Future<void> saveGenres(Set<String> genres) async {}

  @override
  Future<void> saveSortOption(MovieSortOption sortOption) async {}
}

class _RetryMovieService implements MovieService {
  int callCount = 0;

  @override
  Future<List<Movie>> fetchMovies({MovieLoadMode? mode}) async {
    callCount++;
    if (callCount == 1) {
      throw const MovieLoadException('첫 요청 실패');
    }
    return const FakeMovieService(delay: Duration.zero).fetchMovies();
  }
}
