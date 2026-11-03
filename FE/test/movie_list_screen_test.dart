import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'support/test_tmdb_service.dart';

void main() {
  Future<MovieListViewModel> pump(
    WidgetTester tester,
    TestTmdbService service,
  ) async {
    final vm = MovieListViewModel(
      service,
      preferences: MemoryMovieListPreferences(),
    );
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: MovieListScreen()),
      ),
    );
    vm.initialize();
    await tester.pump();
    return vm;
  }

  testWidgets('Loading 중 필터와 새로고침이 잠긴다', (tester) async {
    final service = TestTmdbService()..delay = const Duration(seconds: 1);
    await pump(tester, service);
    expect(find.byKey(const ValueKey('movie-list-loading')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('genre-filter-button')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '전체'))
          .onSelected,
      isNull,
    );
    await tester.drag(
      find.byKey(const ValueKey('movie-list-loading')),
      const Offset(0, 300),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(service.calls, 1);
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
  });

  testWidgets('빈 목록도 새로고침할 수 있다', (tester) async {
    final service = TestTmdbService()..empty = true;
    await pump(tester, service);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-list-empty')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('movie-list-empty')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(service.calls, 2);
  });

  testWidgets('실패 Dialog 취소는 기존 목록 유지, 재시도는 회복', (tester) async {
    final service = TestTmdbService();
    final vm = await pump(tester, service);
    await tester.pumpAndSettle();
    service.fail = true;
    await vm.load();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(vm.movies.length, 6);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
    await vm.load();
    await tester.pumpAndSettle();
    service.fail = false;
    await tester.tap(find.text('재시도'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
    expect(service.requestedPages, [1, 1, 1, 1]);
  });

  testWidgets('첫 요청 실패 뒤 재시도하면 Success', (tester) async {
    final service = TestTmdbService()..fail = true;
    await pump(tester, service);
    await tester.pumpAndSettle();
    expect(find.text('영화 요청 실패'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-list-error')), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
  });
}
