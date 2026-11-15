import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/models/rating_dto.dart';
import 'package:movielog/models/tmdb_movie_dto.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/services/member_check_service.dart';
import 'package:movielog/services/rating_api_service.dart';
import 'package:movielog/services/tmdb_client.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/signup_view_model.dart';

import '../tool/week06_preview.dart' as preview;
import 'support/test_tmdb_service.dart';
import 'week06_mission_test.dart'
    show CheckService, RatingsService, MoviesService;

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.respond);
  final Object Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _NoGenres extends TestTmdbService {
  @override
  Future<List<TmdbGenreDto>> fetchGenres({CancelToken? cancelToken}) async =>
      throw StateError('genres unavailable');
}

class _DetailedMovies extends TestTmdbService {
  int details = 0;
  @override
  Future<TmdbMovieDto> fetchDetail(int id, {CancelToken? cancelToken}) async {
    details++;
    return TmdbMovieDto(id: id, title: '상세 조회 결과', runtime: 123);
  }
}

class _PendingMovies extends TmdbMovieService {
  _PendingMovies() : super(Dio());
  final pending = <int, Completer<TmdbMovieDto>>{};
  final tokens = <CancelToken?>[];
  int active = 0;
  int maxActive = 0;
  @override
  Future<TmdbMovieDto> fetchMovieDetail(
    int id, {
    CancelToken? cancelToken,
  }) async {
    active++;
    if (active > maxActive) maxActive = active;
    tokens.add(cancelToken);
    final gate = Completer<TmdbMovieDto>();
    pending[id] = gate;
    try {
      return await gate.future;
    } finally {
      active--;
    }
  }

  void release() {
    for (final entry in pending.entries) {
      if (!entry.value.isCompleted) {
        entry.value.complete(
          TmdbMovieDto(id: entry.key, title: '영화 ${entry.key}'),
        );
      }
    }
  }
}

RatingDto _rating(int id) => RatingDto(
  ratingId: id,
  movieId: id,
  score: 5,
  createdAt: DateTime.utc(2026),
  comment: '후기',
);
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('이메일 서비스가 실제 v5 인코딩 경로와 available 응답을 사용한다', () async {
    for (final available in [false, true]) {
      final adapter = _JsonAdapter((_) => {'available': available});
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final result = await MemberCheckService(dio)
          .checkEmail(' user+tag@example.com ');
      expect(
        adapter.requests.single.path,
        '/v5/members/email/${Uri.encodeComponent('user+tag@example.com')}',
      );
      expect(result, available);
    }
  });

  test('평점 서비스가 요청한 회원 경로의 JSON 목록을 순서대로 변환한다', () async {
    final adapter = _JsonAdapter(
      (_) => [
        {
          'ratingId': 9,
          'movieId': 550,
          'score': 4,
          'comment': null,
          'createdAt': '2026-11-03T00:00:00Z',
        },
        {
          'ratingId': 8,
          'movieId': 13,
          'score': 3,
          'comment': '후기',
          'createdAt': '2026-11-02T00:00:00Z',
        },
      ],
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    addTearDown(dio.close);
    final service = RatingApiService(dio);
    final items = await service.fetchMyRatings(42);
    expect(adapter.requests.single.path, '/v5/members/42/ratings');
    expect(items.map((r) => r.ratingId), [9, 8]);
    expect(items.first.movieId, 550);
    expect(items.first.comment, isNull);
    expect(items.last.comment, '후기');
    expect(items.first.createdAt.isUtc, isTrue);
  });

  test('공백만 바뀌면 완료된 중복 확인과 제출 가능 상태를 유지한다', () async {
    final vm = SignUpViewModel(CheckService()..available = true);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('홀란드');
    vm.onEmailChanged('user@example.com');
    await vm.checkNickname('홀란드');
    await vm.checkEmail('user@example.com');
    vm.onNicknameChanged(' 홀란드 ');
    vm.onEmailChanged(' user@example.com ');
    expect(vm.bothAvailable, isTrue);
    vm.onNicknameChanged('제임스');
    expect(vm.bothAvailable, isFalse);
  });

  test('공백만 바뀌면 진행 중 중복 확인의 응답을 무효화하지 않는다', () async {
    final service = CheckService()..pending = Completer<bool>();
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('홀란드');
    final loading = vm.checkNickname('홀란드');
    vm.onNicknameChanged(' 홀란드 ');
    expect(vm.nicknameCheckStatus, CheckStatus.checking);
    service.pending!.complete(true);
    await loading;
    expect(vm.nicknameCheckStatus, CheckStatus.available);
  });

  test('장르 API 실패에도 인기 영화는 기타 장르로 표시한다', () async {
    final vm = MovieHomeViewModel(_NoGenres());
    addTearDown(vm.dispose);
    await vm.load();
    expect(vm.status, MovieLoadStatus.success);
    expect(vm.movies, hasLength(5));
    expect(vm.movies.first.genres, contains('기타'));
    expect(vm.errorMessage, isNull);
  });

  test('저장된 장르 이름과 숫자 ID를 함께 복원하며 URL이 우선한다', () async {
    final saved = MemoryMovieListPreferences()
      ..genres = {'SF', '액션', '18', '없는 장르'};
    final vm = MovieListViewModel(TestTmdbService(), preferences: saved);
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(vm.selectedGenreIds, [18, 28, 878]);
    final explicit = MovieListViewModel(TestTmdbService(), preferences: saved);
    addTearDown(explicit.dispose);
    await explicit.initialize(genreIds: [16]);
    expect(explicit.selectedGenreIds, [16]);
  });

  test('TMDB 404는 연결 오류와 다른 영화 없음 안내를 제공한다', () {
    final request = RequestOptions(path: '/movie/999999999');
    expect(
      tmdbErrorMessage(
        DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 404),
        ),
      ),
      '영화를 찾을 수 없습니다.',
    );
    expect(
      tmdbErrorMessage(DioException(requestOptions: request)),
      contains('네트워크'),
    );
  });

  test('영화 상세를 최대 5개씩 요청하고 완료된 캐시를 다시 요청하지 않는다', () async {
    final ratings = RatingsService()
      ..items = List.generate(12, (i) => _rating(i + 1));
    final movies = _PendingMovies();
    final vm = MyRatingsViewModel(ratings, movies);
    addTearDown(vm.dispose);
    final loading = vm.load();
    await _flush();
    expect(movies.pending.length, 5);
    movies.release();
    await _flush();
    expect(movies.pending.length, 10);
    movies.release();
    await _flush();
    expect(movies.pending.length, 12);
    movies.release();
    await loading;
    expect(movies.maxActive, 5);
    expect(vm.moviesById, hasLength(12));
    await vm.load();
    expect(movies.pending.length, 12);
  });

  test('화면 폐기 시 진행 중 토큰을 취소하고 다음 상세 묶음을 시작하지 않는다', () async {
    final ratings = RatingsService()
      ..items = List.generate(12, (i) => _rating(i + 1));
    final movies = _PendingMovies();
    final vm = MyRatingsViewModel(ratings, movies);
    final loading = vm.load();
    await _flush();
    vm.dispose();
    expect(movies.tokens, everyElement(isNotNull));
    expect(movies.tokens.every((t) => t!.isCancelled), isTrue);
    movies.release();
    await loading;
    expect(movies.pending.length, 5);
    expect(vm.moviesById, isEmpty);
  });

  test('실제 영화 상세 서비스가 CancelToken을 Dio에 전달한다', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    addTearDown(dio.close);
    final adapter = _JsonAdapter((_) => {'id': 1, 'title': '상세'});
    dio.httpClientAdapter = adapter;
    final token = CancelToken()..cancel('screen disposed');
    await expectLater(
      TmdbMovieService(dio).fetchMovieDetail(1, cancelToken: token),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  testWidgets('URL 장르 변경 및 브라우저 경로 복원 시 목록을 동기화한다', (tester) async {
    final service = TestTmdbService();
    final saved = MemoryMovieListPreferences()..genres = {'18'};
    final router = AppRouter.createRouter(
      initialLocation: '/movies?genre=878',
      tmdbService: service,
      movieListPreferences: saved,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(router: router));
    await tester.pumpAndSettle();
    expect(service.requestedGenres.last, [878]);
    router.go('/movies?genre=28');
    await tester.pumpAndSettle();
    expect(service.requestedGenres.last, [28]);
    await router.routeInformationProvider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('/movies?genre=878')),
    );
    await tester.pumpAndSettle();
    expect(service.requestedGenres.last, [878]);
    router.go('/movies');
    await tester.pumpAndSettle();
    expect(service.requestedGenres.last, [18]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('목록 Movie에 상영 시간이 없으면 상세 API를 조회한다', (tester) async {
    final service = _DetailedMovies();
    final router = AppRouter.createRouter(
      initialLocation: '/movies',
      tmdbService: service,
      movieListPreferences: MemoryMovieListPreferences(),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(router: router));
    await tester.pumpAndSettle();
    router.go(
      '/movies/1',
      extra: const TmdbMovieDto(id: 1, title: '목록 영화').toMovie([]),
    );
    await tester.pumpAndSettle();
    expect(service.details, 1);
    expect(find.text('상세 조회 결과'), findsOneWidget);
    expect(find.textContaining('123'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('재조회 중 기존 목록과 RefreshIndicator를 유지한다', (tester) async {
    final ratings = RatingsService()..items = [_rating(1)];
    final vm = MyRatingsViewModel(ratings, MoviesService());
    addTearDown(vm.dispose);
    await vm.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: MyRatingsScreen()),
      ),
    );
    expect(find.text('테스트 영화'), findsOneWidget);
    ratings.pending = Completer<List<RatingDto>>();
    final loading = vm.load();
    await tester.pump();
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('테스트 영화'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    ratings.pending!.complete([_rating(1)]);
    await loading;
    await tester.pumpAndSettle();
    expect(find.text('테스트 영화'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('프리뷰 회원가입 폼 완료 후 home 이동이 동작한다', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const preview.PreviewApp());
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '홀란드');
    await tester.enterText(fields.at(1), 'preview@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.tap(find.byKey(const ValueKey('check-nickname')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('check-email')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();
    expect(find.text('프리뷰 · 폼 검증 완료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
