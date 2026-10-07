import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:movielog/widgets/movie_list_states.dart';

void main() {
  Widget testApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('Loading 상태는 영화 카드 형태의 Skeleton을 표시한다', (tester) async {
    await tester.pumpWidget(testApp(const MovieListLoading()));

    expect(find.byKey(const ValueKey('movie-list-loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('영화 정보를 불러오는 중'), findsAtLeastNWidgets(2));
  });

  testWidgets('Empty 상태는 안내 문구를 표시한다', (tester) async {
    await tester.pumpWidget(testApp(const MovieListEmpty()));

    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('Error 상태는 내부 오류 대신 재시도 동작을 제공한다', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      testApp(MovieListError(onRetry: () => retryCount++)),
    );

    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    await tester.tap(find.text('다시 시도'));
    expect(retryCount, 1);
  });

  testWidgets('Success 상태는 기존 MovieGrid와 MovieCard를 재사용한다', (tester) async {
    await tester.pumpWidget(testApp(const MovieGrid(movies: mockMovies)));

    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('movie-card-1')), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
  });
}
