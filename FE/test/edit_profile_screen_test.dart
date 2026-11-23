import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/learning_member_session.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/token_storage.dart';
import 'package:movielog/screens/edit_profile_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('닉네임 변경 후 뒤로 가면 변경 내용 확인 Dialog를 표시한다', (tester) async {
    final auth =
        AuthViewModel(
            MemberApiService(Dio()),
            LearningMemberSession(initialAccessToken: 'token'),
            MemoryTokenStorage('token'),
          )
          ..status = AuthStatus.signedIn
          ..memberStatus = MemberLoadStatus.success
          ..member = MemberInfo(
            memberId: 1,
            email: 'movie@example.com',
            nickname: '무비러버',
            createdAt: DateTime(2026, 10, 10),
          );
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: EditProfileScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).last, '새닉네임');
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();

    expect(find.text('변경 내용을 버릴까요?'), findsOneWidget);
    expect(find.text('계속 수정'), findsOneWidget);
    expect(find.text('나가기'), findsOneWidget);

    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(find.text('프로필 수정'), findsOneWidget);
  });
}
