import 'package:flutter/foundation.dart';

class LearningMemberSession extends ChangeNotifier {
  LearningMemberSession({int? initialMemberId, String? initialAccessToken})
    : _memberId = initialMemberId,
      _accessToken = initialAccessToken;

  int? _memberId;
  String? _accessToken;
  int? get memberId => _memberId;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _memberId != null && _accessToken != null;

  void setMemberId(int memberId) {
    if (_memberId == memberId) return;
    _memberId = memberId;
    notifyListeners();
  }

  void setAuthenticatedMember({
    required int memberId,
    required String accessToken,
  }) {
    if (_memberId == memberId && _accessToken == accessToken) return;
    _memberId = memberId;
    _accessToken = accessToken;
    notifyListeners();
  }
}
