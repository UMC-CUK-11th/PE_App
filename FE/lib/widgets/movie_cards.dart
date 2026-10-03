import 'package:flutter/material.dart';

import '../data/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.movie,
    this.borderRadius = 12,
  });

  final Movie movie;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        movie.posterAsset,
        fit: BoxFit.cover,
        semanticLabel: '${movie.title} 포스터',
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surfaceLow,
          alignment: Alignment.center,
          child: const Icon(Icons.movie_outlined, color: AppColors.gray),
        ),
      ),
    );
  }
}

class RatingLabel extends StatelessWidget {
  const RatingLabel({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 14, color: AppColors.violet),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1), style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.width = 120,
  });

  final Movie movie;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: 2 / 3, child: MoviePoster(movie: movie)),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
            ),
            RatingLabel(rating: movie.rating),
          ],
        ),
      ),
    );
  }
}

class MovieGridCard extends StatelessWidget {
  const MovieGridCard({
    super.key,
    required this.movie,
    required this.onTap,
  });

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MoviePoster(movie: movie),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RatingLabel(rating: movie.rating),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLarge,
          ),
          Text(
            '${movie.year} · ${movie.genre}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
