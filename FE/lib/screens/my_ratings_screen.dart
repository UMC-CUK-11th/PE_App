import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/my'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                '학습용 회원 1번의 공개 평점입니다.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: switch (vm.status) {
                MyRatingsStatus.idle => const Center(
                  child: CircularProgressIndicator(),
                ),
                MyRatingsStatus.loading when vm.ratings.isEmpty => const Center(
                  child: CircularProgressIndicator(),
                ),
                MyRatingsStatus.empty => _Message(
                  icon: Icons.rate_review_outlined,
                  message: '등록한 평점이 없습니다.',
                  onRetry: vm.load,
                ),
                MyRatingsStatus.error => _Message(
                  icon: Icons.wifi_off_rounded,
                  message: vm.errorMessage!,
                  onRetry: vm.load,
                ),
                MyRatingsStatus.loading ||
                MyRatingsStatus.success => RefreshIndicator(
                  onRefresh: vm.load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: vm.ratings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rating = vm.ratings[index];
                      final movie = vm.moviesById[rating.movieId];
                      final date = rating.createdAt.toLocal();
                      final dateText =
                          '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: AppColors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 78,
                                      height: 117,
                                      child: movie == null
                                          ? const ColoredBox(
                                              color: AppColors.softViolet,
                                              child: Icon(Icons.movie_outlined),
                                            )
                                          : TmdbPoster(
                                              movie: movie.toMovie(const []),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          movie?.title ??
                                              '영화 #${rating.movieId}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '★ ${rating.score} / 5',
                                          style: const TextStyle(
                                            color: AppColors.violet,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          rating.comment?.trim().isNotEmpty ==
                                                  true
                                              ? rating.comment!
                                              : '작성한 후기가 없습니다.',
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          dateText,
                                          style: const TextStyle(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (movie == null)
                                          const Text(
                                            '영화 정보를 불러오지 못했습니다.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.error,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.message,
    required this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.violet),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          MovieLogButton(label: '다시 불러오기', width: 160, onPressed: onRetry),
        ],
      ),
    ),
  );
}
