import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/learning_member_session.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/token_storage.dart';
import 'package:movielog/view_models/auth_view_model.dart';

void main() {
  test('저장된 토큰으로 GET me를 검증하고 세션을 복원한다', () async {
    final storage = MemoryTokenStorage('saved-token');
    final session = LearningMemberSession();
    final service = MemberApiService(
      _dio((options) => _memberResponse()),
      authSession: session,
    );
    final viewModel = AuthViewModel(service, session, storage);

    await viewModel.restoreSession();

    expect(viewModel.status, AuthStatus.signedIn);
    expect(viewModel.member?.nickname, '무비러버');
    expect(session.memberId, 7);
    expect(session.accessToken, 'saved-token');
  });

  test('만료된 토큰은 삭제하고 세션 만료 안내 상태를 남긴다', () async {
    final storage = MemoryTokenStorage('expired-token');
    final session = LearningMemberSession();
    final service = MemberApiService(
      _dio(
        (_) => throw DioException(
          requestOptions: RequestOptions(path: '/v7/members/me'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/v7/members/me'),
            statusCode: 401,
            data: {
              'isSuccess': false,
              'code': 'AUTH401_3',
              'message': '유효하지 않은 인증 토큰입니다.',
              'result': null,
            },
          ),
        ),
      ),
      authSession: session,
    );
    final viewModel = AuthViewModel(service, session, storage);

    await viewModel.restoreSession();

    expect(viewModel.status, AuthStatus.signedOut);
    expect(viewModel.sessionExpired, isTrue);
    expect(await storage.read(), isNull);
    expect(session.accessToken, isNull);
  });

  test('네트워크 실패는 저장된 토큰을 지우지 않고 재시도 상태로 남긴다', () async {
    final storage = MemoryTokenStorage('keep-token');
    final session = LearningMemberSession();
    final service = MemberApiService(
      _dio(
        (options) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 5),
          requestOptions: options,
        ),
      ),
      authSession: session,
    );
    final viewModel = AuthViewModel(service, session, storage);

    await viewModel.restoreSession();

    expect(viewModel.status, AuthStatus.initializing);
    expect(viewModel.message, '세션을 확인하지 못했어요.');
    expect(await storage.read(), 'keep-token');
  });

  test('로그인은 토큰 저장 후 signedIn으로 확정하고 GET me는 호출하지 않는다', () async {
    final paths = <String>[];
    final storage = MemoryTokenStorage();
    final session = LearningMemberSession();
    final service = MemberApiService(
      _dio((options) {
        paths.add(options.path);
        return {
          'isSuccess': true,
          'code': 'COMMON200',
          'message': '로그인에 성공했습니다.',
          'result': {'accessToken': 'new-token'},
        };
      }),
      authSession: session,
    );
    final viewModel = AuthViewModel(service, session, storage);

    final success = await viewModel.login(
      email: 'movie@example.com',
      password: 'Password1!',
    );

    expect(success, isTrue);
    expect(viewModel.status, AuthStatus.signedIn);
    expect(viewModel.memberStatus, MemberLoadStatus.idle);
    expect(await storage.read(), 'new-token');
    expect(paths, ['/v7/auth/login']);
  });

  test('로그인 저장 중 로그아웃되면 이전 토큰을 제거하고 signedOut을 유지한다', () async {
    final storage = _DeferredWriteTokenStorage();
    final session = LearningMemberSession();
    final service = MemberApiService(
      _dio(
        (_) => {
          'isSuccess': true,
          'code': 'COMMON200',
          'message': '로그인에 성공했습니다.',
          'result': {'accessToken': 'stale-token'},
        },
      ),
      authSession: session,
    );
    final viewModel = AuthViewModel(service, session, storage);

    final login = viewModel.login(
      email: 'movie@example.com',
      password: 'Password1!',
    );
    await Future<void>.delayed(Duration.zero);
    final logout = viewModel.logout();
    storage.allowWrite.complete();
    await logout;

    expect(await login, isFalse);
    expect(viewModel.status, AuthStatus.signedOut);
    expect(await storage.read(), isNull);
    expect(session.accessToken, isNull);
  });

  test('이전 토큰 저장이 늦게 끝나도 최신 인증 토큰을 유지한다', () async {
    final storage = _OrderedWriteTokenStorage();
    final session = LearningMemberSession();
    final viewModel = AuthViewModel(
      MemberApiService(Dio(), authSession: session),
      session,
      storage,
    );

    final first = viewModel.completeAuthentication(accessToken: 'token-a');
    await storage.firstWriteStarted.future;
    final second = viewModel.completeAuthentication(accessToken: 'token-b');
    storage.allowFirstWrite.complete();
    await Future.wait([first, second]);

    expect(await storage.read(), 'token-b');
    expect(session.accessToken, 'token-b');
    expect(viewModel.status, AuthStatus.signedIn);
  });

  test('토큰 삭제가 실패해도 메모리 세션과 로그아웃 상태는 정리한다', () async {
    final storage = _DeleteFailingTokenStorage('saved-token');
    final session = LearningMemberSession(
      initialMemberId: 7,
      initialAccessToken: 'saved-token',
    );
    final viewModel =
        AuthViewModel(
            MemberApiService(Dio(), authSession: session),
            session,
            storage,
          )
          ..status = AuthStatus.signedIn
          ..memberStatus = MemberLoadStatus.success;

    await viewModel.logout();

    expect(viewModel.status, AuthStatus.signedOut);
    expect(session.accessToken, isNull);
    expect(session.memberId, isNull);
    expect(viewModel.tokenDeletionPending, isTrue);
    expect(await viewModel.retryTokenDeletion(), isFalse);
  });
}

Map<String, dynamic> _memberResponse() => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': '내 정보 조회에 성공했습니다.',
  'result': {
    'memberId': 7,
    'email': 'movie@example.com',
    'nickname': '무비러버',
    'createdAt': '2026-10-10T09:00:00',
  },
};

Dio _dio(Object? Function(RequestOptions options) responseBuilder) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: responseBuilder(options),
            ),
          );
        } on DioException catch (error) {
          handler.reject(error);
        }
      },
    ),
  );
  return dio;
}

class _DeferredWriteTokenStorage implements TokenStorage {
  final allowWrite = Completer<void>();
  String? _token;

  @override
  Future<void> write(String token) async {
    await allowWrite.future;
    _token = token;
  }

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> delete() async => _token = null;
}

class _DeleteFailingTokenStorage implements TokenStorage {
  _DeleteFailingTokenStorage(this._token);

  String? _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> delete() async => throw StateError('keychain unavailable');
}

class _OrderedWriteTokenStorage implements TokenStorage {
  final firstWriteStarted = Completer<void>();
  final allowFirstWrite = Completer<void>();
  String? _token;
  int _writeCount = 0;

  @override
  Future<void> write(String token) async {
    _writeCount++;
    if (_writeCount == 1) {
      firstWriteStarted.complete();
      await allowFirstWrite.future;
    }
    _token = token;
  }

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> delete() async => _token = null;
}
