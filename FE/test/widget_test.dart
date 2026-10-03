import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/genre_filter.dart';
import 'package:movielog/data/genre_preference.dart';
import 'package:movielog/data/movie.dart';
import 'package:movielog/data/movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movies/genre_chip_bar.dart';
import 'package:movielog/screens/movies/genre_filter_sheet.dart';
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
  FakeMovieService service = const FakeMovieService(delay: Duration.zero),
  GenrePreference? preference,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: AppRouter.createRouter(
        initialLocation: location,
        movieService: service,
        genrePreference: preference ?? InMemoryGenrePreference(),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
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

      await tester.tap(
        find.descendant(
          of: find.byType(GenreFilterSheet),
          matching: find.text('SF'),
        ),
      );
      await tester.pump();
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
      expect(find.text('장르: SF'), findsOneWidget);
    });
  });

  group('FakeMovieService', () {
    const service = FakeMovieService(delay: Duration.zero);

    test('성공 모드는 Mock 영화 목록을 반환한다', () async {
      expect(await service.fetchMovies(), movies);
    });

    test('빈 목록 모드는 빈 List를 반환한다', () async {
      expect(await service.fetchMovies(mode: MovieLoadMode.empty), isEmpty);
    });

    test('실패 모드는 MovieLoadException으로 완료된다', () {
      expect(
        service.fetchMovies(mode: MovieLoadMode.failure),
        throwsA(isA<MovieLoadException>()),
      );
    });
  });

  group('비동기 영화 목록', () {
    testWidgets('진입하면 Loading을 먼저 보여주고 1초 뒤 Grid를 표시한다', (tester) async {
      await _pumpApp(
        tester,
        location: '/movies',
        service: const FakeMovieService(),
        settle: false,
      );
      await tester.pump();

      expect(find.text('영화를 불러오는 중이에요'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('영화를 불러오는 중이에요'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('빈 목록 모드에서는 Empty 화면을 보여준다', (tester) async {
      await _pumpApp(tester, location: '/movies');

      await tester.tap(find.byTooltip('불러오기 상태'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('빈 목록'));
      await tester.pumpAndSettle();

      expect(find.text('불러올 영화가 없어요'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('실패하면 Error 화면을 보여주고 다시 시도하면 목록을 불러온다', (tester) async {
      await _pumpApp(tester, location: '/movies');

      await tester.tap(find.byTooltip('불러오기 상태'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('실패'));
      await tester.pumpAndSettle();

      expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
      expect(find.textContaining('MovieLoadException'), findsNothing);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('영화를 불러오지 못했어요'), findsNothing);
    });

    testWidgets('장르 Chip을 누르면 목록이 바뀌고 선택 장르를 저장한다', (tester) async {
      final preference = InMemoryGenrePreference();
      await _pumpApp(tester, location: '/movies', preference: preference);

      await tester.tap(find.widgetWithText(FilterChip, 'SF'));
      await tester.pumpAndSettle();

      expect(find.text('장르: SF'), findsOneWidget);
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
      expect(preference.saved, {'SF'});

      final comedyChip = find.widgetWithText(FilterChip, '코미디');
      await tester.scrollUntilVisible(
        comedyChip,
        100,
        scrollable: find.descendant(
          of: find.byType(GenreChipBar),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(comedyChip);
      await tester.pumpAndSettle();
      expect(find.text('선택한 장르의 영화가 없어요'), findsNothing);

      final sfChip = find.widgetWithText(FilterChip, 'SF');
      await tester.scrollUntilVisible(
        sfChip,
        -100,
        scrollable: find.descendant(
          of: find.byType(GenreChipBar),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(sfChip);
      await tester.pumpAndSettle();
      expect(find.text('선택한 장르의 영화가 없어요'), findsOneWidget);
      expect(preference.saved, {'코미디'});
    });

    testWidgets('앱을 다시 실행하면 저장된 장르를 복원한다', (tester) async {
      final preference = InMemoryGenrePreference({'애니메이션'});
      await _pumpApp(tester, location: '/movies', preference: preference);

      expect(find.text('장르: 애니메이션'), findsOneWidget);
      expect(find.text('기억의 숲'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
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
