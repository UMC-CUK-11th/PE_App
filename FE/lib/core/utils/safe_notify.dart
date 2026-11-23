import 'package:flutter/foundation.dart';

/// 화면이 사라진 뒤 도착한 응답이 notifyListeners()를 부르지 않게 막습니다.
mixin SafeNotify on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
