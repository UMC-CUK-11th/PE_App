import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, error }

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this.authViewModel);

  final AuthViewModel authViewModel;
  EditProfileStatus status = EditProfileStatus.idle;
  String? fieldError;
  String? message;

  bool get isSaving => status == EditProfileStatus.saving;

  Future<bool> save(String nickname) async {
    final value = nickname.trim();
    fieldError = switch (value.length) {
      < 2 => '닉네임은 2자 이상이어야 합니다.',
      > 12 => '닉네임은 12자 이하여야 합니다.',
      _ => null,
    };
    if (fieldError != null) {
      status = EditProfileStatus.error;
      notifyListeners();
      return false;
    }
    if (value == authViewModel.member?.nickname) return true;

    status = EditProfileStatus.saving;
    fieldError = null;
    message = null;
    notifyListeners();
    try {
      final result = await authViewModel.updateNickname(value);
      if (result == null) return false;
      status = EditProfileStatus.success;
      notifyListeners();
      return true;
    } on DioException catch (error) {
      status = EditProfileStatus.error;
      if (memberApiErrorCode(error) == 'MEMBER409_1') {
        fieldError = '이미 사용 중인 닉네임이에요.';
      } else {
        message = '프로필 저장에 실패했습니다. 다시 시도해주세요.';
      }
    } on Object {
      status = EditProfileStatus.error;
      message = '프로필 저장에 실패했습니다. 다시 시도해주세요.';
    }
    notifyListeners();
    return false;
  }

  void clearError() {
    if (fieldError == null && message == null) return;
    fieldError = null;
    message = null;
    status = EditProfileStatus.idle;
    notifyListeners();
  }
}
