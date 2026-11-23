import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import 'movie_poster.dart';

class MovieListTile extends StatelessWidget {
  const MovieListTile({
    required this.movie,
    required this.onTap,
    this.label,
    super.key,
  });

  final Movie movie;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 144,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          border: Border.all(color: AppColors.softViolet),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 78,
                height: 116,
                child: MoviePoster(movie: movie),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 22 / 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    movie.metadata.isEmpty
                        ? 'TMDB 영화 ID로 연결합니다.'
                        : movie.metadata,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                      height: 18 / 13,
                    ),
                  ),
                  if (label != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      label!,
                      style: const TextStyle(
                        color: AppColors.violet,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
