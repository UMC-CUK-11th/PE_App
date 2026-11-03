import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';

class TmdbPoster extends StatelessWidget {
  const TmdbPoster({required this.movie, super.key});
  final Movie movie;

  Widget _placeholder() => const ColoredBox(
    key: ValueKey('poster-placeholder'),
    color: AppColors.softViolet,
    child: Center(
      child: Icon(
        Icons.movie_outlined,
        size: 40,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final url = movie.posterUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        semanticLabel: '${movie.title} 포스터',
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (context, error, stack) => _placeholder(),
      );
    }
    if (movie.posterAsset.isNotEmpty) {
      return Image.asset(
        movie.posterAsset,
        fit: BoxFit.cover,
        semanticLabel: '${movie.title} 포스터',
        errorBuilder: (context, error, stack) => _placeholder(),
      );
    }
    return _placeholder();
  }
}
