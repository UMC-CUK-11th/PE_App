import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// poster_path URL 조합, null 처리, 로드 실패 처리를 한 곳에서 담당합니다.
class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.semanticLabel,
  });

  final String? posterPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String? semanticLabel;

  static const _baseUrl = 'https://image.tmdb.org/t/p';
  static const _size = 'w500';

  static String? urlOf(String? posterPath) {
    if (posterPath == null || posterPath.isEmpty) return null;
    return '$_baseUrl/$_size$posterPath';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = urlOf(posterPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl == null
          ? _placeholder()
          : Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: fit,
              semanticLabel: semanticLabel,
              errorBuilder: (_, _, _) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      key: const ValueKey('poster-placeholder'),
      width: width,
      height: height,
      color: AppColors.surfaceLow,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.gray,
      ),
    );
  }
}
