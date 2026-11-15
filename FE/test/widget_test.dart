import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:movielog/data/genre_preference.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movies/genre_filter_sheet.dart';
import 'package:movielog/screens/sign_up/sign_up_validators.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

const _homeHeadline = '오늘은 어떤\n영화를 볼까요?';

TmdbMovieDto _movie(int id, {List<int> genreIds = const [28], String? title}) {
  return TmdbMovieDto(
    id: id,
    title: title ?? '영화 $id',
    overview: '줄거리 $id',
    posterPath: null,
    backdropPath: null,
    releaseDate: '2024-01-01',
    genreIds: genreIds,
    voteAverage: 8,
    popularity: 1,
  );
}

DioException _networkError() => DioException(
  requestOptions: RequestOptions(path: '/discover/movie'),
  type: DioExceptionType.connectionError,
);

/// 실제 HTTP 없이 TMDB 응답 모양을 흉내 냅니다.
class FakeTmdbMovieService extends TmdbMovieService {
  FakeTmdbMovieService({
    this.popular = const [],
    this.pages = const {},
    this.genres = const [
      TmdbGenreDto(id: 28, name: '액션'),
      TmdbGenreDto(id: 878, name: 'SF'),
    ],
  }) : super(Dio());

  List<TmdbMovieDto> popular;
  Map<int, List<TmdbMovieDto>> pages;
  List<TmdbGenreDto> genres;

  /// true면 discoverMovies가 DioException으로 실패합니다.
  bool failDiscover = false;

  /// 설정하면 discoverMovies가 이 Completer를 기다립니다.
  Completer<void>? discoverGate;
  final discoverCalls = <({int page, List<int>? genreIds})>[];

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    return TmdbMoviePageDto(
      page: 1,
      results: popular,
      totalPages: 1,
      totalResults: popular.length,
    );
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    discoverCalls.add((page: page, genreIds: genreIds));
    await discoverGate?.future;
    if (failDiscover) throw _networkError();

    final selected = genreIds;
    final results = (pages[page] ?? const <TmdbMovieDto>[])
        .where(
          (movie) => selected == null || movie.genreIds.any(selected.contains),
        )
        .toList();
    return TmdbMoviePageDto(
      page: page,
      results: results,
      totalPages: pages.length,
      totalResults: results.length,
    );
  }

  /// true면 fetchGenres가 DioException으로 실패합니다.
  bool failGenres = false;

  /// true면 영화 상세 조회가 네트워크 오류로 실패합니다.
  bool failMovieDetail = false;

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    if (failGenres) throw _networkError();
    return genres;
  }

  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    if (failMovieDetail) throw _networkError();
    final all = [...popular, ...pages.values.expand((page) => page)];
    for (final movie in all) {
      if (movie.id == movieId) return movie;
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/movie/$movieId'),
      response: Response(
        requestOptions: RequestOptions(path: '/movie/$movieId'),
        statusCode: 404,
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

/// 워크북 v5 중복 확인 응답을 흉내 냅니다.
class FakeMemberCheckService extends MemberCheckService {
  FakeMemberCheckService() : super(Dio());

  final takenNicknames = {'영화광', 'test'};
  final takenEmails = {'test@umc.com', 'movie@umc.com'};
  bool fail = false;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<bool> checkNickname(String nickname) async {
    calls++;
    await gate?.future;
    if (fail) throw _networkError();
    return !takenNicknames.contains(nickname.trim());
  }

  @override
  Future<bool> checkEmail(String email) async {
    calls++;
    await gate?.future;
    if (fail) throw _networkError();
    return !takenEmails.contains(email.trim());
  }
}

/// 워크북 v5 유저별 평점 조회 응답을 흉내 냅니다.
class FakeRatingApiService extends RatingApiService {
  FakeRatingApiService({this.ratings = const []}) : super(Dio());

  List<RatingDto> ratings;
  int? failStatus;

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final status = failStatus;
    if (status != null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/v5/members/$memberId/ratings'),
        response: Response(
          requestOptions: RequestOptions(path: '/v5/members/$memberId/ratings'),
          statusCode: status,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return ratings;
  }
}

RatingDto _rating(
  int id,
  int movieId, {
  String? comment = '좋아요',
  int score = 4,
}) {
  return RatingDto(
    ratingId: id,
    movieId: movieId,
    score: score,
    comment: comment,
    createdAt: DateTime(2026, 11, 15, 12),
  );
}

class _ThrowingGenrePreference implements GenrePreference {
  @override
  Future<List<int>> read() async => const [];

  @override
  Future<void> save(List<int> genreIds) async => throw StateError('저장 실패');
}

FakeTmdbMovieService _defaultService() => FakeTmdbMovieService(
  popular: [for (var id = 1; id <= 8; id++) _movie(id)],
  pages: {
    1: [
      _movie(1),
      _movie(2, genreIds: [878], title: '우주 영화'),
    ],
  },
);

Finder _field(int index) => find.byType(TextFormField).at(index);

Finder get _submitButton => find.widgetWithText(ElevatedButton, '가입하기');

bool _isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<ButtonStyleButton>(button).onPressed != null;
}

Future<FakeTmdbMovieService> _pumpApp(
  WidgetTester tester, {
  String location = '/start',
  Size size = const Size(390, 844),
  FakeTmdbMovieService? service,
  FakeMemberCheckService? checkService,
  FakeRatingApiService? ratingService,
  GenrePreference? preference,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final fake = service ?? _defaultService();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TmdbMovieService>.value(value: fake),
        Provider<MemberCheckService>.value(
          value: checkService ?? FakeMemberCheckService(),
        ),
        Provider<RatingApiService>.value(
          value: ratingService ?? FakeRatingApiService(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: AppRouter.createRouter(
          initialLocation: location,
          genrePreference: preference ?? InMemoryGenrePreference(),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return fake;
}

Future<void> _fillValidSignUp(WidgetTester tester) async {
  await tester.enterText(_field(0), '무비러버');
  await tester.enterText(_field(1), 'movie@example.com');
  await tester.enterText(_field(2), 'password1');
  await tester.pump();
}

void main() {
  group('SignUpValidators', () {
    test('닉네임은 비어 있거나 2자 미만이면 오류를 반환한다', () {
      expect(SignUpValidators.nickname(''), '닉네임을 입력해주세요.');
      expect(SignUpValidators.nickname(' a '), '닉네임은 2자 이상이어야 합니다.');
      expect(SignUpValidators.nickname('무비'), isNull);
    });

    test('이메일 형식이 아니면 오류를 반환한다', () {
      expect(SignUpValidators.email(''), '이메일을 입력해주세요.');
      expect(SignUpValidators.email('test@'), '올바른 이메일 형식이 아닙니다.');
      expect(SignUpValidators.email('movie@example.com'), isNull);
    });

    test('비밀번호가 8자 미만이면 오류를 반환한다', () {
      expect(SignUpValidators.password(''), '비밀번호를 입력해주세요.');
      expect(SignUpValidators.password('123'), '비밀번호는 8자 이상이어야 합니다.');
      expect(SignUpValidators.password('12345678'), isNull);
    });
  });

  group('SignUpScreen', () {
    testWidgets('처음에는 가입 버튼이 비활성화되어 있고 뒤로가기 버튼이 없다', (tester) async {
      await _pumpApp(tester, location: '/register');

      expect(find.text('회원가입'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(_isEnabled(tester, _submitButton), isFalse);
    });

    testWidgets('잘못된 입력에는 한국어 오류 메시지를 표시한다', (tester) async {
      await _pumpApp(tester, location: '/register');

      await tester.enterText(_field(0), 'a');
      await tester.enterText(_field(1), 'test@');
      await tester.enterText(_field(2), '123');
      await tester.pump();

      expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
      expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
      expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
      expect(_isEnabled(tester, _submitButton), isFalse);
    });

    testWidgets('유효한 입력과 약관 동의 후 가입하면 홈으로 이동한다', (tester) async {
      await _pumpApp(tester, location: '/register');

      await _fillValidSignUp(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      // 중복 확인 전에는 형식이 맞아도 가입할 수 없습니다.
      expect(_isEnabled(tester, _submitButton), isFalse);

      await tester.tap(find.text('중복 확인').at(0));
      await tester.tap(find.text('중복 확인').at(1));
      await tester.pumpAndSettle();
      expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);
      expect(find.text('사용할 수 있는 이메일입니다.'), findsOneWidget);
      expect(_isEnabled(tester, _submitButton), isTrue);

      await tester.tap(_submitButton);
      await tester.pumpAndSettle();

      expect(find.text(_homeHeadline), findsOneWidget);
      expect(find.text('회원가입이 완료되었습니다.'), findsOneWidget);
    });

    testWidgets('비밀번호 표시 버튼으로 obscureText를 전환한다', (tester) async {
      await _pumpApp(tester, location: '/register');

      EditableText passwordText() => tester.widget<EditableText>(
        find.descendant(of: _field(2), matching: find.byType(EditableText)),
      );

      expect(passwordText().obscureText, isTrue);
      await tester.tap(find.byTooltip('비밀번호 표시'));
      await tester.pump();
      expect(passwordText().obscureText, isFalse);
    });

    testWidgets('키보드가 열려도 Overflow가 발생하지 않는다', (tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.resetViewInsets);
      await _pumpApp(tester, location: '/register');

      await tester.enterText(_field(0), 'a');
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _submitButton,
        100,
        scrollable: find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(_submitButton, findsOneWidget);
    });

    testWidgets('넓은 화면에서는 Form 너비를 560으로 제한한다', (tester) async {
      await _pumpApp(
        tester,
        location: '/register',
        size: const Size(1280, 800),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_field(0)).width, lessThanOrEqualTo(560));
    });
  });

  group('TMDB DTO', () {
    test('snake_case·null·num 값을 Dart Model로 변환한다', () {
      final movie = TmdbMovieDto.fromJson({
        'id': 550,
        'title': null,
        'poster_path': null,
        'release_date': '',
        'genre_ids': [18, 53.0],
        'vote_average': 8,
      });

      expect(movie.id, 550);
      expect(movie.title, '제목 없음');
      expect(movie.overview, '');
      expect(movie.posterPath, isNull);
      expect(movie.year, isNull);
      expect(movie.genreIds, [18, 53]);
      expect(movie.voteAverage, 8.0);
    });

    test('페이지 응답과 장르 응답을 변환한다', () {
      final page = TmdbMoviePageDto.fromJson({
        'page': 1,
        'results': [
          {'id': 1, 'title': 'A'},
        ],
        'total_pages': 3,
        'total_results': 60,
      });
      expect(page.results.single.id, 1);
      expect(page.totalPages, 3);

      final genre = TmdbGenreDto.fromJson({'id': 28, 'name': '액션'});
      expect((genre.id, genre.name), (28, '액션'));
    });

    test('poster_path가 없으면 이미지 URL을 만들지 않는다', () {
      expect(TmdbPosterImage.urlOf(null), isNull);
      expect(TmdbPosterImage.urlOf(''), isNull);
      expect(
        TmdbPosterImage.urlOf('/a.jpg'),
        'https://image.tmdb.org/t/p/w500/a.jpg',
      );
    });
  });

  group('MovieListViewModel', () {
    test('중복을 제거하며 최대 30개까지 page 1부터 요청한다', () async {
      final service = FakeTmdbMovieService(
        pages: {
          1: [for (var id = 1; id <= 20; id++) _movie(id)],
          // 15~20은 앞 페이지와 중복입니다.
          2: [for (var id = 15; id <= 34; id++) _movie(id)],
          3: [for (var id = 35; id <= 54; id++) _movie(id)],
        },
      );
      final viewModel = MovieListViewModel(service, InMemoryGenrePreference());

      await viewModel.loadInitial();

      expect(viewModel.status, MovieListLoadStatus.success);
      expect(viewModel.movies, hasLength(30));
      expect(viewModel.movies.map((movie) => movie.id).toSet(), hasLength(30));
      expect(service.discoverCalls.map((call) => call.page), [1, 2]);
    });

    test('결과가 30개보다 적으면 마지막 페이지에서 멈추고 오류로 보지 않는다', () async {
      final service = FakeTmdbMovieService(
        pages: {
          1: [_movie(1), _movie(2)],
          2: [_movie(3)],
        },
      );
      final viewModel = MovieListViewModel(service, InMemoryGenrePreference());

      await viewModel.loadInitial();

      expect(viewModel.movies, hasLength(3));
      expect(viewModel.status, MovieListLoadStatus.success);
    });

    test('장르를 고르면 목록을 비우고 with_genres로 page 1부터 다시 요청한다', () async {
      final service = _defaultService();
      final preference = InMemoryGenrePreference();
      final viewModel = MovieListViewModel(service, preference);
      await viewModel.loadInitial();
      service.discoverCalls.clear();

      await viewModel.selectGenres([878, 28]);

      // Genre API 순서로 정렬해 OR 조건으로 보냅니다.
      expect(service.discoverCalls.first.page, 1);
      expect(service.discoverCalls.first.genreIds, [28, 878]);
      expect(viewModel.selectedGenreIds, [28, 878]);
      expect(preference.saved, [28, 878]);

      await viewModel.selectGenres(const []);
      expect(service.discoverCalls.last.genreIds, isNull);
      expect(viewModel.selectedGenreIds, isNull);
    });

    test('Discover 요청 중에는 장르를 바꾸지 않는다', () async {
      final service = _defaultService();
      final viewModel = MovieListViewModel(service, InMemoryGenrePreference());
      await viewModel.loadInitial();

      service.discoverGate = Completer<void>();
      final pending = viewModel.selectGenres([28]);
      expect(viewModel.canChangeGenre, isFalse);

      await viewModel.selectGenres([878]);
      service.discoverGate!.complete();
      await pending;

      expect(viewModel.selectedGenreIds, [28]);
    });

    test('저장된 장르 ID를 복원하고 없는 ID는 버린다', () async {
      final service = _defaultService();
      final viewModel = MovieListViewModel(
        service,
        InMemoryGenrePreference([878, 9999]),
      );

      await viewModel.loadInitial();

      expect(viewModel.selectedGenreIds, [878]);
      expect(service.discoverCalls.first.genreIds, [878]);
      expect(viewModel.movies.single.title, '우주 영화');
    });

    test('결과가 없으면 Empty, 실패하면 Error 상태가 된다', () async {
      final empty = MovieListViewModel(
        FakeTmdbMovieService(pages: {1: const []}),
        InMemoryGenrePreference(),
      );
      await empty.loadInitial();
      expect(empty.status, MovieListLoadStatus.empty);

      final service = _defaultService()..failDiscover = true;
      final failed = MovieListViewModel(service, InMemoryGenrePreference());
      await failed.loadInitial();
      expect(failed.status, MovieListLoadStatus.error);

      service.failDiscover = false;
      await failed.retry();
      expect(failed.status, MovieListLoadStatus.success);
    });

    test('새로고침이 실패해도 최근 성공 목록을 유지한다', () async {
      final service = _defaultService();
      final viewModel = MovieListViewModel(service, InMemoryGenrePreference());
      await viewModel.loadInitial();

      service.failDiscover = true;
      final succeeded = await viewModel.refresh();

      expect(succeeded, isFalse);
      expect(viewModel.movies, hasLength(2));
      expect(viewModel.status, MovieListLoadStatus.success);
      expect(viewModel.isRefreshing, isFalse);
    });
  });

  group('MovieListViewModel 오류 경로', () {
    test('장르 저장이 실패해도 Loading에 멈추지 않는다', () async {
      final viewModel = MovieListViewModel(
        _defaultService(),
        _ThrowingGenrePreference(),
      );
      await viewModel.loadInitial();

      await viewModel.selectGenres([878]);

      expect(viewModel.status, MovieListLoadStatus.success);
      expect(viewModel.movies.single.title, '우주 영화');
    });

    testWidgets('Genre API 실패 후 "전체" 칩을 누르면 장르부터 다시 불러온다', (tester) async {
      final service = _defaultService()..failGenres = true;
      await _pumpApp(tester, location: '/movies', service: service);

      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, '액션'), findsNothing);

      service.failGenres = false;
      service.discoverCalls.clear();
      await tester.tap(find.widgetWithText(FilterChip, '전체'));
      await tester.pumpAndSettle();

      // 영화만 다시 조회하지 않고 장르 Chip까지 복구됩니다.
      expect(find.widgetWithText(FilterChip, '액션'), findsOneWidget);
      expect(find.text('영화 1'), findsOneWidget);
      expect(service.discoverCalls.first.genreIds, isNull);
    });

    test('빈 목록에서 새로고침이 실패하면 Empty 대신 Error가 된다', () async {
      final service = FakeTmdbMovieService(pages: {1: const []});
      final viewModel = MovieListViewModel(service, InMemoryGenrePreference());
      await viewModel.loadInitial();
      expect(viewModel.status, MovieListLoadStatus.empty);

      service.failDiscover = true;
      expect(await viewModel.refresh(), isFalse);

      expect(viewModel.status, MovieListLoadStatus.error);
    });
  });

  group('화면 전환', () {
    testWidgets('시작하기를 누르면 회원가입 화면으로 이동한다', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('회원가입'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('홈은 Popular 결과 중 5개만 보여주고 상세로 TMDB id를 넘긴다', (tester) async {
      await _pumpApp(tester, location: '/home', size: const Size(390, 1400));

      expect(find.text(_homeHeadline), findsOneWidget);
      final popularRow = find.descendant(
        of: find.byType(ListView).last,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('영화 5'),
        200,
        scrollable: popularRow.first,
      );
      expect(find.text('영화 6'), findsNothing);
      // 포스터가 없는 영화는 placeholder를 그립니다.
      expect(find.byKey(const ValueKey('poster-placeholder')), findsWidgets);

      await tester.tap(find.text('상세보기'));
      await tester.pumpAndSettle();
      expect(find.text('Cinema Archive'), findsOneWidget);
      expect(find.text('줄거리 1'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text(_homeHeadline), findsOneWidget);
    });

    testWidgets('Popular 결과가 5개보다 적어도 오류 없이 표시한다', (tester) async {
      await _pumpApp(
        tester,
        location: '/home',
        service: FakeTmdbMovieService(popular: [_movie(1), _movie(2)]),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('영화 2'), findsOneWidget);
    });

    testWidgets('NavigationBar로 영화와 마이 탭을 전환한다', (tester) async {
      await _pumpApp(tester, location: '/home');

      await tester.tap(find.text('영화'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );

      await tester.tap(find.text('마이'));
      await tester.pumpAndSettle();
      expect(find.text('내 프로필'), findsOneWidget);
    });
  });

  group('영화 목록 화면', () {
    testWidgets('BottomSheet에서 고른 장르로 다시 조회한다', (tester) async {
      final service = await _pumpApp(tester, location: '/movies');
      expect(find.text('영화 1'), findsOneWidget);

      await tester.tap(find.byTooltip('장르 필터'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(GenreFilterSheet),
          matching: find.text('SF'),
        ),
      );
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(service.discoverCalls.last.genreIds, [878]);
      expect(find.text('우주 영화'), findsOneWidget);
      expect(find.text('영화 1'), findsNothing);
      expect(find.text('장르: SF · 1편'), findsOneWidget);
    });

    testWidgets('로딩 중에는 Loading을 보여주고 장르 Chip을 막는다', (tester) async {
      final service = _defaultService()..discoverGate = Completer<void>();
      await _pumpApp(
        tester,
        location: '/movies',
        service: service,
        settle: false,
      );
      await tester.pump();

      expect(find.text('영화를 불러오는 중이에요'), findsOneWidget);
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '액션'),
      );
      expect(chip.onSelected, isNull);

      service.discoverGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('실패하면 Error 화면을 보여주고 다시 시도하면 목록을 불러온다', (tester) async {
      final service = _defaultService()..failDiscover = true;
      await _pumpApp(tester, location: '/movies', service: service);

      expect(find.text('다시 시도'), findsOneWidget);

      service.failDiscover = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('영화 1'), findsOneWidget);
    });

    testWidgets('결과가 없으면 Empty 화면을 보여준다', (tester) async {
      await _pumpApp(
        tester,
        location: '/movies',
        service: FakeTmdbMovieService(pages: {1: const []}),
      );

      expect(find.text('불러올 영화가 없어요'), findsOneWidget);
    });

    testWidgets('새로고침 실패 시 목록을 유지하고 재시도 Dialog를 띄운다', (tester) async {
      final service = await _pumpApp(tester, location: '/movies');
      service.failDiscover = true;

      await tester.fling(find.byType(GridView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('영화 1'), findsOneWidget);

      service.failDiscover = false;
      final calls = service.discoverCalls.length;
      await tester.tap(find.text('재시도'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(service.discoverCalls.length, greaterThan(calls));
      expect(service.discoverCalls.last.page, 1);
    });
  });

  group('MovieDetailScreen', () {
    testWidgets('즐겨찾기를 누르면 아이콘이 바뀌고 Snackbar를 표시한다', (tester) async {
      await _pumpApp(tester, location: '/movies/1');

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      await tester.tap(find.text('즐겨찾기'));
      await tester.pump();

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.text('즐겨찾기에 추가했어요.'), findsOneWidget);
    });

    testWidgets('평점 Dialog에서 별점을 고르면 확인 버튼이 활성화되고 저장된다', (tester) async {
      await _pumpApp(tester, location: '/movies/1');

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();

      final confirm = find.widgetWithText(ElevatedButton, '확인');
      expect(_isEnabled(tester, confirm), isFalse);

      final thirdStar = find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byIcon(Icons.star),
          )
          .at(2);
      await tester.tapAt(tester.getCenter(thirdStar) + const Offset(10, 0));
      await tester.pump();
      expect(_isEnabled(tester, confirm), isTrue);
      expect(find.text('다시 선택하기'), findsOneWidget);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('내 평점 3.0'), findsOneWidget);
    });

    testWidgets('다시 선택하기를 누르면 평점이 초기화된다', (tester) async {
      await _pumpApp(tester, location: '/movies/1');

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();

      final stars = find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.star),
      );
      await tester.tapAt(tester.getCenter(stars.at(3)) + const Offset(10, 0));
      await tester.pump();

      await tester.tap(find.text('다시 선택하기'));
      await tester.pump();

      final confirm = find.widgetWithText(ElevatedButton, '확인');
      expect(_isEnabled(tester, confirm), isFalse);
      expect(find.text('다시 선택하기'), findsNothing);
    });

    testWidgets('없는 영화 ID면 안내 문구를 표시한다', (tester) async {
      await _pumpApp(tester, location: '/movies/999');

      expect(find.text('영화를 찾을 수 없어요.'), findsOneWidget);
    });
  });

  group('6주차 회원가입 중복 확인', () {
    test('중복 응답이면 버튼을 막고, 다른 값으로 바꾸면 다시 확인할 수 있다', () async {
      final service = FakeMemberCheckService();
      final viewModel = SignUpViewModel(service);

      viewModel.onNicknameChanged('영화광');
      await viewModel.checkNickname('영화광');
      expect(viewModel.nickname.status, CheckStatus.duplicated);
      expect(viewModel.nickname.errorText, '이미 사용 중인 닉네임입니다.');
      expect(viewModel.nickname.canCheck, isFalse);

      viewModel.onNicknameChanged('영화광2');
      expect(viewModel.nickname.status, CheckStatus.idle);
      expect(viewModel.nickname.errorText, isNull);
      expect(viewModel.nickname.canCheck, isTrue);
    });

    test('중복이던 문자열을 다시 입력하면 서버에 묻지 않고 바로 에러가 된다', () async {
      final service = FakeMemberCheckService();
      final viewModel = SignUpViewModel(service);

      viewModel.onNicknameChanged('영화광');
      await viewModel.checkNickname('영화광');
      viewModel.onNicknameChanged('영화');
      viewModel.onNicknameChanged(' 영화광 ');

      expect(service.calls, 1);
      expect(viewModel.nickname.status, CheckStatus.duplicated);
      expect(viewModel.nickname.canCheck, isFalse);
    });

    test('확인 중에 입력이 바뀌면 늦게 온 응답을 버린다', () async {
      final service = FakeMemberCheckService()..gate = Completer<void>();
      final viewModel = SignUpViewModel(service);

      viewModel.onEmailChanged('new@umc.com');
      final pending = viewModel.checkEmail('new@umc.com');
      expect(viewModel.email.status, CheckStatus.checking);
      viewModel.onEmailChanged('new2@umc.com');
      service.gate!.complete();
      await pending;

      expect(viewModel.email.status, CheckStatus.idle);
    });

    test('통신 실패는 중복과 다른 문구로 error 상태가 된다', () async {
      final viewModel = SignUpViewModel(FakeMemberCheckService()..fail = true);

      viewModel.onEmailChanged('new@umc.com');
      await viewModel.checkEmail('new@umc.com');

      expect(viewModel.email.status, CheckStatus.error);
      expect(viewModel.email.errorText, '중복 확인에 실패했습니다. 다시 시도해 주세요.');
      expect(viewModel.email.canCheck, isTrue);
    });

    testWidgets('통신 중에는 버튼이 비활성화되고 인디케이터만 보인다', (tester) async {
      final service = FakeMemberCheckService()..gate = Completer<void>();
      await _pumpApp(tester, location: '/register', checkService: service);

      await tester.enterText(_field(0), '새닉네임');
      await tester.pump();
      await tester.tap(find.text('중복 확인').first);
      await tester.pump();

      final button = find.byType(MovieLogButton).first;
      expect(
        find.descendant(
          of: button,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.descendant(
                of: button,
                matching: find.byType(ElevatedButton),
              ),
            )
            .onPressed,
        isNull,
      );

      service.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);
    });

    testWidgets('서버가 중복이라고 하면 입력창이 에러가 되고 버튼이 막힌다', (tester) async {
      await _pumpApp(tester, location: '/register');

      await tester.enterText(_field(1), 'test@umc.com');
      await tester.pump();
      await tester.tap(find.text('중복 확인').at(1));
      await tester.pumpAndSettle();

      expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
      final emailButton = find.byType(MovieLogButton).at(1);
      expect(tester.widget<MovieLogButton>(emailButton).onPressed, isNull);
      expect(_isEnabled(tester, _submitButton), isFalse);
    });
  });

  group('MovieLogButton', () {
    testWidgets('width null·double.infinity·고정값에 따라 너비가 달라진다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  children: [MovieLogButton(label: '확인', onPressed: () {})],
                ),
                MovieLogButton(
                  label: '전체',
                  width: double.infinity,
                  onPressed: () {},
                ),
                MovieLogButton(label: '고정', width: 120, onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      final content = tester.getSize(find.byType(MovieLogButton).at(0)).width;
      final full = tester.getSize(find.byType(MovieLogButton).at(1)).width;
      final fixed = tester.getSize(find.byType(MovieLogButton).at(2)).width;
      expect(content, lessThan(120));
      expect(
        full,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
      expect(fixed, 120);
    });
  });

  group('6주차 내가 등록한 평점', () {
    test('평점과 TMDB 영화를 묶고, 못 찾은 영화는 안내 문구와 함께 남긴다', () async {
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(ratings: [_rating(2, 1), _rating(1, 999)]),
        _defaultService(),
        sampleMemberId,
      );

      await viewModel.load();

      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.ratings.first.movie?.title, '영화 1');
      expect(viewModel.ratings.last.movie, isNull);
      expect(viewModel.message, contains('일부 영화 정보'));
    });

    test('영화 상세 조회가 실패해도 평점 목록은 남긴다', () async {
      final tmdb = _defaultService()..failMovieDetail = true;
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(ratings: [_rating(1, 1)]),
        tmdb,
        sampleMemberId,
      );

      await viewModel.load();

      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.ratings, hasLength(1));
    });

    test('빈 배열은 Empty, 404·400은 서로 다른 Error 문구', () async {
      final empty = MyRatingsViewModel(
        FakeRatingApiService(),
        _defaultService(),
        sampleMemberId,
      );
      await empty.load();
      expect(empty.status, MyRatingsLoadStatus.empty);

      final notFound = MyRatingsViewModel(
        FakeRatingApiService()..failStatus = 404,
        _defaultService(),
        sampleMemberId,
      );
      await notFound.load();
      expect(notFound.status, MyRatingsLoadStatus.error);
      expect(notFound.message, '존재하지 않는 회원입니다.');

      final badRequest = MyRatingsViewModel(
        FakeRatingApiService()..failStatus = 400,
        _defaultService(),
        sampleMemberId,
      );
      await badRequest.load();
      expect(badRequest.message, 'memberId 형식을 다시 확인해 주세요.');
    });

    testWidgets('마이페이지에서 진입하면 하단 탭 없이 평점 카드를 보여준다', (tester) async {
      await _pumpApp(
        tester,
        location: '/my',
        size: const Size(390, 1600),
        ratingService: FakeRatingApiService(
          ratings: [
            _rating(2, 1, comment: '다시 봐도 좋다'),
            _rating(1, 2, comment: null),
          ],
        ),
      );

      await tester.tap(find.text('내가 등록한 평점'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('영화 1'), findsOneWidget);
      expect(find.text('다시 봐도 좋다'), findsOneWidget);
      expect(find.text('2026.11.15 등록'), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
