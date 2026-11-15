import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/tmdb_poster_image.dart';

/// GET /members/{memberId}/ratings 결과를 TMDB 영화 정보와 함께 보여 줍니다.
class MyRatingsSection extends StatelessWidget {
  const MyRatingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('내 평점', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            switch (viewModel.status) {
              MyRatingsStatus.loading => const Center(
                child: CircularProgressIndicator(color: AppColors.violet),
              ),
              MyRatingsStatus.empty => const Text(
                '아직 남긴 평점이 없어요.',
                style: AppTextStyles.bodyMedium,
              ),
              MyRatingsStatus.error => Row(
                children: [
                  const Expanded(
                    child: Text(
                      '평점을 불러오지 못했어요.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: viewModel.load,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
              MyRatingsStatus.success => Column(
                children: [
                  for (final item in viewModel.ratings) _RatingTile(item: item),
                ],
              ),
            },
          ],
        );
      },
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({required this.item});

  final MyRating item;

  @override
  Widget build(BuildContext context) {
    final rating = item.rating;
    final movie = item.movie;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TmdbPosterImage(
            posterPath: movie?.posterPath,
            width: 56,
            height: 84,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie?.title ?? '영화 #${rating.movieId}',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= rating.score ? Icons.star : Icons.star_border,
                        size: 16,
                        color: AppColors.violet,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'movieId ${rating.movieId}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                if (rating.comment case final comment?) ...[
                  const SizedBox(height: 4),
                  Text(comment, style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
