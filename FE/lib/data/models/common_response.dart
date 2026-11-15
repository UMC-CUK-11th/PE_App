class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool? ?? false,
      code: json['code'] as String? ?? 'COMMON500',
      message: json['message'] as String? ?? '요청에 실패했습니다.',
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }

  final bool isSuccess;
  final String code;
  final String message;
  final T? result;
}
