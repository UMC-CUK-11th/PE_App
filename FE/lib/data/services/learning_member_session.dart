import 'package:flutter/foundation.dart';

class LearningMemberSession extends ChangeNotifier {
  LearningMemberSession({int? initialMemberId}) : _memberId = initialMemberId;

  int? _memberId;
  int? get memberId => _memberId;

  void setMemberId(int memberId) {
    if (_memberId == memberId) return;
    _memberId = memberId;
    notifyListeners();
  }
}
