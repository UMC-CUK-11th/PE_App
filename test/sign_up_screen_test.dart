import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie_log_app.dart';

void main() {
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('유효한 입력과 약관 동의 후 가입 버튼이 활성화된다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));

    final fieldHeights = List.generate(
      3,
      (index) => tester.getSize(fields.at(index)).height,
    );
    expect(fieldHeights.toSet(), hasLength(1));

    ElevatedButton signUpButton() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '가입하기'),
    );

    expect(signUpButton().onPressed, isNull);

    await tester.enterText(fields.at(0), '노바');
    await tester.enterText(fields.at(1), 'nova@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.pump();

    expect(find.text('노바'), findsOneWidget);
    expect(find.text('nova@example.com'), findsOneWidget);
    expect(find.byTooltip('비밀번호 표시'), findsOneWidget);

    await tester.tap(find.byTooltip('비밀번호 표시'));
    await tester.pump();
    expect(find.byTooltip('비밀번호 숨기기'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(find.byTooltip('비밀번호 숨기기'), findsNothing);
    expect(find.byKey(const ValueKey('password-valid-icon')), findsOneWidget);

    await tester.tap(fields.at(2));
    await tester.pump();
    expect(find.byTooltip('비밀번호 숨기기'), findsOneWidget);
    expect(find.byKey(const ValueKey('password-valid-icon')), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.byKey(const ValueKey('password-valid-icon')), findsOneWidget);
    expect(signUpButton().onPressed, isNotNull);

    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
  });

  testWidgets('입력값이 잘못되면 한국어 오류 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '노');
    await tester.enterText(fields.at(1), 'invalid-email');
    await tester.enterText(fields.at(2), 'short');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('낮은 모바일 화면에서 입력창을 선택해도 overflow가 없다', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MovieLogApp());

    final backIconCenter = tester.getCenter(
      find.byKey(const ValueKey('common-app-bar-back-icon')),
    );
    final appBarTitleCenter = tester.getCenter(find.text('회원가입'));
    expect(backIconCenter.dy, closeTo(appBarTitleCenter.dy - 2, 0.01));

    final passwordField = find.byType(TextFormField).at(2);
    await tester.ensureVisible(passwordField);
    await tester.tap(passwordField);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('너비 700 이상에서 넓은 화면 회원가입 레이아웃을 사용한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('MovieLog에 오신 것을 환영합니다!'), findsOneWidget);
    expect(find.text('영화로운 닉네임을 입력하세요'), findsOneWidget);
    expect(find.text('example@movielog.com'), findsOneWidget);
    expect(find.text('영문, 숫자 포함 8자 이상'), findsOneWidget);

    final containerSize = tester.getSize(
      find.byKey(const ValueKey('wide-sign-up-container')),
    );
    expect(containerSize, const Size(560, 622));

    final fields = find.byType(TextFormField);
    final editableTexts = find.byType(EditableText);
    final inputDecorators = find.byType(InputDecorator);
    final initialFieldRects = List.generate(
      3,
      (index) => tester.getRect(fields.at(index)),
    );
    for (var index = 0; index < 3; index++) {
      expect(tester.getSize(fields.at(index)), const Size(496, 42));
      expect(tester.getSize(inputDecorators.at(index)), const Size(496, 42));
      final editableText = tester.widget<EditableText>(editableTexts.at(index));
      final inputDecorator = tester.widget<InputDecorator>(
        inputDecorators.at(index),
      );
      expect(inputDecorator.decoration.suffixIcon, isNotNull);
      expect(editableText.style.fontFamily, 'Manrope');
      expect(editableText.style.fontSize, 14);
      expect(editableText.style.height, 20 / 14);
      expect(inputDecorator.decoration.hintStyle?.fontSize, 14);
      expect(inputDecorator.decoration.hintStyle?.height, 20 / 14);
    }

    await tester.enterText(fields.at(0), 'a');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('wide-sign-up-container'))),
      const Size(560, 622),
    );
    for (var index = 0; index < 3; index++) {
      expect(tester.getRect(fields.at(index)), initialFieldRects[index]);
      expect(tester.getSize(fields.at(index)), const Size(496, 42));
      expect(tester.getSize(inputDecorators.at(index)), const Size(496, 42));
    }
    expect(tester.takeException(), isNull);
  });
}
