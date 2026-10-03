import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/movie.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movie_cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = movies.first;
    final popular = movies.skip(1).toList();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: CommonAppBar(
          title: 'MovieLog',
          actions: [
            IconButton(
              tooltip: '검색',
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text('오늘은 어떤\n영화를 볼까요?', style: AppTextStyles.headline),
            const SizedBox(height: 16),
            FeaturedMovieCard(
              movie: featured,
              onDetail: () => context.push('/movies/${featured.id}'),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: '인기 영화',
              actionLabel: '전체보기',
              onAction: () => context.go('/movies'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popular.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final movie = popular[index];
                  return MovieCard(
                    movie: movie,
                    onTap: () => context.push('/movies/${movie.id}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedMovieCard extends StatelessWidget {
  const FeaturedMovieCard({
    super.key,
    required this.movie,
    required this.onDetail,
  });

  final Movie movie;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDetail,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MoviePoster(movie: movie, borderRadius: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.violet,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '추천 신작',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.title,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '${movie.tags.take(2).join(' · ')} · ${movie.runtimeMinutes}분',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onDetail,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('상세보기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: AppColors.violet),
          child: Text('$actionLabel >'),
        ),
      ],
    );
  }
}
