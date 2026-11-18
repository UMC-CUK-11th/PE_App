import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/storage/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/models/rating_dto.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

/// initializing: 앱 시작 후 토큰 확인 중 / retryRequired: 확인 실패(네트워크 등)
/// signedOut: 토큰 없음·만료·로그아웃 / authenticating: 로그인 요청 중 / signedIn: 확정
enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

/// 로그인 세션 전체를 관리합니다. 화면 이동은 하지 않고 상태만 바꾸며, Router가 status를 보고 이동합니다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message;

  /// 만료로 쫓겨났을 때만 켜집니다. 로그인 화면이 Snackbar로 한 번 안내한 뒤 끕니다.
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;

  /// 이번 로그인 세션에서 등록한 평점. v7에는 토큰 기반 "내 평점 목록 GET"이 없어
  /// 등록 응답의 Rating으로만 채우고, 세션이 끝나면 비웁니다.
  final List<RatingDto> sessionRatings = [];

  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;
  bool _disposed = false;
  Future<void>? _tokenWrite;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _resetSessionData() {
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionRatings.clear();
  }

  /// 앱 시작: 저장된 토큰이 있어도 GET me 검증이 끝나야 signedIn입니다.
  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    _resetSessionData();
    _notify();

    try {
      final token = await _storage.readAccessToken();
      if (!_isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        final verified = await _memberApi.fetchMe();
        if (!_isCurrent(version)) return;
        member = verified;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredError(error)) {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 네트워크가 잠시 끊겼다고 유효한 토큰을 지우지 않습니다.
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) _notify();
  }

  /// 신규 로그인: 토큰 저장 뒤 signedIn, 내 정보는 MainScreen이 loadMember()로 불러옵니다.
  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.authenticating;
    _resetSessionData();
    sessionExpired = false;
    message = null;
    _notify();

    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      // 로그인 실패 401(AUTH401_1)은 Form 오류이지 세션 만료가 아닙니다.
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    _notify();
  }

  /// 어느 탭으로 진입해도 한 번 GET me를 불러와 보관합니다. 네트워크 실패로는 로그아웃하지 않습니다.
  Future<void> loadMember({bool force = false}) async {
    if (status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return;
    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return; // 로그아웃·계정 전환 뒤 늦게 온 응답 무시
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredError(error)) {
        await _clearCurrentSession(expired: true);
        return;
      }
      memberStatus = MemberLoadStatus.error;
    } catch (_) {
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error;
    }
    _notify();
  }

  /// 프로필 수정 성공 응답으로 교체합니다. GET me를 다시 부르지 않습니다.
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    _notify();
  }

  void addSessionRating(RatingDto rating) {
    sessionRatings.removeWhere((r) => r.ratingId == rating.ratingId);
    sessionRatings.insert(0, rating);
    _notify();
  }

  void replaceSessionRating(RatingDto rating) {
    final index = sessionRatings.indexWhere(
      (r) => r.ratingId == rating.ratingId,
    );
    if (index >= 0) sessionRatings[index] = rating;
    _notify();
  }

  void removeSessionRating(int ratingId) {
    sessionRatings.removeWhere((r) => r.ratingId == ratingId);
    _notify();
  }

  /// 다른 ViewModel이 보호 요청에서 AUTH401_2/3/4를 받았을 때 부르는 공개 진입점입니다.
  Future<void> expireSession() => _clearCurrentSession(expired: true);

  /// 직접 로그아웃은 만료 Snackbar를 켜지 않습니다. 서버 토큰 폐기를 보장하지는 않습니다.
  Future<void> logout() => _clearCurrentSession(expired: false);

  void consumeSessionExpired() {
    sessionExpired = false;
  }

  Future<void> _clearCurrentSession({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    _resetSessionData();
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    _notify();

    try {
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제합니다. 정리 중 새 로그인은 막습니다.
      try {
        await _tokenWrite;
      } catch (_) {
        // 저장 실패여도 삭제는 시도합니다.
      }
      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
