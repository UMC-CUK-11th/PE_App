import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/models/member_rating.dart';
import '../data/services/member_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';

class Week05ApiScreen extends StatefulWidget {
  const Week05ApiScreen({required this.apiService, super.key});

  final MemberApiService apiService;

  @override
  State<Week05ApiScreen> createState() => _Week05ApiScreenState();
}

class _Week05ApiScreenState extends State<Week05ApiScreen> {
  final _nicknameController = TextEditingController(text: '수현');
  final _emailController = TextEditingController(text: 'noco@umc.com');
  final _memberIdController = TextEditingController(text: '1');

  bool? _nicknameAvailable;
  bool? _emailAvailable;
  List<MemberRating>? _ratings;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _memberIdController.dispose();
    super.dispose();
  }

  Future<void> _checkAllApis() async {
    final memberId = int.tryParse(_memberIdController.text.trim());
    if (memberId == null || memberId < 1) {
      setState(() => _errorMessage = '회원 ID는 1 이상의 숫자여야 합니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _nicknameAvailable = null;
      _emailAvailable = null;
      _ratings = null;
    });

    bool? nicknameAvailable;
    bool? emailAvailable;
    List<MemberRating>? ratings;
    final errors = <String>[];

    try {
      nicknameAvailable = await widget.apiService.isNicknameAvailable(
        _nicknameController.text.trim(),
      );
    } on Object catch (error) {
      errors.add('닉네임 API: ${_apiErrorMessage(error)}');
    }
    try {
      emailAvailable = await widget.apiService.isEmailAvailable(
        _emailController.text.trim(),
      );
    } on Object catch (error) {
      errors.add('이메일 API: ${_apiErrorMessage(error)}');
    }
    try {
      ratings = await widget.apiService.fetchRatings(memberId);
    } on Object catch (error) {
      errors.add('평점 API: ${_apiErrorMessage(error)}');
    }

    if (!mounted) return;
    setState(() {
      _nicknameAvailable = nicknameAvailable;
      _emailAvailable = emailAvailable;
      _ratings = ratings;
      _errorMessage = errors.isEmpty ? null : errors.join('\n');
      _isLoading = false;
    });
  }

  String _apiErrorMessage(Object error) {
    if (error is DioException) {
      return error.response?.data?.toString() ?? '백엔드 주소와 서버 상태를 확인해주세요.';
    }
    return '응답을 처리하지 못했습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '5주차 API 확인',
        titleStyle: AppTextStyles.signUpAppBarTitle,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('회원 API 연결 상태', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            const Text(
              '아래 버튼 한 번으로 닉네임, 이메일, 평점 API를 모두 호출합니다.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            _ApiInput(label: '닉네임', controller: _nicknameController),
            const SizedBox(height: 12),
            _ApiInput(
              label: '이메일',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _ApiInput(
              label: '회원 ID',
              controller: _memberIdController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isLoading ? null : _checkAllApis,
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isLoading ? '확인 중...' : '모든 API 확인'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _ResultCard(
                title: '요청 실패',
                value: _errorMessage!,
                color: AppColors.error,
              ),
            ],
            if (_nicknameAvailable != null) ...[
              const SizedBox(height: 16),
              _ResultCard(
                title: 'GET /members/nickname/{nickname}',
                value: 'available: $_nicknameAvailable',
              ),
            ],
            if (_emailAvailable != null) ...[
              const SizedBox(height: 12),
              _ResultCard(
                title: 'GET /members/email/{email}',
                value: 'available: $_emailAvailable',
              ),
            ],
            if (_ratings != null) ...[
              const SizedBox(height: 12),
              _ResultCard(
                title: 'GET /members/{memberId}/ratings?page=0&size=10',
                value: _ratings!.isEmpty
                    ? '평점 0개'
                    : _ratings!
                          .map(
                            (rating) =>
                                'movieId ${rating.movieId} · ${rating.score}점 · '
                                '${rating.comment ?? '코멘트 없음'}',
                          )
                          .join('\n'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApiInput extends StatelessWidget {
  const _ApiInput({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.value,
    this.color = AppColors.violet,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
