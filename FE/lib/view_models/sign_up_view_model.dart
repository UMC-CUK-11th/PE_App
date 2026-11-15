import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/movielog_member_service.dart';

enum DuplicateCheck { unchecked, checking, available, taken, failed }

/// 회원가입 화면의 닉네임·이메일 중복 체크 상태를 관리합니다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final MovieLogMemberService _service;

  DuplicateCheck nickname = DuplicateCheck.unchecked;
  DuplicateCheck email = DuplicateCheck.unchecked;

  // 확인 중에 입력이 바뀌면 이전 응답을 버리기 위해 마지막 요청 값을 기억합니다.
  String? _pendingNickname;
  String? _pendingEmail;
  bool _disposed = false;

  bool get bothAvailable =>
      nickname == DuplicateCheck.available && email == DuplicateCheck.available;

  Future<void> checkNickname(String value) async {
    _pendingNickname = value;
    nickname = DuplicateCheck.checking;
    notifyListeners();
    final result = await _check(() => _service.isNicknameAvailable(value));
    if (_disposed || _pendingNickname != value) return;
    nickname = result;
    notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    _pendingEmail = value;
    email = DuplicateCheck.checking;
    notifyListeners();
    final result = await _check(() => _service.isEmailAvailable(value));
    if (_disposed || _pendingEmail != value) return;
    email = result;
    notifyListeners();
  }

  /// 입력이 바뀌면 이전 확인 결과는 더 이상 유효하지 않습니다.
  void nicknameChanged() {
    _pendingNickname = null;
    if (nickname == DuplicateCheck.unchecked) return;
    nickname = DuplicateCheck.unchecked;
    notifyListeners();
  }

  void emailChanged() {
    _pendingEmail = null;
    if (email == DuplicateCheck.unchecked) return;
    email = DuplicateCheck.unchecked;
    notifyListeners();
  }

  Future<DuplicateCheck> _check(Future<bool> Function() request) async {
    try {
      return await request() ? DuplicateCheck.available : DuplicateCheck.taken;
    } on DioException catch (error) {
      debugPrint('중복 체크 실패: ${error.response?.statusCode} ${error.message}');
      return DuplicateCheck.failed;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
