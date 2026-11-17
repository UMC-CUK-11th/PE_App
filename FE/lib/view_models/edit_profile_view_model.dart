import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 닉네임 수정. 입력칸 문제(길이·중복)는 nicknameError, 그 외(네트워크)는 message로 나눕니다.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;

  bool get isSaving => status == EditProfileStatus.saving;

  static String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  void onNicknameChanged() {
    if (nicknameError == null) return;
    nicknameError = null;
    _notify();
  }

  /// 성공하면 true. 실패·세션 만료면 false를 돌려 화면이 pop하지 않게 합니다.
  Future<bool> save(String input) async {
    if (isSaving) return false; // 중복 탭 방지
    final version = _auth.sessionVersion;
    if (_disposed ||
        _auth.status != AuthStatus.signedIn ||
        _auth.member == null) {
      return false;
    }
    final nickname = input.trim();
    message = null;
    nicknameError = validateNickname(nickname);
    if (nicknameError != null) {
      _notify();
      return false;
    }
    // 자기 닉네임은 중복 검사에서 제외되므로 같은 값은 요청 없이 완료입니다.
    if (nickname == _auth.member?.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    _notify();

    bool stale() =>
        _disposed ||
        version != _auth.sessionVersion ||
        _auth.status != AuthStatus.signedIn;

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (stale()) return false;
      _auth.updateMember(updated); // 마이페이지가 바로 새 닉네임을 보여줍니다.
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (stale()) return false;
      status = EditProfileStatus.failure;
      switch (apiErrorCode(error)) {
        case 'AUTH401_2' || 'AUTH401_3' || 'AUTH401_4':
          // 안내와 이동은 로그인 화면과 Router가 처리합니다.
          await _auth.expireSession();
          return false;
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값은 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.'; // 로그아웃하지 않음
      }
    } catch (_) {
      if (stale()) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
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
