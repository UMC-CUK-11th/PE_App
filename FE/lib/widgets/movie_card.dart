import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    required this.movie,
    required this.onTap,
    this.rank,
    this.compact = false,
    super.key,
  });

  final Movie movie;
  final VoidCallback onTap;
  final int? rank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('movie-card-${movie.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: compact ? 0.7 : 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(compact ? 16 : 12),
                  child: Image.asset(
                    movie.posterAsset,
                    fit: BoxFit.cover,
                    semanticLabel: '${movie.title} 포스터',
                  ),
                ),
                if (rank != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _OverlayBadge(label: '$rank'),
                  ),
                if (!compact)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _OverlayBadge(label: '★ ${movie.rating}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (compact)
            Row(
              children: [
                const Icon(Icons.star, size: 13, color: Color(0xFFD0A53B)),
                const SizedBox(width: 4),
                Text(
                  '${movie.rating}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
              ],
            )
          else
            Text(
              movie.metadata,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
