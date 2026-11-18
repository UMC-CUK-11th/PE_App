import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/favorite_detail_view_model.dart';

/// 영화 상세 제목 오른쪽의 북마크. 요청 중에는 이 자리에만 인디케이터를 보여주고,
/// 결과는 서버 응답을 확인한 뒤 Snackbar로 안내합니다.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    await vm.toggle();
    if (!context.mounted || vm.isDisposed) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            vm.errorMessage ??
                (vm.isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        final busy = vm.isLoading || vm.isSaving;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 48,
              child: busy
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.violet,
                        ),
                      ),
                    )
                  // 첫 여부 조회에 실패하면 같은 자리에서 다시 확인합니다.
                  : vm.hasLoadedStatus
                  ? IconButton(
                      tooltip: vm.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
                      color: AppColors.violet,
                      onPressed: () => _toggle(context, vm),
                      icon: Icon(
                        vm.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      ),
                    )
                  : IconButton(
                      tooltip: '즐겨찾기 여부 다시 확인',
                      color: AppColors.violet,
                      onPressed: vm.load,
                      icon: const Icon(Icons.refresh),
                    ),
            ),
            const Text('즐겨찾기', style: AppTextStyles.bodySmall),
          ],
        );
      },
    );
  }
}
