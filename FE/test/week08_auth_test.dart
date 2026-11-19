import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/models/auth_models.dart';
import 'package:movielog/models/rating_request.dart';
import 'package:movielog/services/auth_api_service.dart';
import 'package:movielog/services/movie_log_client.dart';
import 'package:movielog/services/rating_api_service.dart';
import 'package:movielog/services/token_storage.dart';
import 'package:movielog/view_models/auth_session.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';

class _MemoryTokenStorage extends TokenStorage {
  String? value;

  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

class _Adapter implements HttpClientAdapter {
  FutureOr<ResponseBody> Function(RequestOptions)? reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => reply!(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object? data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

ResponseBody _wrap(int status, Object? data, [String? code]) => _json(status, {
  'isSuccess': status < 300,
  'code': code ?? 'COMMON$status',
  'message': '워크북 응답',
  'result': data,
});

const _member = {
  'email': 'james@example.com',
  'nickname': '제임스',
  'createdAt': '2026-11-16T00:00:00Z',
};
const _rating = {
  'ratingId': 42,
  'movieId': 550,
  'score': 4,
  'comment': null,
  'createdAt': '2026-11-16T00:00:00Z',
  'updatedAt': '2026-11-16T00:00:00Z',
};

void main() {
  late Dio dio;
  late _Adapter adapter;
  late _MemoryTokenStorage storage;
  late AuthSession session;

  setUp(() {
    adapter = _Adapter();
    dio = createMovieLogClient()..httpClientAdapter = adapter;
    storage = _MemoryTokenStorage();
    session = AuthSession(AuthApiService(dio), storage);
    attachMovieLogAuth(dio, session);
    addTearDown(() {
      session.dispose();
      dio.close();
    });
  });

  test('복원 중 통신 오류는 토큰을 유지하고 재시도 성공 후 로그인한다', () async {
    storage.value = 'restored-token';
    adapter.reply = (request) => throw DioException.connectionError(
      requestOptions: request,
      reason: 'offline',
    );
    await session.restore();
    expect(session.status, AuthStatus.restoreError);
    expect(storage.value, 'restored-token');

    adapter.reply = (request) {
      expect(request.path, '/v7/members/me');
      expect(request.headers['Authorization'], 'Bearer restored-token');
      return _wrap(200, _member);
    };
    await session.restore();
    expect(session.status, AuthStatus.signedIn);
    expect(session.member?.nickname, '제임스');
  });

  test('로그인 폼의 401은 만료 안내를 만들지 않고 보호 요청의 401만 정리한다', () async {
    await session.restore();
    adapter.reply = (request) {
      expect(request.path, '/v7/auth/login');
      expect(request.headers['Authorization'], isNull);
      return _wrap(401, null, 'AUTH401_1');
    };
    const login = LoginRequest('james@example.com', 'fake-password');
    await expectLater(session.login(login), throwsException);
    expect(session.takeExpiredNotice(), isFalse);

    adapter.reply = (_) =>
        _wrap(200, {'accessToken': 'session-token', 'nickname': '제임스'});
    await session.login(login);
    expect(storage.value, 'session-token');

    final api = RatingApiService(dio);
    adapter.reply = (_) => _wrap(403, null, 'RATING403_1');
    await expectLater(api.deleteForSession(42), throwsA(isA<DioException>()));
    expect(session.signedIn, isTrue);
    expect(storage.value, 'session-token');

    adapter.reply = (_) => _wrap(401, null, 'AUTH401_3');
    await expectLater(api.deleteForSession(42), throwsA(isA<DioException>()));
    expect(session.status, AuthStatus.signedOut);
    expect(storage.value, isNull);
    expect(session.takeExpiredNotice(), isTrue);
    expect(session.takeExpiredNotice(), isFalse);
  });

  test('토큰은 워크북의 보호 경로에만 붙고 평점은 v7 응답을 파싱한다', () async {
    storage.value = 'rating-token';
    adapter.reply = (_) => _wrap(200, _member);
    await session.restore();
    final api = RatingApiService(dio);

    adapter.reply = (request) {
      expect(request.headers['Authorization'], isNull);
      return _json(200, [_rating]);
    };
    expect((await api.fetchPublicRatings(42)).single.movieId, 550);
    await dio.get<Object>('https://example.com/v7/members/me');

    adapter.reply = (request) {
      expect(request.headers['Authorization'], 'Bearer rating-token');
      if (request.method == 'POST') {
        expect(request.path, '/v7/ratings');
        expect(request.data, {'movieId': 550, 'score': 4});
        return _wrap(201, _rating);
      }
      expect(request.path, '/v7/ratings/42');
      if (request.method == 'PATCH') {
        return _wrap(200, {..._rating, 'score': 5});
      }
      expect(request.method, 'DELETE');
      return _wrap(200, null);
    };
    final legacySession = LearningMemberSession();
    addTearDown(legacySession.dispose);
    final detail = MovieDetailViewModel(550, api, legacySession, auth: session);
    await detail.register(RatingInput(4, null));
    expect(session.ratings.single.ratingId, 42);
    final updated = await api.updateForSession(
      42,
      UpdateRatingRequest(RatingInput(5, null)),
    );
    expect(updated.score, 5);
    await api.deleteForSession(42);
  });

  test('로그아웃 뒤 도착한 평점 등록 응답은 다음 회원의 목록에 들어가지 않는다', () async {
    storage.value = 'old-token';
    adapter.reply = (_) => _wrap(200, _member);
    await session.restore();
    final legacySession = LearningMemberSession();
    addTearDown(legacySession.dispose);
    final detail = MovieDetailViewModel(
      550,
      RatingApiService(dio),
      legacySession,
      auth: session,
    );
    final arrived = Completer<void>();
    final oldResponse = Completer<ResponseBody>();
    adapter.reply = (_) {
      arrived.complete();
      return oldResponse.future;
    };
    final pending = detail.register(RatingInput(4, null));
    await arrived.future;
    await session.logout();
    adapter.reply = (_) =>
        _wrap(200, {'accessToken': 'new-token', 'nickname': '홀란드'});
    await session.login(
      const LoginRequest('other@example.com', 'fake-password'),
    );
    oldResponse.complete(_wrap(201, _rating));
    await pending;
    expect(session.signedIn, isTrue);
    expect(session.ratings, isEmpty);
  });

  testWidgets('보호 라우팅을 거쳐 로그인하고 프로필을 수정한 뒤 로그아웃한다', (tester) async {
    final client = createMovieLogClient()..httpClientAdapter = adapter;
    addTearDown(client.close);
    adapter.reply = (request) {
      return switch ((request.method, request.path)) {
        ('POST', '/v7/auth/login') => _wrap(200, {
          'nickname': '제임스',
          'accessToken': 'widget-token',
        }),
        ('GET', '/v7/members/me') => _wrap(200, _member),
        ('PATCH', '/v7/members/me') => _wrap(200, {
          ..._member,
          'nickname': '새이름',
        }),
        _ => throw StateError('Unexpected route'),
      };
    };
    await tester.pumpWidget(
      MovieLogApp(workbookClient: client, tokenStorage: storage),
    );
    await tester.pumpAndSettle();
    expect(find.text('회원가입'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'james@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'fake-password');
    await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.text('제임스'), findsOneWidget);
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '새이름');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('새이름'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.text('회원가입'), findsOneWidget);
    expect(storage.value, isNull);
    expect(find.byType(SnackBar), findsNothing);
  });
}
