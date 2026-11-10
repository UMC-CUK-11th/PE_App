import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/models/common_response.dart';
import 'package:movielog/models/member_models.dart';

// 수동 검증 전용 진입점. main.dart 앱에는 이 코드를 등록하지 않습니다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/sign_up_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/services/member_check_service.dart';
import 'package:movielog/services/rating_api_service.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/models/rating_dto.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/theme/app_theme.dart';

void main() => runApp(const PreviewApp());

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});
  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  late final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Preview()),
      GoRoute(
        path: '/movies',
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('프리뷰 · 폼 검증 완료')),
          body: Center(
            child: FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('프리뷰로 돌아가기'),
            ),
          ),
        ),
      ),
    ],
  );
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => LearningMemberSession(),
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: _router),
  );
}

class _Checks extends MemberCheckService {
  _Checks() : super(Dio());
  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async => const CommonResponse('COMMON201', '가입 완료', SignUpResult(42));

  bool fail = false;
  @override
  Future<bool> checkNickname(String value) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/preview'));
    }
    return value != '제임스';
  }

  @override
  Future<bool> checkEmail(String value) =>
      checkNickname(value == 'test@example.com' ? '제임스' : value);
}

class _Ratings extends RatingApiService {
  _Ratings(this.mode) : super(Dio());
  final String mode;
  @override
  Future<List<RatingDto>> fetchMyRatings(int id) async {
    if (mode == '로딩') return Completer<List<RatingDto>>().future;
    if (mode == '오류') {
      throw DioException(requestOptions: RequestOptions(path: '/preview'));
    }
    return [];
  }
}

class Preview extends StatefulWidget {
  const Preview({super.key});
  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  final checks = _Checks();
  final movies = TmdbMovieService(Dio());
  MyRatingsViewModel? ratings;
  String mode = '회원가입';
  int calls = 0;
  void select(String value) {
    final old = ratings;
    setState(() {
      mode = value;
      ratings = value == '회원가입' || value == '버튼 너비'
          ? null
          : (MyRatingsViewModel(_Ratings(value), movies, memberId: 1)..load());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  @override
  void dispose() {
    ratings?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFF1CC),
            child: const Text(
              '6주차 검증 전용 · 합성 응답 · 실제 API 결과가 아닙니다.',
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in ['회원가입', '로딩', '빈 목록', '오류', '버튼 너비'])
                  OutlinedButton(
                    onPressed: () => select(value),
                    child: Text(value),
                  ),
                FilterChip(
                  label: const Text('중복 확인 통신 실패'),
                  selected: checks.fail,
                  onSelected: (value) => setState(() => checks.fail = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (mode) {
              '회원가입' => Provider<MemberCheckService>.value(
                value: checks,
                child: const SignUpScreen(),
              ),
              '버튼 너비' => Center(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('width: null · 내용에 맞춤'),
                      const SizedBox(height: 8),
                      MovieLogButton(
                        label: '중복 확인',
                        onPressed: () => setState(() => calls++),
                      ),
                      const SizedBox(height: 20),
                      const Text('width: double.infinity · 부모의 320px'),
                      const SizedBox(height: 8),
                      MovieLogButton(
                        label: '가입하기',
                        width: double.infinity,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 20),
                      const Text('width: 160 · 고정 너비'),
                      const SizedBox(height: 8),
                      MovieLogButton(
                        label: '다시 불러오기',
                        width: 160,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 20),
                      const Text('isLoading: true · 클릭 차단'),
                      const SizedBox(height: 8),
                      MovieLogButton(
                        label: '중복 확인',
                        width: 160,
                        isLoading: true,
                        onPressed: () => setState(() => calls++),
                      ),
                      Text('클릭 처리 횟수: $calls'),
                    ],
                  ),
                ),
              ),
              _ => ChangeNotifierProvider.value(
                value: ratings!,
                child: const MyRatingsScreen(),
              ),
            },
          ),
        ],
      ),
    ),
  );
}
