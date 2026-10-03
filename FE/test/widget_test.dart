import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';
import 'package:movielog/screens/sign_up/sign_up_validators.dart';

Finder _field(int index) => find.byType(TextFormField).at(index);

Finder get _submitButton => find.widgetWithText(ElevatedButton, '가입하기');

bool _isSubmitEnabled(WidgetTester tester) {
  return tester.widget<ElevatedButton>(_submitButton).onPressed != null;
}

void _setScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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

  group('SignUpScreen', () {
    testWidgets('처음에는 가입 버튼이 비활성화되어 있다', (tester) async {
      _setScreenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const MovieLogApp());

      expect(find.text('회원가입'), findsOneWidget);
      expect(_isSubmitEnabled(tester), isFalse);
    });

    testWidgets('잘못된 입력에는 한국어 오류 메시지를 표시한다', (tester) async {
      _setScreenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const MovieLogApp());

      await tester.enterText(_field(0), 'a');
      await tester.enterText(_field(1), 'test@');
      await tester.enterText(_field(2), '123');
      await tester.pump();

      expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
      expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
      expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
      expect(_isSubmitEnabled(tester), isFalse);
    });

    testWidgets('모든 입력이 유효하고 약관에 동의하면 버튼이 활성화된다', (tester) async {
      _setScreenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const MovieLogApp());

      await tester.enterText(_field(0), '무비러버');
      await tester.enterText(_field(1), 'movie@example.com');
      await tester.enterText(_field(2), 'password1');
      await tester.pump();
      expect(_isSubmitEnabled(tester), isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_isSubmitEnabled(tester), isTrue);

      await tester.tap(_submitButton);
      await tester.pump();
      expect(find.text('회원가입 정보가 확인되었습니다.'), findsOneWidget);
    });

    testWidgets('비밀번호 표시 버튼으로 obscureText를 전환한다', (tester) async {
      _setScreenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const MovieLogApp());

      EditableText passwordText() => tester.widget<EditableText>(
            find.descendant(of: _field(2), matching: find.byType(EditableText)),
          );

      expect(passwordText().obscureText, isTrue);
      await tester.tap(find.byTooltip('비밀번호 표시'));
      await tester.pump();
      expect(passwordText().obscureText, isFalse);
    });

    testWidgets('키보드가 열려도 Overflow가 발생하지 않는다', (tester) async {
      _setScreenSize(tester, const Size(390, 844));
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(const MovieLogApp());
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
      _setScreenSize(tester, const Size(1280, 800));
      await tester.pumpWidget(const MovieLogApp());

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_field(0)).width, lessThanOrEqualTo(560));
    });
  });
}
