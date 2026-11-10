import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/learning_member_session.dart';
import 'package:movielog/data/services/fake_movie_service.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  Future<void> pumpRegisterScreen(
    WidgetTester tester, {
    required MemberApiService apiService,
  }) async {
    final router = AppRouter.createRouter(
      initialLocation: '/register',
      memberApiService: apiService,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(router: router));
  }

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetViewInsets();
  });

  testWidgets('닉네임과 이메일 확인이 성공해야 가입 버튼이 활성화된다', (tester) async {
    await pumpRegisterScreen(
      tester,
      apiService: MemberApiService(_fakeDio((_) => {'available': true})),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '노바');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('닉네임-check-button')));
    await tester.pumpAndSettle();
    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'nova@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('이메일-check-button')));
    await tester.pumpAndSettle();
    expect(find.text('사용 가능한 이메일입니다.'), findsOneWidget);
    expect(find.text('사용 가능한 이메일입니다.'), findsOneWidget);

    await tester.enterText(fields.at(2), 'Password1!');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('sign-up-button')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('입력이 바뀌면 확인 결과를 무효화하고 중복값 재입력은 즉시 복원한다', (tester) async {
    var nicknameRequests = 0;
    await pumpRegisterScreen(
      tester,
      apiService: MemberApiService(
        _fakeDio((options) {
          if (options.path.contains('/nickname/')) nicknameRequests++;
          return {'available': false};
        }),
      ),
    );

    final nicknameField = find.byType(TextFormField).first;
    await tester.enterText(nicknameField, '중복닉네임');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('닉네임-check-button')));
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(nicknameRequests, 1);

    await tester.enterText(nicknameField, '새닉네임');
    await tester.pump();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);

    await tester.enterText(nicknameField, '중복닉네임');
    await tester.pump();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(nicknameRequests, 1);
  });

  testWidgets('통신 실패는 중복 응답과 다른 오류 메시지를 표시한다', (tester) async {
    await pumpRegisterScreen(
      tester,
      apiService: MemberApiService(_failingDio()),
    );

    final emailField = find.byType(TextFormField).at(1);
    await tester.enterText(emailField, 'nova@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('이메일-check-button')));
    await tester.pumpAndSettle();

    expect(find.text('이메일 중복 확인에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsNothing);
  });

  testWidgets('잘못된 형식은 한국어 오류를 표시하고 낮은 화면에서도 스크롤된다', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    await pumpRegisterScreen(
      tester,
      apiService: MemberApiService(_fakeDio((_) => {'available': true})),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '노');
    await tester.enterText(fields.at(1), 'invalid-email');
    await tester.enterText(fields.at(2), 'short');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('common-app-bar-back-icon')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('254자를 초과한 이메일은 중복 확인 전에 길이 오류를 표시한다', (tester) async {
    await pumpRegisterScreen(
      tester,
      apiService: MemberApiService(_fakeDio((_) => {'available': true})),
    );

    final emailField = find.byType(TextFormField).at(1);
    final email = '${List.filled(250, 'a').join()}@x.com';
    await tester.enterText(emailField, email);
    await tester.pump();

    expect(find.text('이메일은 254자 이하여야 합니다.'), findsOneWidget);
    final checkButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('이메일-check-button')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(checkButton.onPressed, isNull);
  });

  testWidgets('입력이 원래 값으로 돌아와도 이전 중복 확인 응답을 무시한다', (tester) async {
    final response = Completer<Response<dynamic>>();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          handler.resolve(await response.future);
        },
      ),
    );
    await pumpRegisterScreen(tester, apiService: MemberApiService(dio));

    final nicknameField = find.byType(TextFormField).first;
    await tester.enterText(nicknameField, '노바');
    await tester.tap(find.byKey(const ValueKey('닉네임-check-button')));
    await tester.pump();
    await tester.enterText(nicknameField, '다른닉네임');
    await tester.enterText(nicknameField, '노바');
    response.complete(
      Response<dynamic>(
        requestOptions: RequestOptions(path: '/members/nickname/노바'),
        statusCode: 200,
        data: {'available': true},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('사용 가능한 닉네임입니다.'), findsNothing);
  });

  testWidgets('회원가입 성공 memberId를 세션에 저장하고 영화 화면으로 이동한다', (tester) async {
    final session = LearningMemberSession();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final Map<String, dynamic> data = options.method == 'POST'
              ? {
                  'isSuccess': true,
                  'code': 'COMMON201',
                  'message': '회원가입 성공',
                  'result': {
                    'memberId': 27,
                    'email': 'nova@example.com',
                    'nickname': '노바',
                  },
                }
              : {'available': true};
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: options.method == 'POST' ? 201 : 200,
              data: data,
            ),
          );
        },
      ),
    );
    final router = AppRouter.createRouter(
      initialLocation: '/register',
      memberApiService: MemberApiService(dio),
      memberSession: session,
      movieService: const FakeMovieService(delay: Duration.zero),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(router: router));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '노바');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('닉네임-check-button')));
    await tester.pumpAndSettle();
    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
    await tester.enterText(fields.at(1), 'nova@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('이메일-check-button')));
    await tester.pumpAndSettle();
    expect(find.text('사용 가능한 이메일입니다.'), findsOneWidget);
    await tester.enterText(fields.at(2), 'Password1!');
    final termsCheckbox = find.byType(Checkbox);
    await tester.ensureVisible(termsCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(termsCheckbox);
    await tester.pump();
    final signUpButton = find.byKey(const ValueKey('sign-up-button'));
    await tester.ensureVisible(signUpButton);
    await tester.pumpAndSettle();
    final filledButton = tester.widget<FilledButton>(
      find.descendant(of: signUpButton, matching: find.byType(FilledButton)),
    );
    expect(filledButton.onPressed, isNotNull);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    expect(session.memberId, 27);
    expect(router.routeInformationProvider.value.uri.path, '/movies');
  });
}

Dio _fakeDio(dynamic Function(RequestOptions) responseBuilder) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
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
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
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
