import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  Future<dynamic> pumpRoute(WidgetTester tester, String initialLocation) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final router = AppRouter.createRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(router: router));
    await tester.pumpAndSettle();
    return router;
  }

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetViewInsets();
  });

  testWidgets('시작하기 버튼은 회원가입 화면으로 이동한다', (tester) async {
    await pumpRoute(tester, '/start');

    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byTooltip('뒤로 가기'), findsNothing);
  });

  testWidgets('NavigationBar로 홈, 영화, 마이 화면을 전환한다', (tester) async {
    await pumpRoute(tester, '/home');

    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
    await tester.tap(find.text('영화').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
  });

  testWidgets('장르 Chip 선택은 Query Parameter와 목록에 반영된다', (tester) async {
    final router = await pumpRoute(tester, '/movies');

    expect(find.byKey(const ValueKey('genre-filter-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('genre-chip-로맨스')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('genre-chip-SF')));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.queryParameters['genre'],
      'SF',
    );
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('genre-filter-bar')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('genre-chip-다큐멘터리')), findsOneWidget);
  });

  testWidgets('영화 카드는 상세 화면으로 이동하고 뒤로 돌아온다', (tester) async {
    await pumpRoute(tester, '/movies');

    tester
        .widget<GestureDetector>(find.byKey(const ValueKey('movie-card-1')))
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
  });

  testWidgets('상세 화면의 즐겨찾기, 별점 Dialog와 초기화를 사용할 수 있다', (tester) async {
    await pumpRoute(tester, '/movies/1');

    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.textContaining('4.5'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('favorite-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('favorite-button')));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('open-rating-dialog-button')),
    );
    await tester.tap(find.byKey(const ValueKey('open-rating-dialog-button')));
    await tester.pumpAndSettle();
    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);

    final confirmButton = find.widgetWithText(ElevatedButton, '확인');
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);

    final ratingBar = find.byType(RatingBar);
    tester.widget<RatingBar>(ratingBar).onRatingUpdate(3.5);
    await tester.pumpAndSettle();
    expect(find.text('다시 선택하기'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNotNull);

    await tester.tap(find.text('다시 선택하기'));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
  });
}
