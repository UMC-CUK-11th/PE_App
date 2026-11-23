import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage.dart';

enum AuthStatus { initializing, restoreError, signedOut, signedIn }

enum MemberLoadStatus { idle, loading, success, error }

class AuthSession extends ChangeNotifier {
  AuthSession(this._api, this._storage);

  final AuthApiService _api;
  final TokenStorage _storage;
  AuthStatus _status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? _token;
  String? loginNickname;
  bool busy = false;
  bool _disposed = false;
  int _generation = 0;
  bool _expiredNotice = false;
  final _ratings = <int, RatingDto>{};

  AuthStatus get status => _status;
  bool get signedIn => _status == AuthStatus.signedIn;
  String? get token => _token;
  int get generation => _generation;
  List<RatingDto> get ratings =>
      _ratings.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  bool isCurrent(int generation) => !_disposed && _generation == generation;

  void saveRating(int generation, RatingDto rating) {
    if (isCurrent(generation) && signedIn) _ratings[rating.ratingId] = rating;
  }

  void removeRating(int generation, int ratingId) {
    if (isCurrent(generation) && signedIn) _ratings.remove(ratingId);
  }

  bool takeExpiredNotice() {
    final pending = _expiredNotice;
    _expiredNotice = false;
    return pending;
  }

  Future<void> restore() async {
    if (busy || signedIn || _disposed) return;
    busy = true;
    final generation = _generation;
    _status = AuthStatus.initializing;
    _notify();
    try {
      final stored = await _storage.read();
      if (!isCurrent(generation)) return;
      if (stored == null || stored.trim().isEmpty) {
        _status = AuthStatus.signedOut;
        return;
      }
      _token = stored;
      final restored = await _api.getMember();
      if (!isCurrent(generation)) return;
      member = restored;
      memberStatus = MemberLoadStatus.success;
      _status = AuthStatus.signedIn;
    } catch (_) {
      if (isCurrent(generation)) _status = AuthStatus.restoreError;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> login(LoginRequest request) async {
    if (busy || _status != AuthStatus.signedOut || _disposed) return;
    busy = true;
    _notify();
    try {
      final result = await _api.login(request);
      if (_disposed) return;
      await _storage.write(result.accessToken);
      if (_disposed) return;
      _generation++;
      _token = result.accessToken;
      loginNickname = result.nickname;
      _status = AuthStatus.signedIn;
    } catch (error) {
      final failure = ApiFailure.from(error, '로그인하지 못했습니다. 다시 시도해 주세요.');
      if (failure.code == 'AUTH401_1' || failure.status == 401) {
        throw const ApiFailure('이메일 또는 비밀번호를 확인해 주세요.');
      }
      throw failure;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> loadMember() async {
    if (!signedIn ||
        busy ||
        memberStatus == MemberLoadStatus.loading ||
        _disposed) {
      return;
    }
    final generation = _generation;
    memberStatus = MemberLoadStatus.loading;
    _notify();
    try {
      final result = await _api.getMember();
      if (!isCurrent(generation)) return;
      member = result;
      memberStatus = MemberLoadStatus.success;
    } catch (_) {
      if (!isCurrent(generation)) return;
      memberStatus = MemberLoadStatus.error;
    }
    _notify();
  }

  Future<void> updateNickname(String nickname) async {
    if (!signedIn || busy) throw const ApiFailure('다시 로그인해 주세요.');
    final generation = _generation;
    final result = await _api.updateNickname(nickname);
    if (!isCurrent(generation)) return;
    member = result;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  Future<void> logout() => _endSession(expired: false);

  Future<void> expire(int generation) async {
    if (!isCurrent(generation) || _token == null) return;
    await _endSession(expired: true);
  }

  Future<void> _endSession({required bool expired}) async {
    if (_disposed || _token == null || (!expired && busy)) return;
    final previousBusy = busy;
    busy = true;
    final endingGeneration = _generation;
    final previousToken = _token;
    _token = null;
    _notify();
    try {
      await _storage.clear();
    } catch (_) {
      if (isCurrent(endingGeneration)) _token = previousToken;
      busy = previousBusy;
      _notify();
      rethrow;
    }
    busy = previousBusy;
    if (!isCurrent(endingGeneration)) return;
    _generation++;
    member = null;
    loginNickname = null;
    memberStatus = MemberLoadStatus.idle;
    _ratings.clear();
    _expiredNotice = expired;
    _status = AuthStatus.signedOut;
    _notify();
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
