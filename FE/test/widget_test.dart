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
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movies/genre_filter_sheet.dart';
import 'package:movielog/screens/sign_up/sign_up_validators.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/data/models/favorite_models.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/screens/login/login_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
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

  /// 이 page 번호의 discover만 실패시킵니다.
  final failDiscoverPages = <int>{};
  int? totalPagesOverride;

  /// 검색어별 page 결과. 없는 검색어는 빈 결과입니다.
  Map<String, Map<int, List<TmdbMovieDto>>> searchPages = {};
  bool failSearch = false;
  final searchGates = <String, Completer<void>>{};
  final searchCalls = <({int page, String query})>[];

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
    if (failDiscover || failDiscoverPages.contains(page)) throw _networkError();

    final selected = genreIds;
    final results = (pages[page] ?? const <TmdbMovieDto>[])
        .where(
          (movie) => selected == null || movie.genreIds.any(selected.contains),
        )
        .toList();
    return TmdbMoviePageDto(
      page: page,
      results: results,
      totalPages: totalPagesOverride ?? pages.length,
      totalResults: results.length,
    );
  }

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required int page,
    required String query,
  }) async {
    searchCalls.add((page: page, query: query));
    await searchGates[query]?.future;
    if (failSearch) throw _networkError();
    final byPage = searchPages[query] ?? const <int, List<TmdbMovieDto>>{};
    final results = byPage[page] ?? const <TmdbMovieDto>[];
    return TmdbMoviePageDto(
      page: page,
      results: results,
      totalPages: byPage.length,
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

/// v6 공통 오류 응답(DioException)을 만듭니다.
DioException _apiError(int status, String code, String message) {
  final options = RequestOptions(path: '/v6');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {
        'isSuccess': false,
        'code': code,
        'message': message,
        'result': null,
      },
    ),
    type: DioExceptionType.badResponse,
  );
}

/// 워크북 v6 중복 확인·회원가입 응답을 흉내 냅니다.
class FakeSignUpService extends SignUpService {
  FakeSignUpService() : super(Dio());

  final takenNicknames = {'영화광', 'test'};
  final takenEmails = {'test@umc.com', 'movie@umc.com'};
  bool fail = false;
  Completer<void>? gate;
  int calls = 0;

  /// 설정하면 signUp이 이 오류로 실패합니다.
  DioException? signUpError;
  Completer<void>? signUpGate;
  final signUpRequests = <Map<String, dynamic>>[];

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

  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    signUpRequests.add(request.toJson());
    await signUpGate?.future;
    final error = signUpError;
    if (error != null) throw error;
    return CommonResponse(
      isSuccess: true,
      code: 'COMMON201',
      message: '회원가입에 성공했습니다.',
      result: SignUpResult(
        memberId: 42,
        email: request.email,
        nickname: request.nickname,
      ),
    );
  }
}

/// v7 평점 쓰기 응답을 메모리 목록으로 흉내 냅니다.
class FakeRatingApiService extends RatingApiService {
  FakeRatingApiService() : super(Dio(), Dio());

  /// 설정하면 다음 쓰기 요청이 이 오류로 실패합니다.
  DioException? writeError;

  /// 이 ratingId의 DELETE만 실패시킵니다(값: 오류).
  final failDeleteIds = <int, DioException>{};
  Completer<void>? writeGate;
  int _nextId = 100;

  final created = <Map<String, dynamic>>[];
  final movieRecords = <Map<String, dynamic>>[];
  void Function(int movieId)? onMovieRecord;
  final updated = <({int ratingId, int score, String? comment})>[];
  final deleted = <int>[];

  Future<void> _write() async {
    await writeGate?.future;
    final error = writeError;
    writeError = null;
    if (error != null) throw error;
  }

  @override
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    await _write();
    final json = request.toJson();
    created.add(json);
    return _rating(
      _nextId++,
      json['movieId'] as int,
      score: json['score'] as int,
      comment: json['comment'] as String?,
    );
  }

  @override
  Future<RatingDto> createMovieRecord({
    required CreateRatingRequest request,
    required bool addToFavorites,
  }) async {
    await _write();
    final json = {...request.toJson(), 'addToFavorites': addToFavorites};
    movieRecords.add(json);
    onMovieRecord?.call(json['movieId'] as int);
    return _rating(
      _nextId++,
      json['movieId'] as int,
      score: json['score'] as int,
    );
  }

  @override
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _write();
    updated.add((ratingId: ratingId, score: score, comment: comment));
    return _rating(ratingId, 1, score: score, comment: comment);
  }

  @override
  Future<void> deleteRating(int ratingId) async {
    await _write();
    final error = failDeleteIds[ratingId];
    if (error != null) throw error;
    deleted.add(ratingId);
  }
}

/// v8 즐겨찾기를 메모리 Set으로 흉내 냅니다.
class FakeFavoriteApiService extends FavoriteApiService {
  FakeFavoriteApiService([Iterable<int> movieIds = const []])
    : favorites = {...movieIds},
      super(Dio());

  final Set<int> favorites;
  DioException? addError;
  DioException? deleteError;
  DioException? checkError;
  DioException? listError;
  Completer<void>? saveGate;
  int addCalls = 0;

  FavoriteResponseDto _dto(int movieId) => FavoriteResponseDto(
    favoriteId: movieId,
    movieId: movieId,
    createdAt: DateTime(2026, 11, 18),
  );

  @override
  Future<FavoriteResponseDto> addFavorite(int movieId) async {
    addCalls++;
    await saveGate?.future;
    final error = addError;
    if (error != null) throw error;
    favorites.add(movieId);
    return _dto(movieId);
  }

  @override
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final error = listError;
    if (error != null) throw error;
    return [for (final id in favorites.toList().reversed) _dto(id)];
  }

  @override
  Future<bool> checkFavorite(int movieId) async {
    final error = checkError;
    if (error != null) throw error;
    return favorites.contains(movieId);
  }

  @override
  Future<void> deleteFavorite(int movieId) async {
    await saveGate?.future;
    final error = deleteError;
    if (error != null) throw error;
    favorites.remove(movieId);
  }
}

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.token]);

  String? token;
  bool failRead = false;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw StateError('읽기 실패');
    return token;
  }

  @override
  Future<void> deleteAccessToken() async => token = null;
}

class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService() : super(Dio());

  DioException? error;
  final requests = <Map<String, dynamic>>[];

  @override
  Future<LoginResult> login(LoginRequest request) async {
    requests.add(request.toJson());
    final error = this.error;
    if (error != null) throw error;
    return const LoginResult(nickname: '무비러버', accessToken: 'new-token');
  }
}

MemberInfo _member({String nickname = '무비러버'}) => MemberInfo(
  email: 'movie@example.com',
  nickname: nickname,
  createdAt: DateTime(2026, 10, 10, 12),
);

class FakeMemberApiService extends MemberApiService {
  FakeMemberApiService() : super(Dio());

  MemberInfo member = _member();
  DioException? fetchError;
  DioException? updateError;
  Completer<void>? fetchGate;
  int fetchCalls = 0;
  final nicknameUpdates = <String>[];

  @override
  Future<MemberInfo> fetchMe() async {
    fetchCalls++;
    await fetchGate?.future;
    final error = fetchError;
    if (error != null) throw error;
    return member;
  }

  @override
  Future<MemberInfo> updateNickname(String nickname) async {
    nicknameUpdates.add(nickname);
    final error = updateError;
    if (error != null) throw error;
    return member = _member(nickname: nickname);
  }
}

/// 요청을 보내지 않고 마지막 헤더만 기록합니다.
class _CaptureAdapter implements HttpClientAdapter {
  Map<String, dynamic> lastHeaders = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastHeaders = Map.of(options.headers);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioException _authError(String code) => _apiError(401, code, '인증 오류');

/// 저장된 토큰으로 restoreSession까지 마친 AuthViewModel을 만듭니다.
Future<AuthViewModel> _auth({
  bool signedIn = true,
  FakeMemberApiService? memberApi,
  FakeAuthApiService? authApi,
  MemoryTokenStorage? storage,
}) async {
  final auth = AuthViewModel(
    authApi ?? FakeAuthApiService(),
    memberApi ?? FakeMemberApiService(),
    storage ?? MemoryTokenStorage(signedIn ? 'stored-token' : null),
  );
  await auth.restoreSession();
  return auth;
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
  String location = '/home',
  Size size = const Size(390, 844),
  FakeTmdbMovieService? service,
  FakeSignUpService? checkService,
  FakeRatingApiService? ratingService,
  FakeMemberApiService? memberApi,
  FakeFavoriteApiService? favoriteApi,
  AuthViewModel? auth,
  bool signedIn = true,
  GenrePreference? preference,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final members = memberApi ?? FakeMemberApiService();
  final session = auth ?? await _auth(signedIn: signedIn, memberApi: members);
  final fake = service ?? _defaultService();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TmdbMovieService>.value(value: fake),
        Provider<SignUpService>.value(
          value: checkService ?? FakeSignUpService(),
        ),
        Provider<RatingApiService>.value(
          value: ratingService ?? FakeRatingApiService(),
        ),
        Provider<MemberApiService>.value(value: members),
        Provider<FavoriteApiService>.value(
          value: favoriteApi ?? FakeFavoriteApiService(),
        ),
        ChangeNotifierProvider<AuthViewModel>.value(value: session),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: AppRouter.createRouter(
          auth: session,
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
  await tester.enterText(_field(2), 'Password1!');
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
      await _pumpApp(tester, location: '/register', signedIn: false);

      expect(find.text('회원가입'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(_isEnabled(tester, _submitButton), isFalse);
    });

    testWidgets('잘못된 입력에는 한국어 오류 메시지를 표시한다', (tester) async {
      await _pumpApp(tester, location: '/register', signedIn: false);

      await tester.enterText(_field(0), 'a');
      await tester.enterText(_field(1), 'test@');
      await tester.enterText(_field(2), '123');
      await tester.pump();

      expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
      expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
      expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
      expect(_isEnabled(tester, _submitButton), isFalse);
    });

    testWidgets('v7 가입 성공 시 로그인 화면으로 이동한다', (tester) async {
      final signUp = FakeSignUpService();
      await _pumpApp(
        tester,
        location: '/register',
        signedIn: false,
        checkService: signUp,
      );

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

      expect(signUp.signUpRequests.single, {
        'email': 'movie@example.com',
        'password': 'Password1!',
        'nickname': '무비러버',
      });
      expect(find.text('회원가입이 완료되었습니다. 로그인해 주세요.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('비밀번호 400은 입력칸 에러, 409는 Snackbar로 나눠 보여준다', (tester) async {
      final signUp = FakeSignUpService();
      await _pumpApp(
        tester,
        location: '/register',
        signedIn: false,
        checkService: signUp,
      );
      await _fillValidSignUp(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('중복 확인').at(0));
      await tester.tap(find.text('중복 확인').at(1));
      await tester.pumpAndSettle();

      const passwordMessage = '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.';
      signUp.signUpError = _apiError(400, 'COMMON400', passwordMessage);
      await tester.tap(_submitButton);
      await tester.pumpAndSettle();
      expect(find.text(passwordMessage), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      // 비밀번호를 고치면 서버 에러가 사라집니다.
      await tester.enterText(_field(2), 'Password2!');
      await tester.pump();
      expect(find.text(passwordMessage), findsNothing);

      signUp.signUpError = _apiError(409, 'COMMON409', '이미 사용 중인 이메일입니다.');
      await tester.tap(_submitButton);
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('회원가입'), findsOneWidget);
    });

    testWidgets('제출 중에는 가입 버튼이 로딩이고 뒤로가기로 나갈 수 없다', (tester) async {
      final signUp = FakeSignUpService()..signUpGate = Completer<void>();
      await _pumpApp(
        tester,
        location: '/login',
        signedIn: false,
        checkService: signUp,
      );
      await tester.tap(find.widgetWithText(TextButton, '회원가입'));
      await tester.pumpAndSettle();
      await _fillValidSignUp(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('중복 확인').at(0));
      await tester.tap(find.text('중복 확인').at(1));
      await tester.pumpAndSettle();

      await tester.tap(_submitButton);
      await tester.pump();
      expect(_isEnabled(tester, _submitButton), isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('가입하기'), findsOneWidget);

      signUp.signUpError = _apiError(409, 'COMMON409', '이미 사용 중인 닉네임입니다.');
      signUp.signUpGate!.complete();
      await tester.pumpAndSettle();

      // 제출이 끝나면 다시 나갈 수 있습니다.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('가입하기'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('비밀번호 표시 버튼으로 obscureText를 전환한다', (tester) async {
      await _pumpApp(tester, location: '/register', signedIn: false);

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
      await _pumpApp(tester, location: '/register', signedIn: false);

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
        signedIn: false,
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

  group('9주차 PagedMoviesViewModel', () {
    Map<int, List<TmdbMovieDto>> threePages() => {
      1: [for (var id = 1; id <= 20; id++) _movie(id)],
      // 15~20은 앞 page와 중복입니다.
      2: [for (var id = 15; id <= 34; id++) _movie(id)],
      3: [_movie(35)],
    };

    test('첫 page만 불러오고 더 보기마다 중복 없이 다음 page를 붙인다', () async {
      final service = FakeTmdbMovieService(pages: threePages());
      final viewModel = MovieListViewModel(service, InMemoryGenrePreference());

      await viewModel.start();
      expect(viewModel.phase, LoadPhase.ready);
      expect(viewModel.movies, hasLength(20));
      expect(service.discoverCalls.map((c) => c.page), [1]);

      await viewModel.loadNextPage();
      expect(viewModel.movies, hasLength(34));
      expect(viewModel.movies.map((m) => m.id).toSet(), hasLength(34));

      await viewModel.loadNextPage();
      expect(viewModel.hasMore, isFalse);
      await viewModel.loadNextPage(); // 마지막 page 뒤에는 요청하지 않습니다.
      expect(service.discoverCalls.map((c) => c.page), [1, 2, 3]);
    });

    test('다음 page가 실패하면 목록과 nextPage를 유지하고 같은 page를 다시 요청한다', () async {
      final service = FakeTmdbMovieService(pages: threePages());
      final viewModel = MovieListViewModel(service, InMemoryGenrePreference());
      await viewModel.start();

      service.failDiscover = true;
      await viewModel.loadNextPage();
      expect(viewModel.movies, hasLength(20));
      expect(viewModel.nextPage, 2);
      expect(viewModel.loadMoreError, isNotNull);
      expect(viewModel.isLoadingMore, isFalse);

      service.failDiscover = false;
      await viewModel.loadNextPage();
      expect(service.discoverCalls.last.page, 2);
      expect(viewModel.loadMoreError, isNull);
      expect(viewModel.movies, hasLength(34));
    });

    test('TMDB total_pages가 500보다 커도 500까지만 조회한다', () async {
      final service = FakeTmdbMovieService(
        pages: {
          1: [_movie(1)],
        },
      )..totalPagesOverride = 900;
      final viewModel = PagedMoviesViewModel(tmdbApi: service);
      await viewModel.loadInitial();
      expect(viewModel.totalPages, 500);
    });

    test('장르를 바꾸면 목록·page를 비우고 이전 장르의 늦은 응답은 버린다', () async {
      final service = _defaultService();
      final preference = InMemoryGenrePreference();
      final viewModel = MovieListViewModel(service, preference);
      await viewModel.start();

      service.discoverGate = Completer<void>();
      final slow = viewModel.loadInitial(genreIds: [28]);
      expect(viewModel.movies, isEmpty);
      final gate = service.discoverGate!;
      service.discoverGate = null;
      await viewModel.loadInitial(genreIds: [878]); // 새 조건이 먼저 끝남
      gate.complete();
      await slow;

      expect(viewModel.movies.single.title, '우주 영화');
      expect(viewModel.nextPage, 2);
    });

    test('장르 선택은 Genre API 순서로 OR 조건을 보내고 저장한다', () async {
      final service = _defaultService();
      final preference = InMemoryGenrePreference();
      final viewModel = MovieListViewModel(service, preference);
      await viewModel.start();
      service.discoverCalls.clear();

      await viewModel.selectGenres([878, 28]);
      expect(service.discoverCalls.first.page, 1);
      expect(service.discoverCalls.first.genreIds, [28, 878]);
      expect(preference.saved, [28, 878]);

      await viewModel.selectGenres(const []);
      expect(service.discoverCalls.last.genreIds, isNull);
      expect(viewModel.selectedGenreIds, isNull);
    });

    test('저장된 장르를 복원하고, 장르 저장 실패는 목록 조회를 막지 않는다', () async {
      final service = _defaultService();
      final restored = MovieListViewModel(
        service,
        InMemoryGenrePreference([878, 9999]),
      );
      await restored.start();
      expect(restored.selectedGenreIds, [878]);
      expect(restored.movies.single.title, '우주 영화');

      final throwing = MovieListViewModel(
        _defaultService(),
        _ThrowingGenrePreference(),
      );
      await throwing.start();
      await throwing.selectGenres([878]);
      expect(throwing.phase, LoadPhase.ready);
    });

    test('결과가 없으면 empty, 첫 page 실패는 error이고 다시 시도하면 회복한다', () async {
      final empty = MovieListViewModel(
        FakeTmdbMovieService(pages: {1: const []}),
        InMemoryGenrePreference(),
      );
      await empty.start();
      expect(empty.phase, LoadPhase.empty);

      final service = _defaultService()..failDiscover = true;
      final failed = MovieListViewModel(service, InMemoryGenrePreference());
      await failed.start();
      expect(failed.phase, LoadPhase.error);

      service.failDiscover = false;
      await failed.refresh();
      expect(failed.phase, LoadPhase.ready);
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

      expect(find.widgetWithText(FilterChip, '액션'), findsOneWidget);
      expect(find.text('영화 1'), findsOneWidget);
      expect(service.discoverCalls.first.genreIds, isNull);
    });
  });

  group('화면 전환', () {
    testWidgets('로그인 화면의 회원가입 버튼으로 가입 화면을 연다', (tester) async {
      await _pumpApp(tester, location: '/login', signedIn: false);

      await tester.tap(find.widgetWithText(TextButton, '회원가입'));
      await tester.pumpAndSettle();

      expect(find.text('가입하기'), findsOneWidget);
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
      expect(find.byType(CustomScrollView), findsOneWidget);
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
      expect(find.byType(CustomScrollView), findsOneWidget);
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

    testWidgets('스크롤 끝에서 다음 page를 붙이고, 실패하면 같은 page 재시도 버튼을 보여준다', (
      tester,
    ) async {
      final service = FakeTmdbMovieService(
        pages: {
          1: [for (var id = 1; id <= 20; id++) _movie(id)],
          2: [for (var id = 21; id <= 40; id++) _movie(id)],
        },
      )..failDiscoverPages.add(2);
      await _pumpApp(tester, location: '/movies', service: service);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -6000),
        3000,
      );
      await tester.pumpAndSettle();
      expect(find.text('다음 페이지를 불러오지 못했습니다.'), findsOneWidget);
      expect(find.text('영화 1'), findsNothing); // 기존 카드는 그대로(스크롤 위쪽)

      service.failDiscoverPages.clear();
      await tester.tap(find.text('다음 페이지 다시 시도'));
      await tester.pumpAndSettle();
      expect(service.discoverCalls.map((c) => c.page), [1, 2, 2]);
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -6000),
        3000,
      );
      await tester.pumpAndSettle();
      expect(find.text('더 이상 조회할 페이지가 없습니다.'), findsOneWidget);
    });
  });

  group('MovieDetailScreen', () {
    testWidgets('북마크는 서버 여부로 시작하고, 등록 성공을 확인한 뒤 바뀐다', (tester) async {
      final favorites = FakeFavoriteApiService();
      await _pumpApp(tester, location: '/movies/1', favoriteApi: favorites);

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      favorites.saveGate = Completer<void>();
      await tester.tap(find.byTooltip('즐겨찾기 추가'));
      await tester.pump();
      // 요청 중에는 북마크 자리에만 인디케이터, 아이콘은 아직 바꾸지 않습니다.
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
      expect(find.byIcon(Icons.bookmark), findsNothing);

      favorites.saveGate!.complete();
      favorites.saveGate = null;
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
      expect(favorites.favorites, {1});

      await tester.tap(find.byTooltip('즐겨찾기 해제'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.text('즐겨찾기에서 삭제했습니다.'), findsOneWidget);
    });

    testWidgets('정수 별점과 코멘트를 TMDB id로 v7 등록하고 result로 화면을 갱신한다', (
      tester,
    ) async {
      final ratings = FakeRatingApiService();
      await _pumpApp(tester, location: '/movies/1', ratingService: ratings);

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

      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        ),
        '  재밌어요  ',
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(ratings.created.single, {
        'movieId': 1,
        'score': 3,
        'comment': '재밌어요',
      });
      expect(find.text('내 평점 3점'), findsOneWidget);
      expect(find.text('평점을 저장했습니다.'), findsOneWidget);
    });

    testWidgets('등록 409면 Dialog를 유지하고 서버 문구를 보여준다', (tester) async {
      final ratings = FakeRatingApiService()
        ..writeError = _apiError(409, 'COMMON409', '이미 이 영화에 평점을 남기셨습니다.');
      await _pumpApp(tester, location: '/movies/1', ratingService: ratings);

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      final star = find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byIcon(Icons.star),
          )
          .at(4);
      await tester.tapAt(tester.getCenter(star) + const Offset(10, 0));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
      // 실패 후 로딩이 풀려 다시 시도할 수 있습니다.
      expect(
        _isEnabled(tester, find.widgetWithText(ElevatedButton, '확인')),
        isTrue,
      );
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
      final service = FakeSignUpService();
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
      final service = FakeSignUpService();
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
      final service = FakeSignUpService()..gate = Completer<void>();
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
      final viewModel = SignUpViewModel(FakeSignUpService()..fail = true);

      viewModel.onEmailChanged('new@umc.com');
      await viewModel.checkEmail('new@umc.com');

      expect(viewModel.email.status, CheckStatus.error);
      expect(viewModel.email.errorText, '중복 확인에 실패했습니다. 다시 시도해 주세요.');
      expect(viewModel.email.canCheck, isTrue);
    });

    testWidgets('통신 중에는 버튼이 비활성화되고 인디케이터만 보인다', (tester) async {
      final service = FakeSignUpService()..gate = Completer<void>();
      await _pumpApp(
        tester,
        location: '/register',
        signedIn: false,
        checkService: service,
      );

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
      await _pumpApp(tester, location: '/register', signedIn: false);

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

  group('8주차 인증 상태', () {
    test('authRedirect는 상태별로 스플래시·로그인·홈만 허용한다', () {
      expect(authRedirect(AuthStatus.initializing, '/home'), '/start');
      expect(authRedirect(AuthStatus.retryRequired, '/start'), isNull);
      expect(authRedirect(AuthStatus.signedOut, '/my'), '/login');
      expect(authRedirect(AuthStatus.signedOut, '/register'), isNull);
      expect(authRedirect(AuthStatus.authenticating, '/login'), isNull);
      expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/my/ratings'), isNull);
    });

    test('저장된 토큰은 GET me 검증 뒤에만 signedIn이 된다', () async {
      final members = FakeMemberApiService();
      final auth = await _auth(memberApi: members);

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, '무비러버');
      expect(members.fetchCalls, 1);

      final empty = await _auth(signedIn: false);
      expect(empty.status, AuthStatus.signedOut);
    });

    test('네트워크 실패는 재시도 상태로 두고 토큰을 지우지 않는다', () async {
      final storage = MemoryTokenStorage('stored-token');
      final auth = await _auth(
        storage: storage,
        memberApi: FakeMemberApiService()..fetchError = _networkError(),
      );

      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'stored-token');

      final broken = MemoryTokenStorage('x')..failRead = true;
      final failed = await _auth(storage: broken);
      expect(failed.status, AuthStatus.retryRequired);
      expect(failed.message, contains('인증 저장소'));
    });

    test('만료 토큰(AUTH401_4)이면 토큰을 지우고 만료 안내를 켠다', () async {
      final storage = MemoryTokenStorage('old-token');
      final auth = await _auth(
        storage: storage,
        memberApi: FakeMemberApiService()..fetchError = _authError('AUTH401_4'),
      );

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
    });

    test('로그인 실패 AUTH401_1은 Form 오류이고 만료가 아니다', () async {
      final authApi = FakeAuthApiService()..error = _authError('AUTH401_1');
      final storage = MemoryTokenStorage();
      final auth = await _auth(
        signedIn: false,
        authApi: authApi,
        storage: storage,
      );

      await auth.login('movie@example.com', 'wrong');

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, '이메일 또는 비밀번호를 확인해 주세요.');
      expect(auth.sessionExpired, isFalse);
      expect(storage.token, isNull);

      authApi.error = null;
      await auth.login('movie@example.com', 'Password1!');
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'new-token');
    });

    test('로그아웃 뒤 늦게 도착한 GET me는 반영하지 않는다', () async {
      final members = FakeMemberApiService();
      final auth = await _auth(signedIn: false, memberApi: members);
      await auth.login('movie@example.com', 'Password1!');

      members.fetchGate = Completer<void>();
      final loading = auth.loadMember();
      await auth.logout();
      members.fetchGate!.complete();
      await loading;

      expect(auth.member, isNull);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isFalse);
    });
  });

  group('8주차 AuthInterceptor', () {
    Future<Map<String, dynamic>> headersFor(
      String url, {
      String method = 'GET',
      TokenStorage? storage,
    }) async {
      final dio = Dio();
      final adapter = _CaptureAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(
          storage ?? MemoryTokenStorage('secret-jwt'),
          host: 'workbook.devnoco.com',
        ),
      );
      await dio.request(
        url,
        options: Options(method: method, headers: {'Authorization': 'old'}),
      );
      return adapter.lastHeaders;
    }

    test('워크북 보호 path에만 Bearer를 붙이고 다른 host·공개 path에는 붙이지 않는다', () async {
      expect(
        (await headersFor(
          'https://workbook.devnoco.com/v8/ratings/3',
        ))['Authorization'],
        'Bearer secret-jwt',
      );
      expect(
        (await headersFor(
          'https://workbook.devnoco.com/v8/members/me',
        ))['Authorization'],
        'Bearer secret-jwt',
      );
      expect(
        (await headersFor(
          'https://workbook.devnoco.com/v8/members/1/ratings',
        ))['Authorization'],
        isNull,
      );
      expect(
        (await headersFor(
          'https://api.themoviedb.org/v8/ratings',
        ))['Authorization'],
        isNull,
      );
    });

    test('9주차 즐겨찾기·영화 기록은 정해진 method에만 Bearer를 붙인다', () async {
      Future<Object?> auth(String path, String method) async =>
          (await headersFor(
            'https://workbook.devnoco.com$path',
            method: method,
          ))['Authorization'];

      expect(await auth('/v8/favorites', 'GET'), 'Bearer secret-jwt');
      expect(await auth('/v8/favorites', 'POST'), 'Bearer secret-jwt');
      expect(await auth('/v8/favorites/550', 'GET'), 'Bearer secret-jwt');
      expect(await auth('/v8/favorites/550', 'DELETE'), 'Bearer secret-jwt');
      expect(await auth('/v8/movie-records', 'POST'), 'Bearer secret-jwt');
      expect(await auth('/v8/favorites/550', 'PATCH'), isNull);
      expect(await auth('/v8/favorites/abc', 'GET'), isNull);
      expect(await auth('/v8/members/nickname/a', 'GET'), isNull);
    });

    test('저장소를 못 읽으면 서버 401이 아닌 다른 오류로 거절한다', () async {
      await expectLater(
        headersFor(
          'https://workbook.devnoco.com/v8/ratings',
          storage: MemoryTokenStorage('x')..failRead = true,
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.unknown,
          ),
        ),
      );
    });
  });

  group('8주차 로그인·세션 화면', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    testWidgets('세션 확인 실패면 스플래시에서 다시 시도해 홈으로 간다', (tester) async {
      final members = FakeMemberApiService()..fetchError = _networkError();
      final auth = await _auth(memberApi: members);
      await _pumpApp(
        tester,
        location: '/start',
        auth: auth,
        memberApi: members,
      );

      expect(find.text('FLUTTER 8주차'), findsOneWidget);
      expect(find.text('로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);

      members.fetchError = null;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text(_homeHeadline), findsOneWidget);
    });

    testWidgets('로그인 실패는 Form 문구, 성공하면 홈으로 이동한다', (tester) async {
      final authApi = FakeAuthApiService()..error = _authError('AUTH401_1');
      final auth = await _auth(signedIn: false, authApi: authApi);
      await _pumpApp(tester, location: '/my', auth: auth);
      expect(find.byType(LoginScreen), findsOneWidget); // 보호 화면 차단

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'movie@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
      await tester.pumpAndSettle();
      expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);

      authApi.error = null;
      await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
      await tester.pumpAndSettle();
      expect(find.text(_homeHeadline), findsOneWidget);
      expect(authApi.requests.last['email'], 'movie@example.com');
    });

    testWidgets('이메일 저장을 켜면 이메일만 저장해 다음에 채운다', (tester) async {
      final auth = await _auth(signedIn: false);
      await _pumpApp(tester, location: '/login', auth: auth);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'movie@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Password1!');
      await tester.tap(find.text('이메일 저장'));
      await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
      await tester.pumpAndSettle();

      final prefs = SharedPreferencesAsyncPlatform.instance!;
      final saved = await prefs.getString(
        LoginScreen.savedEmailKey,
        const SharedPreferencesOptions(),
      );
      expect(saved, 'movie@example.com');
      final all = await prefs.getPreferences(
        const GetPreferencesParameters(filter: PreferencesFilters()),
        const SharedPreferencesOptions(),
      );
      expect(all.values, isNot(contains('Password1!')));

      await auth.logout();
      await tester.pumpAndSettle();
      final emailField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(0),
          matching: find.byType(EditableText),
        ),
      );
      expect(emailField.controller.text, 'movie@example.com');
    });

    testWidgets('마이페이지는 내 정보를 보여주고 로그아웃하면 만료 안내 없이 로그인으로 간다', (tester) async {
      final storage = MemoryTokenStorage('stored-token');
      final auth = await _auth(storage: storage);
      await _pumpApp(
        tester,
        location: '/my',
        auth: auth,
        size: const Size(390, 1400),
      );

      expect(find.text('무비러버'), findsOneWidget);
      expect(find.text('movie@example.com'), findsOneWidget);
      expect(find.text('2026.10.10 가입'), findsOneWidget);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(storage.token, isNull);
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);
    });

    testWidgets('보호 요청 만료면 로그인 화면에서 Snackbar로 한 번 안내한다', (tester) async {
      final auth = await _auth();
      await _pumpApp(tester, location: '/my', auth: auth);

      await auth.expireSession();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
      expect(auth.sessionExpired, isFalse);
    });

    testWidgets('내 정보 로딩 실패면 재시도 버튼을 보여준다', (tester) async {
      final members = FakeMemberApiService();
      final auth = await _auth(signedIn: false, memberApi: members);
      await auth.login('movie@example.com', 'Password1!');
      members.fetchError = _networkError();
      await _pumpApp(tester, location: '/my', auth: auth, memberApi: members);

      expect(find.text('내 정보를 불러오지 못했어요.'), findsOneWidget);
      expect(auth.status, AuthStatus.signedIn); // 네트워크 실패로 로그아웃하지 않음

      members.fetchError = null;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('무비러버'), findsOneWidget);
    });
  });

  group('8주차 프로필 수정', () {
    test('2~12자 검증, 같은 닉네임은 요청 없이 완료, 409는 입력 오류', () async {
      final members = FakeMemberApiService();
      final auth = await _auth(memberApi: members);
      final viewModel = EditProfileViewModel(members, auth);

      expect(await viewModel.save('a'), isFalse);
      expect(viewModel.nicknameError, '닉네임은 2~12자로 입력해 주세요.');
      expect(await viewModel.save(' 무비러버 '), isTrue);
      expect(members.nicknameUpdates, isEmpty);

      members.updateError = _apiError(409, 'MEMBER409_1', '이미 사용 중인 닉네임입니다.');
      expect(await viewModel.save('영화광'), isFalse);
      expect(viewModel.nicknameError, '이미 사용 중인 닉네임이에요.');

      members.updateError = _networkError();
      expect(await viewModel.save('영화광'), isFalse);
      expect(viewModel.message, contains('네트워크'));
      expect(auth.status, AuthStatus.signedIn);

      members.updateError = _authError('AUTH401_3');
      expect(await viewModel.save('영화광'), isFalse);
      expect(auth.status, AuthStatus.signedOut);
    });

    testWidgets('저장하면 마이페이지에 새 닉네임이 바로 보인다', (tester) async {
      final members = FakeMemberApiService();
      await _pumpApp(
        tester,
        location: '/my',
        memberApi: members,
        size: const Size(390, 1400),
      );

      await tester.tap(find.text('프로필 수정'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);

      await tester.enterText(find.byType(TextField).last, '새닉네임');
      await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
      await tester.pumpAndSettle();

      expect(members.nicknameUpdates, ['새닉네임']);
      expect(find.text('프로필을 수정했어요.'), findsOneWidget);
      expect(find.text('새닉네임'), findsOneWidget);
    });

    testWidgets('변경 내용이 있으면 뒤로가기 전에 확인한다', (tester) async {
      await _pumpApp(tester, location: '/my', size: const Size(390, 1400));
      await tester.tap(find.text('프로필 수정'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '바뀐닉네임');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('수정을 취소할까요?'), findsOneWidget);

      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      expect(find.text('바뀐닉네임'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '나가기'));
      await tester.pumpAndSettle();
      expect(find.text('내 프로필'), findsOneWidget);
    });
  });

  group('8주차 v7 평점', () {
    test('정수 1~5만 허용하고 빈 코멘트는 body에서 뺀다', () {
      expect(validateServerScore(3), 3);
      expect(() => validateServerScore(3.5), throwsArgumentError);
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 4,
          comment: '  ',
        ).toJson(),
        {'movieId': 550, 'score': 4},
      );
    });

    test('v7 공통 응답에서 Rating 객체를 읽고 오류 code를 구분한다', () {
      final rating = parseRatingResult({
        'isSuccess': true,
        'code': 'COMMON201',
        'message': '평점을 등록했습니다.',
        'result': {
          'ratingId': 7,
          'movieId': 550,
          'score': 5,
          'comment': null,
          'createdAt': '2026-09-06T12:14:03.000Z',
          'updatedAt': '2026-09-06T12:14:03.000Z',
        },
      });
      expect(rating.ratingId, 7);
      expect(rating.comment, isNull);

      final forbidden = _apiError(
        403,
        'RATING403_1',
        '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      expect(writeErrorMessage(forbidden), '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.');
      expect(isSessionExpiredError(forbidden), isFalse);
      expect(isSessionExpiredError(_authError('AUTH401_2')), isTrue);
      expect(isSessionExpiredError(_authError('AUTH401_1')), isFalse);
    });

    test('수정은 result로 카드를 교체하고, 404는 목록에서 빼고, 403은 로그인을 유지한다', () async {
      final service = FakeRatingApiService();
      final auth = await _auth();
      auth.addSessionRating(_rating(1, 1, score: 2));
      auth.addSessionRating(_rating(2, 2));
      final viewModel = MyRatingsViewModel(service, _defaultService(), auth);
      await viewModel.load();

      await viewModel.updateRating(ratingId: 1, score: 5, comment: null);
      expect(service.updated.single, (ratingId: 1, score: 5, comment: null));
      expect(
        viewModel.ratings
            .firstWhere((e) => e.rating.ratingId == 1)
            .rating
            .score,
        5,
      );

      service.writeError = _apiError(
        403,
        'RATING403_1',
        '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      await expectLater(
        viewModel.deleteRating(2),
        throwsA(isA<DioException>()),
      );
      expect(auth.status, AuthStatus.signedIn);
      expect(viewModel.ratings, hasLength(2));

      service.writeError = _apiError(404, 'RATING404_1', '해당 평점을 찾을 수 없습니다.');
      await expectLater(
        viewModel.deleteRating(2),
        throwsA(isA<DioException>()),
      );
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [1]);
    });

    test('다중 삭제 중 일부만 실패하면 실패한 항목만 선택에 남긴다', () async {
      final service = FakeRatingApiService()
        ..failDeleteIds[2] = _apiError(403, 'RATING403_1', '권한 없음');
      final auth = await _auth();
      for (final id in [1, 2, 3]) {
        auth.addSessionRating(_rating(id, 1));
      }
      final viewModel = MyRatingsViewModel(service, _defaultService(), auth);
      await viewModel.load();

      viewModel.startEditing();
      viewModel.toggleSelected(3);
      viewModel.toggleSelected(2);
      await viewModel.deleteSelectedRatings();

      expect(service.deleted, [3]);
      expect(viewModel.selectedRatingIds, {2});
      expect(viewModel.isEditing, isTrue);
      expect(viewModel.message, contains('1개 항목을 삭제하지 못했습니다'));
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [2, 1]);
    });

    testWidgets('등록 401이면 세션을 정리하고 로그인 화면으로 보낸다', (tester) async {
      final ratings = FakeRatingApiService()
        ..writeError = _authError('AUTH401_4');
      await _pumpApp(tester, location: '/movies/1', ratingService: ratings);

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      final star = find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byIcon(Icons.star),
          )
          .at(4);
      await tester.tapAt(tester.getCenter(star) + const Offset(10, 0));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    });

    testWidgets('상세에서 등록한 평점을 내가 등록한 평점에서 수정·삭제한다', (tester) async {
      final ratings = FakeRatingApiService();
      final auth = await _auth();
      auth.addSessionRating(_rating(9, 999, comment: '처음 감상', score: 2));
      await _pumpApp(
        tester,
        location: '/my/ratings',
        auth: auth,
        ratingService: ratings,
        size: const Size(390, 1600),
      );

      // TMDB에 없는 영화도 평점은 남기고 placeholder로 표시합니다.
      expect(find.text('영화 정보를 찾을 수 없어요'), findsOneWidget);
      expect(find.text('이번 로그인에서 등록한 평점 1개'), findsOneWidget);

      await tester.tap(find.byTooltip('수정'));
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(field).controller!.text, '처음 감상');
      await tester.enterText(field, '다시 보니 좋다');
      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();
      expect(ratings.updated.single, (
        ratingId: 9,
        score: 2,
        comment: '다시 보니 좋다',
      ));
      expect(find.text('다시 보니 좋다'), findsOneWidget);

      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(ratings.deleted, isEmpty);

      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '삭제'));
      await tester.pumpAndSettle();
      expect(ratings.deleted, [9]);
      expect(find.textContaining('이번 로그인에서 등록한 평점이 없어요'), findsOneWidget);
    });

    testWidgets('편집 모드에서 선택한 평점을 오버레이와 함께 한 번에 삭제한다', (tester) async {
      final ratings = FakeRatingApiService();
      final auth = await _auth();
      auth.addSessionRating(_rating(1, 2, comment: '하나'));
      auth.addSessionRating(_rating(2, 1, comment: '둘'));
      await _pumpApp(
        tester,
        location: '/my/ratings',
        auth: auth,
        ratingService: ratings,
        size: const Size(390, 1600),
      );

      await tester.tap(find.text('편집'));
      await tester.pumpAndSettle();
      expect(find.text('0개 선택'), findsOneWidget);
      expect(
        _isEnabled(tester, find.widgetWithText(ElevatedButton, '선택한 0개 삭제')),
        isFalse,
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();

      ratings.writeGate = Completer<void>();
      await tester.tap(find.widgetWithText(ElevatedButton, '선택한 2개 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '삭제'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ModalBarrier), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('내가 등록한 평점'), findsOneWidget);

      ratings.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(ratings.deleted, [2, 1]);
      expect(auth.sessionRatings, isEmpty);
    });
  });

  group('9주차 내 즐겨찾기', () {
    test('mapBounded는 동시에 최대 N개만 실행하고 입력 순서를 지킨다', () async {
      var running = 0;
      var peak = 0;
      final result = await mapBounded([1, 2, 3, 4, 5, 6, 7], 3, (n) async {
        running++;
        peak = running > peak ? running : peak;
        await Future<void>.delayed(Duration.zero);
        running--;
        return n * 10;
      });
      expect(result, [10, 20, 30, 40, 50, 60, 70]);
      expect(peak, 3);
    });

    test('409·404는 POST/DELETE를 반복하지 않고 서버 여부로 맞춘다', () async {
      final favorites = FakeFavoriteApiService([550])
        ..addError = _apiError(409, 'FAVORITE409_1', '이미 즐겨찾기');
      final auth = await _auth();
      final viewModel = FavoriteDetailViewModel(
        movieId: 550,
        favoriteApi: favorites,
        auth: auth,
      );
      // 화면은 아직 등록 전이라고 알고 있는 상황(다른 기기에서 등록됨)을 만듭니다.
      await viewModel.load();
      favorites.favorites.clear();
      viewModel.isFavorite = false;
      favorites.favorites.add(550);

      await viewModel.toggle();
      expect(favorites.addCalls, 1);
      expect(viewModel.isFavorite, isTrue);
      expect(viewModel.errorMessage, isNull);

      favorites.deleteError = _networkError();
      await viewModel.toggle();
      expect(viewModel.isFavorite, isTrue); // 실패하면 이전 상태 유지
      expect(viewModel.errorMessage, '즐겨찾기 해제에 실패했습니다.');
    });

    test('즐겨찾기 401(AUTH401_4)은 세션을 정리하고, 로그아웃 뒤 늦은 응답은 버린다', () async {
      final favorites = FakeFavoriteApiService()
        ..checkError = _authError('AUTH401_4');
      final auth = await _auth();
      final viewModel = FavoriteDetailViewModel(
        movieId: 1,
        favoriteApi: favorites,
        auth: auth,
      );
      await viewModel.load();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);

      final auth2 = await _auth();
      final late = FavoritesViewModel(
        favoriteApi: FakeFavoriteApiService([1]),
        tmdbApi: _defaultService(),
        auth: auth2,
      );
      final pending = late.refresh();
      await auth2.logout();
      await pending;
      expect(late.items, isEmpty);
    });

    test('영화 정보 한 건만 실패하면 그 카드만 placeholder로 두고 재조회한다', () async {
      final tmdb = _defaultService();
      final viewModel = FavoritesViewModel(
        favoriteApi: FakeFavoriteApiService([1, 999]),
        tmdbApi: tmdb,
        auth: await _auth(),
      );
      await viewModel.refresh();
      expect(viewModel.phase, LoadPhase.ready);
      expect(viewModel.items.map((i) => i.movie?.title), [null, '영화 1']);

      tmdb.popular = [...tmdb.popular, _movie(999, title: '복구된 영화')];
      await viewModel.retryMovie(999);
      expect(viewModel.items.first.movie?.title, '복구된 영화');
    });

    testWidgets('마이페이지 → 내 즐겨찾기 → 상세 해제 → 뒤로가기하면 목록이 갱신된다', (tester) async {
      final favorites = FakeFavoriteApiService([1, 2]);
      await _pumpApp(
        tester,
        location: '/my',
        favoriteApi: favorites,
        size: const Size(390, 1600),
      );

      await tester.tap(find.text('내 즐겨찾기'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('영화 1'), findsOneWidget);
      expect(find.text('영화 2'), findsOneWidget);

      await tester.tap(find.text('영화 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('즐겨찾기 해제'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('영화 1'), findsNothing);
      expect(find.text('영화 2'), findsOneWidget);
    });

    testWidgets('빈 목록과 조회 오류를 서로 다른 화면으로 보여준다', (tester) async {
      final favorites = FakeFavoriteApiService()..listError = _networkError();
      await _pumpApp(tester, location: '/my/favorites', favoriteApi: favorites);
      expect(find.text('내 즐겨찾기 목록을 불러오지 못했습니다.'), findsOneWidget);

      favorites.listError = null;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('아직 즐겨찾기한 영화가 없습니다.'), findsOneWidget);
    });

    testWidgets('로그아웃 후 다른 계정으로 로그인하면 이전 계정 즐겨찾기가 보이지 않는다', (tester) async {
      final favorites = FakeFavoriteApiService([1]);
      final members = FakeMemberApiService();
      final auth = await _auth(memberApi: members);
      await _pumpApp(
        tester,
        location: '/my/favorites',
        auth: auth,
        memberApi: members,
        favoriteApi: favorites,
      );
      expect(find.text('영화 1'), findsOneWidget);

      await auth.logout();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // 다른 계정(B)의 서버 즐겨찾기는 비어 있습니다.
      favorites.favorites.clear();
      members.member = MemberInfo(
        email: 'b@example.com',
        nickname: '다른사람',
        createdAt: DateTime(2026, 11, 1),
      );
      await auth.login('b@example.com', 'Password1!');
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(NavigationBar)));
      router.push('/my/favorites');
      await tester.pumpAndSettle();

      expect(find.text('영화 1'), findsNothing);
      expect(find.text('아직 즐겨찾기한 영화가 없습니다.'), findsOneWidget);
    });
  });

  group('9주차 영화 검색', () {
    testWidgets('검색 아이콘으로 들어가 제출하면 결과를 보여주고 더 보기로 이어서 불러온다', (tester) async {
      final service = _defaultService()
        ..searchPages = {
          '우주': {
            1: [_movie(31, title: '우주 1')],
            2: [_movie(32, title: '우주 2')],
          },
        };
      await _pumpApp(
        tester,
        location: '/movies',
        service: service,
        size: const Size(390, 1200),
      );

      await tester.tap(find.byTooltip('검색'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('검색어를 입력해 주세요.'), findsOneWidget);

      // 빈 검색어는 서버에 보내지 않습니다.
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(service.searchCalls, isEmpty);

      await tester.enterText(find.byType(TextField), '우주');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('우주 1'), findsOneWidget);

      await tester.tap(find.text('더 보기'));
      await tester.pumpAndSettle();
      expect(find.text('우주 2'), findsOneWidget);
      expect(find.text('더 이상 조회할 페이지가 없습니다.'), findsOneWidget);

      await tester.tap(find.text('우주 1'));
      await tester.pumpAndSettle();
      expect(find.text('Cinema Archive'), findsOneWidget);
    });

    testWidgets('입력이 500ms 멈추면 마지막 검색어만 요청하고 이전 검색어의 늦은 응답은 버린다', (
      tester,
    ) async {
      final service = _defaultService()
        ..searchPages = {
          '어벤': {
            1: [_movie(41, title: '어벤 결과')],
          },
          '어벤져스': {
            1: [_movie(42, title: '어벤져스 결과')],
          },
        };
      await _pumpApp(tester, location: '/movies/search', service: service);

      await tester.enterText(find.byType(TextField), '어');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), '어벤');
      await tester.pump(const Duration(milliseconds: 600));
      expect(service.searchCalls.map((c) => c.query), ['어벤']);

      // '어벤' 응답이 늦는 사이 새 검색어를 제출합니다.
      service.searchGates['어벤'] = Completer<void>();
      await tester.enterText(find.byType(TextField), '어벤져스');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      service.searchGates['어벤']!.complete();
      await tester.pumpAndSettle();

      expect(find.text('어벤져스 결과'), findsOneWidget);
      expect(find.text('어벤 결과'), findsNothing);
    });

    testWidgets('결과 없음과 오류를 구분한다', (tester) async {
      final service = _defaultService()..failSearch = true;
      await _pumpApp(tester, location: '/movies/search', service: service);
      await tester.enterText(find.byType(TextField), '없는영화');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('검색 결과를 불러오지 못했습니다.'), findsOneWidget);

      service.failSearch = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('"없는영화" 검색 결과가 없습니다.'), findsOneWidget);
    });
  });

  group('9주차 Challenge 평점·즐겨찾기 통합 저장', () {
    Future<void> rateFive(WidgetTester tester) async {
      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      final star = find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byIcon(Icons.star),
          )
          .at(4);
      await tester.tapAt(tester.getCenter(star) + const Offset(10, 0));
      await tester.pump();
    }

    testWidgets('즐겨찾기 체크 시 movie-records로 한 번에 저장하고 북마크를 서버 값으로 맞춘다', (
      tester,
    ) async {
      final ratings = FakeRatingApiService();
      final favorites = FakeFavoriteApiService();
      ratings.onMovieRecord = (movieId) => favorites.favorites.add(movieId);
      await _pumpApp(
        tester,
        location: '/movies/1',
        ratingService: ratings,
        favoriteApi: favorites,
      );

      await rateFive(tester);
      await tester.tap(find.text('즐겨찾기에도 추가'));
      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();

      expect(ratings.movieRecords.single, {
        'movieId': 1,
        'score': 5,
        'addToFavorites': true,
      });
      expect(ratings.created, isEmpty);
      expect(find.text('평점을 저장했습니다.'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('이미 즐겨찾기한 영화는 체크박스 없이 평점만 저장한다', (tester) async {
      final ratings = FakeRatingApiService();
      await _pumpApp(
        tester,
        location: '/movies/1',
        ratingService: ratings,
        favoriteApi: FakeFavoriteApiService([1]),
      );
      await rateFive(tester);
      expect(find.text('즐겨찾기에도 추가'), findsNothing);
      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();
      expect(ratings.created, hasLength(1));
      expect(ratings.movieRecords, isEmpty);
    });

    testWidgets('RATING409_1은 Dialog를 닫고 Snackbar, 400은 Dialog 안에서 입력을 유지한다', (
      tester,
    ) async {
      final ratings = FakeRatingApiService();
      await _pumpApp(tester, location: '/movies/1', ratingService: ratings);

      await rateFive(tester);
      ratings.writeError = _apiError(400, 'COMMON400', '별점은 5점 이하여야 합니다.');
      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('별점은 5점 이하여야 합니다.'), findsOneWidget);

      ratings.writeError = _apiError(
        409,
        'RATING409_1',
        '이미 이 영화에 평점을 남기셨습니다.',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
    });
  });
}
