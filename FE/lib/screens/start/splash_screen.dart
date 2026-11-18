import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/movielog_button.dart';

/// 1주차 시작 화면 레이아웃을 재사용한 스플래시. 하단 시작하기 버튼 자리에
/// 세션 확인 중이면 인디케이터, 확인 실패면 다시 시도 버튼을 둡니다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  final String? message;

  /// null이면 확인 중(initializing), 있으면 재시도 필요(retryRequired)입니다.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'FLUTTER 8주차',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 72,
                height: 72,
                semanticsLabel: 'MovieLog 로고',
              ),
              const SizedBox(height: 32),
              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 12),
              Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
              ),
              const Spacer(),
              // 하단 시작하기 버튼 자리. 높이를 맞춰 상태가 바뀌어도 로고가 튀지 않게 합니다.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 104),
                child: onRetry == null
                    ? const SizedBox(
                        height: 104,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.violet,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message ?? '로그인 상태를 확인하지 못했어요.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          MovieLogButton(
                            label: '다시 시도',
                            width: double.infinity,
                            height: 56,
                            onPressed: onRetry,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
