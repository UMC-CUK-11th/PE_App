import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.violet),
          SizedBox(height: 16),
          Text('영화를 불러오는 중이에요', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator가 동작하도록 빈 화면도 스크롤 가능한 영역으로 만듭니다.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_outlined, size: 48, color: AppColors.gray),
                  const SizedBox(height: 12),
                  Text(message, style: AppTextStyles.bodyMedium),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MovieListError extends StatelessWidget {
  const MovieListError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('영화를 불러오지 못했어요', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            const Text(
              '네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
