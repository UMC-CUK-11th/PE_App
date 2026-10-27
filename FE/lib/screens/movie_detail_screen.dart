import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({required this.movie, super.key});

  final Movie movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double _myRating = 0;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/movies');
    }
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        ),
      );
  }

  Future<void> _openRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(initialRating: _myRating),
    );
    if (rating == null || !mounted) return;

    setState(() => _myRating = rating);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('내 평점 ${rating.toStringAsFixed(1)}점을 저장했습니다.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Cinema Archive',
        centerTitle: true,
        onBack: _goBack,
        titleStyle: AppTextStyles.signUpAppBarTitle.copyWith(
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            tooltip: '공유',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('공유 링크를 준비했습니다.'),
                ),
              );
            },
            icon: SvgPicture.asset(
              'assets/icons/share.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                AppColors.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const ValueKey('favorite-button'),
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                  ),
                  label: Text(_isFavorite ? '즐겨찾기됨' : '즐겨찾기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.violet,
                    side: const BorderSide(color: AppColors.violet),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const ValueKey('open-rating-dialog-button'),
                  onPressed: _openRatingDialog,
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: Text(
                    _myRating == 0
                        ? '평점 남기기'
                        : '내 평점 ${_myRating.toStringAsFixed(1)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 585,
              child: Image.asset(
                movie.posterAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                semanticLabel: '${movie.title} 상세 포스터',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 28,
                      height: 36 / 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.year} · ${movie.genreLabel} · ${movie.durationMinutes}분',
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: movie.rating,
                        itemCount: 5,
                        itemSize: 18,
                        unratedColor: AppColors.outlineVariant,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: AppColors.violet),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${movie.rating} (1,245)',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.genres
                        .map((genre) => _DetailGenreChip(label: genre))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  const SizedBox(height: 24),
                  const Text(
                    '시놉시스',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.synopsis,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 22 / 14,
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

class _DetailGenreChip extends StatelessWidget {
  const _DetailGenreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.statBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
            height: 16 / 12,
          ),
        ),
      ),
    );
  }
}
