import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/member_info.dart';
import '../data/services/learning_member_session.dart';
import '../data/services/member_api_service.dart';
import '../data/services/token_storage.dart';

enum AuthStatus { initializing, signedOut, signingIn, signedIn }

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._memberApi, this._session, this._tokenStorage);

  final MemberApiService _memberApi;
  final LearningMemberSession _session;
  final TokenStorage _tokenStorage;

  AuthStatus status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? message;
  bool sessionExpired = false;
  int _sessionVersion = 0;
  bool _disposed = false;
  bool _tokenDeletionPending = false;
  Future<void> _tokenOperations = Future<void>.value();

  bool get isSignedIn => status == AuthStatus.signedIn;
  bool get isSigningIn => status == AuthStatus.signingIn;
  bool get tokenDeletionPending => _tokenDeletionPending;

  Future<void> restoreSession() async {
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    _notify();
    try {
      final token = await _runTokenOperation(_tokenStorage.read);
      if (version != _sessionVersion) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
        _session.clear();
        _notify();
        return;
      }
      _session.setAccessToken(token);
      final me = await _memberApi.fetchMe();
      if (version != _sessionVersion) return;
      member = me;
      _session.setMemberId(me.memberId);
      memberStatus = MemberLoadStatus.success;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (version != _sessionVersion) return;
      final code = memberApiErrorCode(error);
      if (_isSessionError(code)) {
        await _clearCurrentSession(expired: true);
        return;
      }
      status = AuthStatus.initializing;
      message = '세션을 확인하지 못했어요.';
    } on Object {
      if (version != _sessionVersion) return;
      status = AuthStatus.initializing;
      message = '세션을 확인하지 못했어요.';
    }
    _notify();
  }

  Future<bool> login({required String email, required String password}) async {
    if (status == AuthStatus.signingIn) return false;
    final version = ++_sessionVersion;
    status = AuthStatus.signingIn;
    message = null;
    sessionExpired = false;
    _notify();
    try {
      final response = await _memberApi.login(email: email, password: password);
      final token = response.result?.accessToken;
      if (token == null || token.isEmpty) {
        throw const FormatException('로그인 응답에 accessToken이 없습니다.');
      }
      if (!await _storeTokenIfCurrent(token, version)) return false;
      _tokenDeletionPending = false;
      _session.setAccessToken(token);
      member = null;
      memberStatus = MemberLoadStatus.idle;
      status = AuthStatus.signedIn;
      _notify();
      return true;
    } on DioException catch (error) {
      if (version != _sessionVersion) return false;
      status = AuthStatus.signedOut;
      message = memberApiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해주세요.'
          : memberApiErrorMessage(error);
    } on Object {
      if (version != _sessionVersion) return false;
      status = AuthStatus.signedOut;
      message = '로그인에 실패했습니다. 다시 시도해주세요.';
    }
    _notify();
    return false;
  }

  Future<void> completeAuthentication({
    required String accessToken,
    int? memberId,
  }) async {
    final version = ++_sessionVersion;
    if (!await _storeTokenIfCurrent(accessToken, version)) return;
    _tokenDeletionPending = false;
    _session
      ..setAccessToken(accessToken)
      ..setMemberId(memberId);
    member = null;
    memberStatus = MemberLoadStatus.idle;
    status = AuthStatus.signedIn;
    sessionExpired = false;
    message = null;
    _notify();
  }

  Future<void> loadMember({bool force = false}) async {
    if (status != AuthStatus.signedIn ||
        memberStatus == MemberLoadStatus.loading ||
        (member != null && !force)) {
      return;
    }
    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    message = null;
    _notify();
    try {
      final me = await _memberApi.fetchMe();
      if (version != _sessionVersion) return;
      member = me;
      _session.setMemberId(me.memberId);
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (version != _sessionVersion) return;
      final code = memberApiErrorCode(error);
      if (_isSessionError(code)) {
        await _clearCurrentSession(expired: true);
        return;
      }
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    } on Object {
      if (version != _sessionVersion) return;
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    }
    _notify();
  }

  Future<MemberInfo?> updateNickname(String nickname) async {
    final version = _sessionVersion;
    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (version != _sessionVersion) return null;
      member = updated;
      memberStatus = MemberLoadStatus.success;
      _notify();
      return updated;
    } on DioException catch (error) {
      if (version != _sessionVersion) return null;
      if (_isSessionError(memberApiErrorCode(error))) {
        await _clearCurrentSession(expired: true);
      }
      rethrow;
    }
  }

  Future<void> logout() => _clearCurrentSession();

  void clearMessage() {
    if (message == null) return;
    message = null;
    _notify();
  }

  Future<bool> retryTokenDeletion() async {
    try {
      await _runTokenOperation(_tokenStorage.delete);
      _tokenDeletionPending = false;
      return true;
    } on Object {
      _tokenDeletionPending = true;
      return false;
    } finally {
      _notify();
    }
  }

  void consumeSessionExpired() {
    if (!sessionExpired) return;
    sessionExpired = false;
    _notify();
  }

  Future<void> _clearCurrentSession({bool expired = false}) async {
    _sessionVersion++;
    _session.clear();
    member = null;
    memberStatus = MemberLoadStatus.idle;
    status = AuthStatus.signedOut;
    sessionExpired = expired;
    message = null;
    try {
      await _runTokenOperation(_tokenStorage.delete);
      _tokenDeletionPending = false;
    } on Object {
      _tokenDeletionPending = true;
    }
    _notify();
  }

  Future<bool> _storeTokenIfCurrent(String token, int version) {
    return _runTokenOperation(() async {
      if (version != _sessionVersion) return false;
      await _tokenStorage.write(token);
      if (version == _sessionVersion) return true;
      try {
        if (await _tokenStorage.read() == token) {
          await _tokenStorage.delete();
        }
      } on Object {
        _tokenDeletionPending = true;
      }
      return false;
    });
  }

  Future<T> _runTokenOperation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    final previous = _tokenOperations;
    _tokenOperations = () async {
      await previous;
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }();
    return completer.future;
  }

  bool _isSessionError(String? code) {
    return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
