import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import 'movielog_button.dart';

/// 목록 아래 footer: 더 보기 / 추가 로딩 / 같은 page 재시도 / 끝.
/// [showLoadMoreButton]이 false면(무한 스크롤) 정상 상태에서는 버튼 없이 로딩만 보여줍니다.
class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({
    super.key,
    required this.viewModel,
    this.showLoadMoreButton = true,
  });

  final PagedMoviesViewModel viewModel;
  final bool showLoadMoreButton;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final error = vm.loadMoreError;

    if (!vm.hasMore && !vm.isLoadingMore && error == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '더 이상 조회할 페이지가 없습니다.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
      );
    }
    if (!showLoadMoreButton && error == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: vm.isLoadingMore
              ? const CircularProgressIndicator(color: AppColors.violet)
              : const SizedBox(height: 36),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (error != null) ...[
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
          ],
          MovieLogButton(
            width: double.infinity,
            label: error == null ? '더 보기' : '다음 페이지 다시 시도',
            isLoading: vm.isLoadingMore,
            onPressed: vm.phase == LoadPhase.ready ? vm.loadNextPage : null,
          ),
        ],
      ),
    );
  }
}
