import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movie_poster.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({required this.viewModel, super.key});

  final MovieDetailViewModel viewModel;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _addToFavorites = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.loadFavorite());
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  void _goBack() => context.canPop() ? context.pop() : context.go('/movies');

  Future<void> _toggleFavorite() async {
    final succeeded = await widget.viewModel.toggleFavorite();
    if (!mounted) return;
    final message = succeeded
        ? (widget.viewModel.isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.')
        : widget.viewModel.favoriteMessage ?? '즐겨찾기를 변경하지 못했습니다.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openRatingDialog() async {
    if (widget.viewModel.memberId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    _addToFavorites = false;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        movieId: widget.viewModel.movie.id,
        showFavoriteOption: true,
        initialAddToFavorites: false,
        onFavoriteChanged: (value) => _addToFavorites = value,
        onSubmit: (score, comment) async {
          await widget.viewModel.createRating(
            score: score,
            comment: comment,
            addToFavorites: _addToFavorites,
          );
          if (widget.viewModel.submitStatus != SubmitStatus.success) {
            throw StateError(
              widget.viewModel.submitMessage ?? '평점 저장에 실패했습니다.',
            );
          }
        },
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('영화 기록을 저장했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.viewModel.movie;
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.warmWhite,
        appBar: AppBar(
          backgroundColor: AppColors.warmWhite,
          centerTitle: true,
          leading: IconButton(
            tooltip: '뒤로 가기',
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text(
            '영화 상세',
            style: TextStyle(
              color: AppColors.violet,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 220,
                    child: MoviePoster(movie: movie, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: const TextStyle(
                              fontSize: 25,
                              height: 32 / 25,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              movie.metadata,
                              if (movie.durationMinutes > 0)
                                '${movie.durationMinutes}분',
                            ].where((value) => value.isNotEmpty).join(' · '),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.violet,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FavoriteButton(
                      isFavorite: widget.viewModel.isFavorite,
                      isLoading:
                          widget.viewModel.isFavoriteLoading ||
                          widget.viewModel.isFavoriteSaving,
                      onPressed: widget.viewModel.memberId == null
                          ? null
                          : _toggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  '줄거리',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  movie.synopsis,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    key: const ValueKey('open-rating-dialog-button'),
                    onPressed: _openRatingDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('평점 남기기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isFavorite;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('favorite-button'),
      width: 66,
      height: 72,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.softViolet),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.violet,
                  ),
                  const SizedBox(height: 4),
                  const Text('즐겨찾기', style: TextStyle(fontSize: 11)),
                ],
              ),
      ),
    );
  }
}
