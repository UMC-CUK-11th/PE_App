import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/services/fake_movie_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/member_ratings_screen.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/member_ratings_view_model.dart';

void main() {
  testWidgets('마이 페이지에서 memberId 1의 평점 목록으로 이동한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final memberService = MemberApiService(_dio((_) => <dynamic>[]));
    final tmdbService = TmdbMovieService(_dio((_) => <String, dynamic>{}));
    final router = AppRouter.createRouter(
      initialLocation: '/my',
      movieService: const FakeMovieService(delay: Duration.zero),
      memberApiService: memberService,
      tmdbMovieService: tmdbService,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(router: router));
    await tester.pumpAndSettle();

    final entry = find.byKey(const ValueKey('my-ratings-entry'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.text('내가 등록한 평점'), findsOneWidget);
    expect(find.text('아직 등록한 평점이 없습니다.'), findsOneWidget);
  });

  testWidgets('평점 목록은 Loading에서 TMDB 영화 정보가 결합된 Success로 전환된다', (tester) async {
    final viewModel = MemberRatingsViewModel(
      memberId: 1,
      memberApiService: MemberApiService(
        _dio((_) => [_ratingJson(movieId: 550)]),
      ),
      movieService: TmdbMovieService(
        _dio(
          (_) => {
            'id': 550,
            'title': '파이트 클럽',
            'vote_average': 8.4,
            'overview': '테스트',
            'poster_path': null,
          },
        ),
      ),
    );

    await tester.pumpWidget(_app(viewModel));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('파이트 클럽'), findsOneWidget);
    expect(find.text('별점 5 / 5'), findsOneWidget);
    expect(find.text('최고의 영화!'), findsOneWidget);
  });

  testWidgets('평점이 없으면 Empty 상태를 표시한다', (tester) async {
    final viewModel = MemberRatingsViewModel(
      memberId: 1,
      memberApiService: MemberApiService(_dio((_) => <dynamic>[])),
      movieService: TmdbMovieService(_dio((_) => <String, dynamic>{})),
    );
    await tester.pumpWidget(_app(viewModel));
    await tester.pumpAndSettle();
    expect(find.text('아직 등록한 평점이 없습니다.'), findsOneWidget);
  });

  testWidgets('회원 평점 API가 실패하면 Error와 다시 시도를 표시한다', (tester) async {
    final viewModel = MemberRatingsViewModel(
      memberId: 1,
      memberApiService: MemberApiService(_failingDio()),
      movieService: TmdbMovieService(_dio((_) => <String, dynamic>{})),
    );
    await tester.pumpWidget(_app(viewModel));
    await tester.pumpAndSettle();
    expect(find.text('평점 목록을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

Widget _app(MemberRatingsViewModel viewModel) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MemberRatingsScreen(viewModel: viewModel),
  );
}

Map<String, dynamic> _ratingJson({required int movieId}) => {
  'ratingId': 1,
  'movieId': movieId,
  'score': 5,
  'comment': '최고의 영화!',
  'createdAt': '2026-10-27T12:00:00',
  'updatedAt': '2026-10-27T12:00:00',
};

Dio _dio(dynamic Function(RequestOptions) responseBuilder) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: responseBuilder(options),
        ),
      ),
    ),
  );
  return dio;
}

Dio _failingDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      ),
    ),
  );
  return dio;
}
