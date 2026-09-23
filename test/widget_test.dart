import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';

void main() {
  testWidgets('회원가입 화면 초기 렌더링 및 필수 입력/유효성 검증 테스트', (WidgetTester tester) async {
    // 1. 앱 실행 (초기 화면인 SignUpScreen 로드)
    await tester.pumpWidget(const MyApp());

    // 2. 화면에 MaterialApp 및 SignUpScreen이 정상적으로 로드되었는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SignUpScreen), findsOneWidget);

    // 3. 회원가입 폼 관련 주요 컴포넌트(입력 필드, 제출 버튼 등)가 존재하는지 확인
    // (프로젝트에서 사용하신 텍스트 필드나 버튼 레이블에 맞게 확인)
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('회원가입'), findsOneWidget); // 또는 '가입하기' 등 버튼 텍스트에 맞게 수정

    // 4. 입력값 없이 제출 버튼을 눌렀을 때 Validation 오류 메시지가 노출되는지 검증
    await tester.tap(find.text('회원가입'));
    await tester.pump();

    // 빈 값 검증 시 나타나는 에러 텍스트나 유효성 검사 실패 상태 확인
    // (예: 필수 입력 에러 메시지가 화면에 나타나는지 확인)
    expect(find.textContaining('필수'), findsWidgets); // 예시 에러 메시지 검증
  });
}