import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/widgets/rating_dialog.dart';

void main() {
  Future<Future<bool?>> openDialog(
    WidgetTester tester,
    RatingSubmitCallback onSubmit,
  ) async {
    late Future<bool?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              result = showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => RatingDialog(
                  movieId: 550,
                  initialScore: 4,
                  onSubmit: onSubmit,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('취소하면 onSubmit 없이 false를 반환한다', (tester) async {
    var called = false;
    final result = await openDialog(tester, (_, _) async => called = true);

    await tester.tap(find.byKey(const ValueKey('rating-cancel-button')));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(called, isFalse);
    expect(find.byType(RatingDialog), findsNothing);
  });

  testWidgets('저장 실패 후에도 취소로 Dialog를 닫을 수 있다', (tester) async {
    final result = await openDialog(
      tester,
      (_, _) async => throw StateError('이미 이 영화에 평점을 남기셨습니다.'),
    );

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rating-cancel-button')));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('저장 중에는 취소 버튼이 비활성화된다', (tester) async {
    final completer = Completer<void>();
    await openDialog(tester, (_, _) => completer.future);

    await tester.tap(find.text('확인'));
    await tester.pump();

    final cancel = tester.widget<TextButton>(
      find.byKey(const ValueKey('rating-cancel-button')),
    );
    expect(cancel.onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
