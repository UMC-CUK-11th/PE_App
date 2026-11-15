import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/models/rating_dto.dart';
import 'package:movielog/models/tmdb_movie_dto.dart';
import 'package:movielog/services/movie_log_client.dart';
import 'package:movielog/services/member_check_service.dart';
import 'package:movielog/services/rating_api_service.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/signup_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/screens/my_ratings_screen.dart';

class CheckService extends MemberCheckService {
  CheckService() : super(Dio());
  int calls = 0;
  bool available = false;
  bool fail = false;
  Completer<bool>? pending;
  Future<bool> answer() async {
    calls++;
    if (fail) throw DioException(requestOptions: RequestOptions(path: '/test'));
    return pending?.future ?? Future.value(available);
  }

  @override
  Future<bool> checkNickname(String value) => answer();
  @override
  Future<bool> checkEmail(String value) => answer();
}

class RatingsService extends RatingApiService {
  RatingsService() : super(Dio());
  List<RatingDto> items = [];
  int? memberId;
  Completer<List<RatingDto>>? pending;
  DioException? failure;
  @override
  Future<List<RatingDto>> fetchMyRatings(int id) async {
    memberId = id;
    if (failure != null) throw failure!;
    return pending?.future ?? Future.value(items);
  }
}

class MoviesService extends TmdbMovieService {
  MoviesService() : super(Dio());
  int calls = 0;
  bool fail = false;
  @override
  Future<TmdbMovieDto> fetchMovieDetail(
    int id, {
    CancelToken? cancelToken,
  }) async {
    calls++;
    if (fail) throw StateError('detail failed');
    return TmdbMovieDto(id: id, title: '테스트 영화');
  }
}

RatingDto rating(int id) => RatingDto(
  ratingId: id,
  movieId: 550,
  score: 5,
  comment: null,
  createdAt: DateTime.utc(2026, 11, 2),
);

void main() {
  test('워크북 클라이언트는 TMDB 인증 헤더를 포함하지 않는다', () {
    final dio = createMovieLogClient();
    expect(dio.options.baseUrl, 'https://workbook.devnoco.com');
    expect(
      dio.options.headers.keys.map((k) => k.toLowerCase()),
      isNot(contains('authorization')),
    );
    dio.close();
  });
  test('RatingDto는 null 후기와 UTC 시각을 처리한다', () {
    final item = RatingDto.fromJson({
      'ratingId': 1,
      'movieId': 550,
      'score': 5,
      'comment': null,
      'createdAt': '2026-11-02T19:00:19.459Z',
    });
    expect(item.comment, isNull);
    expect(item.createdAt.isUtc, isTrue);
  });
  test('닉네임과 이메일 형식이 유효해야 확인할 수 있다', () {
    final vm = SignUpViewModel(CheckService());
    addTearDown(vm.dispose);
    expect(vm.canCheckNickname, isFalse);
    vm.onNicknameChanged('김');
    expect(vm.canCheckNickname, isFalse);
    vm.onNicknameChanged('홀란드');
    expect(vm.canCheckNickname, isTrue);
    vm.onEmailChanged('wrong');
    expect(vm.canCheckEmail, isFalse);
  });
  for (final email in [false, true]) {
    test('${email ? "이메일" : "닉네임"} 중복 기억·재입력 차단 및 통신 오류 구분', () async {
      final service = CheckService();
      final vm = SignUpViewModel(service);
      addTearDown(vm.dispose);
      final changed = email ? vm.onEmailChanged : vm.onNicknameChanged;
      final check = email ? vm.checkEmail : vm.checkNickname;
      final a = email ? 'a@example.com' : '제임스';
      final b = email ? 'b@example.com' : '홀란드';
      CheckStatus status() =>
          email ? vm.emailCheckStatus : vm.nicknameCheckStatus;
      bool enabled() => email ? vm.canCheckEmail : vm.canCheckNickname;
      changed(a);
      await check(a);
      expect(status(), CheckStatus.duplicated);
      expect(enabled(), isFalse);
      changed(b);
      expect(status(), CheckStatus.idle);
      changed(a);
      expect(status(), CheckStatus.duplicated);
      await check(a);
      expect(service.calls, 1);
      changed(b);
      service.fail = true;
      await check(b);
      expect(status(), CheckStatus.error);
      expect(enabled(), isTrue);
    });
  }
  test('이전 입력의 늦은 응답과 dispose 이후 응답을 무시한다', () async {
    final service = CheckService()..pending = Completer<bool>();
    final vm = SignUpViewModel(service);
    vm.onNicknameChanged('제임스');
    final request = vm.checkNickname('제임스');
    expect(vm.nicknameCheckStatus, CheckStatus.checking);
    await vm.checkNickname('제임스');
    expect(service.calls, 1);
    vm.onNicknameChanged('홀란드');
    service.pending!.complete(true);
    await request;
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    service.pending = Completer<bool>();
    final disposedRequest = vm.checkNickname('홀란드');
    vm.dispose();
    service.pending!.complete(true);
    await disposedRequest;
  });
  test('두 입력란은 독립적으로 요청하고 둘 다 확인해야 제출 가능하다', () async {
    final service = CheckService()..available = true;
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('홀란드');
    vm.onEmailChanged('test@example.com');
    await vm.checkNickname('홀란드');
    expect(vm.bothAvailable, isFalse);
    await vm.checkEmail('test@example.com');
    expect(vm.bothAvailable, isTrue);
    vm.onEmailChanged('next@example.com');
    expect(vm.bothAvailable, isFalse);
  });
  test('평점은 회원 1번 조회, 영화 중복 요청 제거, 상세 실패 시에도 보존한다', () async {
    final service = RatingsService()..items = [rating(2), rating(1)];
    final movies = MoviesService()..fail = true;
    final vm = MyRatingsViewModel(service, movies, memberId: 1);
    addTearDown(vm.dispose);
    await vm.load();
    expect(service.memberId, 1);
    expect(vm.status, MyRatingsStatus.success);
    expect(vm.ratings.length, 2);
    expect(movies.calls, 1);
    expect(vm.failedMovieIds, contains(550));
    movies.fail = false;
    await vm.load();
    expect(vm.moviesById[550]?.title, '테스트 영화');
    await vm.load();
    expect(movies.calls, 2);
  });
  test('평점 400/404와 통신 실패의 안내를 구분한다', () {
    String message(int? code) => writeMyRatingsErrorMessage(
      DioException(
        requestOptions: RequestOptions(path: '/ratings'),
        response: code == null
            ? null
            : Response(
                requestOptions: RequestOptions(path: '/ratings'),
                statusCode: code,
              ),
      ),
    );
    expect(message(400), contains('형식'));
    expect(message(404), contains('존재하지 않는'));
    expect(message(null), contains('다시 시도'));
  });
  testWidgets('평점 화면 Loading → Empty → Error → 재시도 Success, 하단 탭 없음', (
    tester,
  ) async {
    final service = RatingsService()..pending = Completer<List<RatingDto>>();
    final vm = MyRatingsViewModel(service, MoviesService(), memberId: 1);
    addTearDown(vm.dispose);
    final loading = vm.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: MyRatingsScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.pending!.complete([]);
    await loading;
    await tester.pump();
    expect(find.text('등록한 평점이 없습니다.'), findsOneWidget);
    service.pending = null;
    service.failure = DioException(
      requestOptions: RequestOptions(path: '/ratings'),
    );
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('평점을 불러오지 못했습니다'), findsOneWidget);
    service.failure = null;
    service.items = [rating(1)];
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('테스트 영화'), findsOneWidget);
    expect(find.text('작성한 후기가 없습니다.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
  testWidgets('공용 버튼의 세 너비 및 로딩 클릭 차단', (tester) async {
    int calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: Column(
                children: [
                  MovieLogButton(
                    key: const ValueKey('natural'),
                    label: '중복 확인',
                    onPressed: () => calls++,
                  ),
                  MovieLogButton(
                    key: const ValueKey('full'),
                    label: '전체',
                    width: double.infinity,
                    onPressed: () {},
                  ),
                  MovieLogButton(
                    key: const ValueKey('fixed'),
                    label: '고정',
                    width: 120,
                    isLoading: true,
                    onPressed: () => calls++,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('natural'))).width,
      lessThan(300),
    );
    expect(tester.getSize(find.byKey(const ValueKey('full'))).width, 300);
    expect(tester.getSize(find.byKey(const ValueKey('fixed'))).width, 120);
    await tester.tap(find.byKey(const ValueKey('fixed')));
    expect(calls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
