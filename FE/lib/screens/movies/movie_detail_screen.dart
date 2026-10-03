import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../../data/movie.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movie_cards.dart';
import '../../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _myRating;

  Movie? get _movie => findMovieById(int.tryParse(widget.movieId));

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showMessage(_isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.');
  }

  Future<void> _openRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (dialogContext) => RatingDialog(initialRating: _myRating ?? 0),
    );

    if (rating == null || !mounted) return;
    setState(() => _myRating = rating);
    _showMessage('평점 ${rating.toStringAsFixed(1)}점을 남겼어요.');
  }

  @override
  Widget build(BuildContext context) {
    final movie = _movie;
    final appBar = CommonAppBar(
      title: 'Cinema Archive',
      centerTitle: true,
      onBack: _goBack,
      actions: [
        IconButton(
          tooltip: '공유',
          onPressed: () {},
          icon: const Icon(Icons.share_outlined),
        ),
      ],
    );

    if (movie == null) {
      return Scaffold(
        appBar: appBar,
        body: const Center(
          child: Text('영화를 찾을 수 없어요.', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: MoviePoster(movie: movie, borderRadius: 0),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: MovieInfoSection(movie: movie, myRating: _myRating),
          ),
        ],
      ),
      bottomNavigationBar: DetailActionBar(
        isFavorite: _isFavorite,
        onFavorite: _toggleFavorite,
        onRate: _openRatingDialog,
      ),
    );
  }
}

class MovieInfoSection extends StatelessWidget {
  const MovieInfoSection({
    super.key,
    required this.movie,
    required this.myRating,
  });

  final Movie movie;
  final double? myRating;

  String _formatCount(int count) {
    return count.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  @override
  Widget build(BuildContext context) {
    final myRating = this.myRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movie.title, style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${movie.year} · ${movie.tags.take(2).join('/')} · ${movie.runtimeMinutes}분',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            RatingBarIndicator(
              rating: movie.rating,
              itemCount: 5,
              itemSize: 18,
              unratedColor: AppColors.violetDisabled,
              itemBuilder: (context, index) {
                return const Icon(Icons.star, color: AppColors.violet);
              },
            ),
            const SizedBox(width: 8),
            Text(
              '${movie.rating} (${_formatCount(movie.ratingCount)})',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        if (myRating != null) ...[
          const SizedBox(height: 4),
          Text(
            '내 평점 ${myRating.toStringAsFixed(1)}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.violet),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: movie.tags
              .map(
                (tag) => Chip(
                  label: Text(tag, style: AppTextStyles.bodySmall),
                  backgroundColor: AppColors.surfaceLow,
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        const Text('시놉시스', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        Text(movie.synopsis, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class DetailActionBar extends StatelessWidget {
  const DetailActionBar({
    super.key,
    required this.isFavorite,
    required this.onFavorite,
    required this.onRate,
  });

  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onFavorite,
                  icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
                  label: const Text('즐겨찾기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.violet,
                    side: const BorderSide(color: AppColors.violet),
                    shape: shape,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('평점 남기기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: shape,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
