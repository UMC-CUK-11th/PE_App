import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

// 두 입력란이 독립적인 요청 버전과 중복값을 기억합니다.
class _CheckField {
  String current = '';
  String? duplicated;
  CheckStatus status = CheckStatus.idle;
  String? error;
  int version = 0;
}

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberCheckService _service;
  final _nickname = _CheckField();
  final _email = _CheckField();
  bool _disposed = false;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  CheckStatus get emailCheckStatus => _email.status;
  String? get nicknameErrorText => _nickname.error;
  String? get emailErrorText => _email.error;
  bool get bothAvailable =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  static String? validateNickname(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '닉네임을 입력해주세요.';
    if (text.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    if (text.length > 12) return '닉네임은 12자 이하여야 합니다.';
    return null;
  }

  static String? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '이메일을 입력해주세요.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  bool _canCheck(_CheckField field, String? validation) =>
      validation == null &&
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated;
  bool get canCheckNickname =>
      _canCheck(_nickname, validateNickname(_nickname.current));
  bool get canCheckEmail => _canCheck(_email, validateEmail(_email.current));

  void _changed(_CheckField field, String value, String label) {
    final current = value.trim();
    if (current == field.current) return;
    field.current = current;
    field.version++; // 입력이 바뀌면 이전 요청의 늦은 응답은 무효입니다.
    final duplicated =
        field.current.isNotEmpty && field.current == field.duplicated;
    field.status = duplicated ? CheckStatus.duplicated : CheckStatus.idle;
    field.error = duplicated ? '이미 사용 중인 $label입니다.' : null;
    if (!_disposed) notifyListeners();
  }

  void onNicknameChanged(String value) => _changed(_nickname, value, '닉네임');
  void onEmailChanged(String value) => _changed(_email, value, '이메일');

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, '닉네임', canCheckNickname, _service.checkNickname);
  Future<void> checkEmail(String value) =>
      _check(_email, value, '이메일', canCheckEmail, _service.checkEmail);

  Future<void> _check(
    _CheckField field,
    String value,
    String label,
    bool allowed,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (_disposed || !allowed || requested != field.current) return;
    final version = ++field.version;
    field.status = CheckStatus.checking;
    field.error = null;
    notifyListeners();
    try {
      final available = await request(requested);
      if (_disposed || version != field.version || requested != field.current) {
        return;
      }
      field.status = available ? CheckStatus.available : CheckStatus.duplicated;
      field.error = available ? null : '이미 사용 중인 $label입니다.';
      if (!available) field.duplicated = requested;
    } on DioException {
      if (_disposed || version != field.version) return;
      field.status = CheckStatus.error;
      field.error = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    } catch (_) {
      if (_disposed || version != field.version) return;
      field.status = CheckStatus.error;
      field.error = '응답 형식을 확인하지 못했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == field.version) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.version++;
    _email.version++;
    super.dispose();
  }
}
