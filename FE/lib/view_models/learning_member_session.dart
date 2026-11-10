import 'package:flutter/foundation.dart';

/// 가입 응답의 회원 ID를 화면 간에 공유하는 학습용 메모리 상태.
class LearningMemberSession extends ChangeNotifier {
  int? _memberId;
  int? get memberId => _memberId;

  void start(int memberId) {
    _memberId = memberId;
    notifyListeners();
  }
}
