import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({
    required this.movie,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final Movie movie;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final posterUrl = movie.posterUrl;
    if (posterUrl != null && posterUrl.isNotEmpty) {
      return Image.network(
        posterUrl,
        fit: fit,
        alignment: alignment,
        semanticLabel: '${movie.title} 포스터',
        errorBuilder: (context, error, stackTrace) =>
            const _PosterPlaceholder(),
      );
    }
    final posterAsset = movie.posterAsset;
    if (posterAsset != null && posterAsset.isNotEmpty) {
      return Image.asset(
        posterAsset,
        fit: fit,
        alignment: alignment,
        semanticLabel: '${movie.title} 포스터',
        errorBuilder: (context, error, stackTrace) =>
            const _PosterPlaceholder(),
      );
    }
    return const _PosterPlaceholder();
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: ValueKey('poster-placeholder'),
      color: AppColors.softViolet,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 44,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
