/// [convert]를 동시에 최대 [concurrency]개만 실행하고, 결과는 입력 순서대로 돌려줍니다.
Future<List<R>> mapBounded<T, R>(
  Iterable<T> values,
  int concurrency,
  Future<R> Function(T value) convert,
) async {
  final input = values.toList(growable: false);
  if (input.isEmpty) return <R>[];
  if (concurrency <= 0) {
    throw ArgumentError.value(concurrency, 'concurrency', 'must be positive');
  }
  final output = List<R?>.filled(input.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < input.length) {
      final index = next++;
      output[index] = await convert(input[index]);
    }
  }

  await Future.wait(
    List.generate(concurrency.clamp(1, input.length), (_) => worker()),
  );
  return output.cast<R>();
}
