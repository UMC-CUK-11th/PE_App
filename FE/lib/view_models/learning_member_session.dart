import 'package:flutter/foundation.dart';

/// 회원가입 결과의 memberId를 앱 전체에서 공유하는 학습용 현재 회원 상태입니다.
/// 메모리에만 있어 앱을 재시작하면 사라집니다. memberId를 안다는 것은 인증이 아니며,
/// JWT 주차에 토큰 기반 식별로 바뀝니다.
class LearningMemberSession extends ChangeNotifier {
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
