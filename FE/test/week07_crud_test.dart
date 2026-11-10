import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/models/common_response.dart';
import 'package:movielog/models/member_models.dart';
import 'package:movielog/models/rating_request.dart';
import 'package:movielog/services/rating_api_service.dart';
import 'package:movielog/services/sign_up_service.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/signup_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'support/test_tmdb_service.dart';

class _Server implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final ratings = <Map<String, Object?>>[];
  bool failGet = false;
  int? failDelete;
  String? signupError;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    final method = options.method;
    final body = options.data as Map<String, dynamic>?;
    if (path == '/v6/members' && method == 'POST') {
      return signupError == null
          ? _wrap(201, {'memberId': 42})
          : _wrap(400, null, message: signupError!);
    }
    if (path.startsWith('/v6/members/nickname/') ||
        path.startsWith('/v6/members/email/')) {
      return _json(200, {'available': true});
    }
    const listPath = '/v6/members/42/ratings';
    if (path == listPath && method == 'GET') {
      return failGet ? _wrap(500, null) : _json(200, ratings);
    }
    if (path == listPath && method == 'POST') {
      final id = ratings.length + 10;
      ratings.add({
        'ratingId': id,
        'comment': null,
        ...body!,
        'createdAt': '2026-11-09T00:00:00Z',
      });
      return _wrap(201, id);
    }
    if (path.startsWith('$listPath/')) {
      final id = int.parse(path.split('/').last);
      if (method == 'PATCH') {
        ratings.singleWhere((r) => r['ratingId'] == id)
          ..['score'] = body!['score']
          ..['comment'] = body['comment'];
        return _wrap(200, null);
      }
      if (method == 'DELETE') {
        if (id == failDelete) return _wrap(403, null, message: '삭제 권한이 없습니다.');
        ratings.removeWhere((rating) => rating['ratingId'] == id);
        return ResponseBody.fromString('', 204);
      }
    }
    throw StateError('Unexpected request: $method $path');
  }

  ResponseBody _wrap(int status, Object? result, {String message = '처리 결과'}) =>
      _json(status, {
        'isSuccess': status < 300,
        'code': 'COMMON$status',
        'message': message,
        'result': result,
      });
  ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  late _Server server;
  late Dio dio;
  setUp(() {
    server = _Server();
    dio = Dio()..httpClientAdapter = server;
    addTearDown(dio.close);
  });

  test('가입 ID로 등록하고 수정에서 후기 유지와 비우기를 구분한다', () async {
    final signup = SignUpService(dio);
    final response = await signup.signUp(
      const CreateMemberRequest(' sample@example.com ', ' 새회원 ', 'Study123!'),
    );
    expect(server.requests.single.data, {
      'email': 'sample@example.com',
      'nickname': '새회원',
      'password': 'Study123!',
    });
    final session = LearningMemberSession()..start(response.result!.memberId);
    addTearDown(session.dispose);
    final api = RatingApiService(dio);
    final detail = MovieDetailViewModel(550, api, session);
    await detail.register(RatingInput(4, '후기'));
    final list = MyRatingsViewModel(
      api,
      TestTmdbService(),
      memberId: session.memberId,
    );
    addTearDown(list.dispose);
    await list.load();
    final id = list.ratings.single.ratingId;
    await list.update(id, RatingInput(3, null));
    expect(list.ratings.single.comment, '후기');
    expect(list.ratings.single.score, 3);
    await list.update(id, RatingInput(5, ''));
    expect(list.ratings.single.comment, isNull);
    expect(await list.deleteSelected({id}), isEmpty);
    expect(list.ratings, isEmpty);
  });

  test('일부 삭제 실패와 저장 후 조회 실패를 쓰기 실패와 구분한다', () async {
    final api = RatingApiService(dio);
    await api.create(42, CreateRatingRequest(550, RatingInput(4, null)));
    await api.create(42, CreateRatingRequest(13, RatingInput(3, null)));
    final vm = MyRatingsViewModel(api, TestTmdbService(), memberId: 42);
    addTearDown(vm.dispose);
    await vm.load();
    final first = vm.ratings.first.ratingId;
    final last = vm.ratings.last.ratingId;
    server.failDelete = last;
    final failures = await vm.deleteSelected({first, last});
    expect(failures.keys, [last]);
    expect(failures[last]!.message, '삭제 권한이 없습니다.');
    expect(vm.ratings.single.ratingId, last);
    server.failGet = true;
    await vm.update(last, RatingInput(5, null));
    expect(vm.status, MyRatingsStatus.error);
    expect(server.ratings.single['score'], 5);
  });

  test('비밀번호 400만 입력란 오류로 전달하고 입력 변경 때 지운다', () async {
    final vm = SignUpViewModel(SignUpService(dio));
    addTearDown(vm.dispose);
    vm.onNicknameChanged('새회원');
    vm.onEmailChanged('sample@example.com');
    await vm.checkNickname('새회원');
    await vm.checkEmail('sample@example.com');
    server.signupError = '비밀번호 형식을 확인해 주세요.';
    expect(await vm.submit('Study123!'), isNull);
    expect(vm.passwordErrorText, server.signupError);
    expect(vm.snackbarMessage, isNull);
    vm.onPasswordChanged();
    expect(vm.passwordErrorText, isNull);
    server.signupError = '이메일 형식을 확인해 주세요.';
    expect(await vm.submit('Study123!'), isNull);
    expect(vm.snackbarMessage, server.signupError);
    expect(vm.passwordErrorText, isNull);
  });

  testWidgets('저장 중 뒤로가기를 막고 실패 시 코멘트를 보존한다', (tester) async {
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RatingDialog(
                    initialRating: 4,
                    onSubmit: (_) => pending.future,
                  ),
                ),
                child: const Text('열기'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '기억할 후기');
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(RatingDialog), findsOneWidget);
    pending.completeError(const ApiFailure('이미 평가한 영화입니다.'));
    await tester.pumpAndSettle();
    expect(find.text('이미 평가한 영화입니다.'), findsOneWidget);
    expect(find.text('기억할 후기'), findsOneWidget);
  });
}
