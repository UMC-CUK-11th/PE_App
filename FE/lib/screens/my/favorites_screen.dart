import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/favorites_view_model.dart';
import '../../view_models/load_phase.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movie_cards.dart';
import '../../widgets/movielog_button.dart';

/// 내 즐겨찾기(/my/favorites). root Navigator에 올라가 하단 탭이 보이지 않습니다.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  /// 상세에서 해제하고 돌아오면 목록을 다시 조회해 해제한 영화를 뺍니다.
  Future<void> _open(TmdbMovieDto movie) async {
    final viewModel = context.read<FavoritesViewModel>();
    await context.push('/movies/${movie.id}', extra: movie);
    if (!mounted) return;
    await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 즐겨찾기',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/my'),
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, vm, _) => switch (vm.phase) {
          LoadPhase.idle || LoadPhase.loading => const Center(
            child: CircularProgressIndicator(color: AppColors.violet),
          ),
          LoadPhase.empty => const Center(
            child: Text('아직 즐겨찾기한 영화가 없습니다.', style: AppTextStyles.bodyMedium),
          ),
          LoadPhase.error => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vm.errorMessage ?? '내 즐겨찾기 목록을 불러오지 못했습니다.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                MovieLogButton(
                  label: '다시 시도',
                  width: 120,
                  onPressed: vm.refresh,
                ),
              ],
            ),
          ),
          LoadPhase.ready => RefreshIndicator(
            color: AppColors.violet,
            onRefresh: vm.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: vm.items.length,
              itemBuilder: (context, index) {
                final item = vm.items[index];
                final movie = item.movie;
                if (movie == null) {
                  // 영화 정보 한 건만 실패한 카드: placeholder와 그 카드만 재조회.
                  return ListTile(
                    leading: const Icon(Icons.broken_image_outlined),
                    title: Text('영화 #${item.favorite.movieId}'),
                    subtitle: Text(item.errorMessage ?? '영화 정보가 없습니다.'),
                    trailing: MovieLogButton(
                      label: '정보 재조회',
                      width: 110,
                      onPressed: () => vm.retryMovie(item.favorite.movieId),
                    ),
                  );
                }
                return MovieListTile(movie: movie, onTap: () => _open(movie));
              },
            ),
          ),
        },
      ),
    );
  }
}
