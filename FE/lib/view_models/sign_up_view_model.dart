import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/sign_up_models.dart';
import '../data/services/learning_member_session.dart';
import '../data/services/member_api_service.dart';

enum SubmitStatus { idle, submitting, success, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel({required this.service, required this.session});

  final MemberApiService service;
  final LearningMemberSession session;

  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;
  bool _disposed = false;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  void clearServerErrors() {
    if (isSubmitting ||
        (passwordErrorText == null && snackbarMessage == null)) {
      return;
    }
    passwordErrorText = null;
    snackbarMessage = null;
    submitStatus = SubmitStatus.idle;
    _notify();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (isSubmitting) return;
    submitStatus = SubmitStatus.submitting;
    passwordErrorText = null;
    snackbarMessage = null;
    _notify();
    try {
      final response = await service.signUp(request);
      final result = response.result;
      if (result == null) {
        throw const FormatException('회원가입 응답에 회원 ID가 없습니다.');
      }
      createdMemberId = result.memberId;
      session.setMemberId(result.memberId);
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;
      final message = memberApiErrorMessage(error);
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } on Object {
      submitStatus = SubmitStatus.error;
      snackbarMessage = '회원가입 응답을 확인하지 못했습니다. 다시 시도해 주세요.';
    }
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
