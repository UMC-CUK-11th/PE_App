import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/genre_filter.dart';
import 'package:movielog/data/movie.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/sign_up/sign_up_validators.dart';
import 'package:movielog/theme/app_theme.dart';

const _homeHeadline = '오늘은 어떤\n영화를 볼까요?';

Finder _field(int index) => find.byType(TextFormField).at(index);

Finder get _submitButton => find.widgetWithText(ElevatedButton, '가입하기');

bool _isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<ButtonStyleButton>(button).onPressed != null;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  String location = '/start',
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: AppRouter.createRouter(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillValidSignUp(WidgetTester tester) async {
  await tester.enterText(_field(0), '무비러버');
  await tester.enterText(_field(1), 'movie@example.com');
  await tester.enterText(_field(2), 'password1');
  await tester.pump();
}

void main() {
  group('SignUpValidators', () {
    test('닉네임은 비어 있거나 2자 미만이면 오류를 반환한다', () {
      expect(SignUpValidators.nickname(''), '닉네임을 입력해주세요.');
      expect(SignUpValidators.nickname(' a '), '닉네임은 2자 이상이어야 합니다.');
      expect(SignUpValidators.nickname('무비'), isNull);
    });

    test('이메일 형식이 아니면 오류를 반환한다', () {
      expect(SignUpValidators.email(''), '이메일을 입력해주세요.');
      expect(SignUpValidators.email('test@'), '올바른 이메일 형식이 아닙니다.');
      expect(SignUpValidators.email('movie@example.com'), isNull);
    });

    test('비밀번호가 8자 미만이면 오류를 반환한다', () {
      expect(SignUpValidators.password(''), '비밀번호를 입력해주세요.');
      expect(SignUpValidators.password('123'), '비밀번호는 8자 이상이어야 합니다.');
      expect(SignUpValidators.password('12345678'), isNull);
    });
  });

  group('Mock 데이터와 장르 필터', () {
    test('ID로 같은 Mock Movie를 찾는다', () {
      expect(findMovieById(1)?.title, '별빛 아래 우리');
      expect(findMovieById(999), isNull);
    });

    test('장르 Query Parameter를 만들고 다시 읽는다', () {
      final location = moviesLocation({'SF', '드라마'});
      final uri = Uri.parse(location);

      expect(uri.path, '/movies');
      expect(parseGenres(uri.queryParameters[genresQueryKey]), {'드라마', 'SF'});
      expect(moviesLocation({}), '/movies');
      expect(filterMoviesByGenres({'SF'}).map((m) => m.title), ['우주의 끝에서']);
    });
  });

  group('SignUpScreen', () {
    testWidgets('처음에는 가입 버튼이 비활성화되어 있고 뒤로가기 버튼이 없다', (tester) async {
      await _pumpApp(tester, location: '/register');

      expect(find.text('회원가입'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(_isEnabled(tester, _submitButton), isFalse);
    });

    testWidgets('잘못된 입력에는 한국어 오류 메시지를 표시한다', (tester) async {
      await _pumpApp(tester, location: '/register');

      await tester.enterText(_field(0), 'a');
      await tester.enterText(_field(1), 'test@');
      await tester.enterText(_field(2), '123');
      await tester.pump();

      expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
      expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
      expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
      expect(_isEnabled(tester, _submitButton), isFalse);
    });

    testWidgets('유효한 입력과 약관 동의 후 가입하면 홈으로 이동한다', (tester) async {
      await _pumpApp(tester, location: '/register');

      await _fillValidSignUp(tester);
      expect(_isEnabled(tester, _submitButton), isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_isEnabled(tester, _submitButton), isTrue);

      await tester.tap(_submitButton);
      await tester.pumpAndSettle();

      expect(find.text(_homeHeadline), findsOneWidget);
      expect(find.text('회원가입이 완료되었습니다.'), findsOneWidget);
    });

    testWidgets('비밀번호 표시 버튼으로 obscureText를 전환한다', (tester) async {
      await _pumpApp(tester, location: '/register');

      EditableText passwordText() => tester.widget<EditableText>(
            find.descendant(of: _field(2), matching: find.byType(EditableText)),
          );

      expect(passwordText().obscureText, isTrue);
      await tester.tap(find.byTooltip('비밀번호 표시'));
      await tester.pump();
      expect(passwordText().obscureText, isFalse);
    });

    testWidgets('키보드가 열려도 Overflow가 발생하지 않는다', (tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.resetViewInsets);
      await _pumpApp(tester, location: '/register');

      await tester.enterText(_field(0), 'a');
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _submitButton,
        100,
        scrollable: find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(_submitButton, findsOneWidget);
    });

    testWidgets('넓은 화면에서는 Form 너비를 560으로 제한한다', (tester) async {
      await _pumpApp(tester, location: '/register', size: const Size(1280, 800));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_field(0)).width, lessThanOrEqualTo(560));
    });
  });

  group('화면 전환', () {
    testWidgets('시작하기를 누르면 회원가입 화면으로 이동한다', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('회원가입'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('홈의 상세보기로 상세에 진입하고 뒤로 돌아온다', (tester) async {
      await _pumpApp(tester, location: '/home');

      await tester.tap(find.text('상세보기'));
      await tester.pumpAndSettle();
      expect(find.text('Cinema Archive'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text(_homeHeadline), findsOneWidget);
    });

    testWidgets('NavigationBar로 영화와 마이 탭을 전환한다', (tester) async {
      await _pumpApp(tester, location: '/home');

      await tester.tap(find.text('영화'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );

      await tester.tap(find.text('마이'));
      await tester.pumpAndSettle();
      expect(find.text('내 프로필'), findsOneWidget);
    });

    testWidgets('BottomSheet에서 선택한 장르로 목록을 필터링한다', (tester) async {
      await _pumpApp(tester, location: '/movies');

      await tester.tap(find.byTooltip('장르 필터'));
      await tester.pumpAndSettle();
      expect(find.text('장르 필터'), findsOneWidget);

      await tester.tap(find.text('SF'));
      await tester.pump();
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
      expect(find.text('장르: SF'), findsOneWidget);
    });
  });

  group('MovieDetailScreen', () {
    testWidgets('즐겨찾기를 누르면 아이콘이 바뀌고 Snackbar를 표시한다', (tester) async {
      await _pumpApp(tester, location: '/movies/1');

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      await tester.tap(find.text('즐겨찾기'));
      await tester.pump();

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.text('즐겨찾기에 추가했어요.'), findsOneWidget);
    });

    testWidgets('평점 Dialog에서 별점을 고르면 확인 버튼이 활성화되고 저장된다', (tester) async {
      await _pumpApp(tester, location: '/movies/1');

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();

      final confirm = find.widgetWithText(ElevatedButton, '확인');
      expect(_isEnabled(tester, confirm), isFalse);

      final thirdStar = find
          .descendant(of: find.byType(Dialog), matching: find.byIcon(Icons.star))
          .at(2);
      await tester.tapAt(tester.getCenter(thirdStar) + const Offset(10, 0));
      await tester.pump();
      expect(_isEnabled(tester, confirm), isTrue);
      expect(find.text('다시 선택하기'), findsOneWidget);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('내 평점 3.0'), findsOneWidget);
    });

    testWidgets('다시 선택하기를 누르면 평점이 초기화된다', (tester) async {
      await _pumpApp(tester, location: '/movies/1');

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();

      final stars = find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.star),
      );
      await tester.tapAt(tester.getCenter(stars.at(3)) + const Offset(10, 0));
      await tester.pump();

      await tester.tap(find.text('다시 선택하기'));
      await tester.pump();

      final confirm = find.widgetWithText(ElevatedButton, '확인');
      expect(_isEnabled(tester, confirm), isFalse);
      expect(find.text('다시 선택하기'), findsNothing);
    });

    testWidgets('없는 영화 ID면 안내 문구를 표시한다', (tester) async {
      await _pumpApp(tester, location: '/movies/999');

      expect(find.text('영화를 찾을 수 없어요.'), findsOneWidget);
    });
  });
}
