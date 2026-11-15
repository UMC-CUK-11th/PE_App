/// v5 중복 확인 응답. 공통 Wrapper 없이 { "available": bool }이 그대로 옵니다.
class CheckResult {
  const CheckResult({required this.available});

  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(available: json['available'] as bool);
  }
}
