import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

/// idle: 확인 전이거나 입력이 바뀌어 무효화됨 / checking: 요청 중
/// available: 사용 가능 / duplicated: 서버가 중복이라고 응답 / error: 통신 실패
enum CheckStatus { idle, checking, available, duplicated, error }

/// 닉네임·이메일 한 칸의 중복 확인 상태. 두 칸이 서로 영향을 주지 않도록 따로 둡니다.
class DuplicateCheckField {
  DuplicateCheckField(this._request, this._duplicatedMessage);

  final Future<bool> Function(String value) _request;
  final String _duplicatedMessage;

  CheckStatus status = CheckStatus.idle;
  String? errorText;

  String _current = '';
  // 마지막으로 "중복"이었던 값. 같은 값을 다시 입력하면 서버에 묻지 않고 바로 에러로 돌립니다.
  String? _lastDuplicated;
  int _version = 0;

  bool get canCheck =>
      _current.isNotEmpty &&
      status != CheckStatus.checking &&
      status != CheckStatus.duplicated;

  void changed(String value) {
    _current = value.trim();
    _version++; // 기다리던 이전 응답은 무시합니다.
    if (_lastDuplicated != null && _current == _lastDuplicated) {
      status = CheckStatus.duplicated;
      errorText = _duplicatedMessage;
    } else {
      status = CheckStatus.idle;
      errorText = null;
    }
  }

  /// 응답이 현재 입력에 대한 것이면 true를 돌려 화면 갱신이 필요함을 알립니다.
  Future<bool> check(String value, VoidCallback notify) async {
    final requested = value.trim();
    if (requested != _current || !canCheck) return false;

    final version = ++_version;
    status = CheckStatus.checking;
    errorText = null;
    notify();

    try {
      final available = await _request(requested);
      if (version != _version) return false;
      status = available ? CheckStatus.available : CheckStatus.duplicated;
      errorText = available ? null : _duplicatedMessage;
      if (!available) _lastDuplicated = requested;
    } on DioException catch (error) {
      if (version != _version) return false;
      debugPrint('중복 확인 실패: ${error.response?.statusCode} ${error.message}');
      status = CheckStatus.error;
      errorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    return true;
  }
}

/// 회원가입 화면의 닉네임·이메일 중복 확인을 담당합니다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(MemberCheckService service)
    : nickname = DuplicateCheckField(service.checkNickname, '이미 사용 중인 닉네임입니다.'),
      email = DuplicateCheckField(service.checkEmail, '이미 사용 중인 이메일입니다.');

  final DuplicateCheckField nickname;
  final DuplicateCheckField email;
  bool _disposed = false;

  bool get bothAvailable =>
      nickname.status == CheckStatus.available &&
      email.status == CheckStatus.available;

  void onNicknameChanged(String value) {
    nickname.changed(value);
    _notify();
  }

  void onEmailChanged(String value) {
    email.changed(value);
    _notify();
  }

  Future<void> checkNickname(String value) async {
    if (await nickname.check(value, _notify)) _notify();
  }

  Future<void> checkEmail(String value) async {
    if (await email.check(value, _notify)) _notify();
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
