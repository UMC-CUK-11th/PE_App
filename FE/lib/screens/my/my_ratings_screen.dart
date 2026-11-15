import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/rating_with_movie.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/my_ratings_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movielog_button.dart';
import '../../widgets/tmdb_poster_image.dart';

/// 마이페이지 위에 열리는 자식 화면입니다. root Navigator에 올라가 하단 탭이 보이지 않습니다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/my'),
      ),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MyRatingsLoadStatus.idle ||
            MyRatingsLoadStatus.loading => const Center(
              child: CircularProgressIndicator(color: AppColors.violet),
            ),
            MyRatingsLoadStatus.empty => const _Message(
              icon: Icons.rate_review_outlined,
              text: '아직 등록한 평점이 없어요.',
            ),
            MyRatingsLoadStatus.error => _Message(
              icon: Icons.error_outline,
              text: viewModel.message ?? '평점을 불러오지 못했습니다.',
              // 고정 너비 예시: 화면 크기와 관계없이 120을 유지합니다.
              action: MovieLogButton(
                label: '다시 시도',
                width: 120,
                onPressed: viewModel.load,
              ),
            ),
            MyRatingsLoadStatus.success => _RatingList(viewModel: viewModel),
          };
        },
      ),
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final message = viewModel.message;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '학습용 회원(memberId ${viewModel.memberId})의 공개 평점 ${viewModel.ratings.length}개',
          style: AppTextStyles.bodySmall,
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 12),
        for (final entry in viewModel.ratings) _RatingCard(entry: entry),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final date = rating.createdAt.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TmdbPosterImage(
            posterPath: movie?.posterPath,
            width: 64,
            height: 96,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie?.title ?? '영화 정보를 찾을 수 없어요',
                  style: AppTextStyles.labelLarge,
                ),
                Text(
                  'movieId ${rating.movieId}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= rating.score ? Icons.star : Icons.star_border,
                        size: 18,
                        color: AppColors.violet,
                      ),
                    const SizedBox(width: 6),
                    Text('${rating.score}점', style: AppTextStyles.bodySmall),
                  ],
                ),
                // comment가 null이면 표시하지 않습니다.
                if (rating.comment case final comment?) ...[
                  const SizedBox(height: 6),
                  Text(comment, style: AppTextStyles.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(
                  '${date.year}.${_two(date.month)}.${_two(date.day)} 등록',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.gray),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            if (action case final action?) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
