import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../data/services/tmdb_movie_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/rating_dialog.dart';
import '../../widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  /// TMDB 영화 ID. 평점 Dialog 결과를 저장할 때 movieId로 사용합니다.
  final int? movieId;

  /// 목록에서 넘겨받은 DTO. 없으면(딥링크 등) movieId로 상세를 조회합니다.
  final TmdbMovieDto? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _myRating;
  Future<TmdbMovieDto>? _movieFuture;

  @override
  void initState() {
    super.initState();
    final movieId = widget.movieId;
    if (widget.movie == null && movieId != null) {
      _movieFuture = context.read<TmdbMovieService>().fetchMovie(movieId)
        ..ignore();
    }
  }

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
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showMessage(_isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.');
  }

  Future<void> _openRatingDialog(int movieId) async {
    final rating = await showDialog<double>(
      context: context,
      builder: (dialogContext) => RatingDialog(initialRating: _myRating ?? 0),
    );

    if (rating == null || !mounted) return;
    // TODO(평점 API): CreateRatingRequest(movieId: movieId, score: rating)로 저장합니다.
    debugPrint('평점 저장 대상 movieId=$movieId score=$rating');
    setState(() => _myRating = rating);
    _showMessage('평점 ${rating.toStringAsFixed(1)}점을 남겼어요.');
  }

  @override
  Widget build(BuildContext context) {
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

    final movie = widget.movie;
    if (movie != null) return _buildMovie(appBar, movie);

    final future = _movieFuture;
    if (future == null) return _buildMessage(appBar, '영화를 찾을 수 없어요.');

    return FutureBuilder<TmdbMovieDto>(
      future: future,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        if (loaded != null) return _buildMovie(appBar, loaded);
        if (snapshot.hasError) return _buildMessage(appBar, '영화를 찾을 수 없어요.');
        return Scaffold(
          appBar: appBar,
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.violet),
          ),
        );
      },
    );
  }

  Widget _buildMessage(PreferredSizeWidget appBar, String message) {
    return Scaffold(
      appBar: appBar,
      body: Center(child: Text(message, style: AppTextStyles.bodyMedium)),
    );
  }

  Widget _buildMovie(PreferredSizeWidget appBar, TmdbMovieDto movie) {
    return Scaffold(
      appBar: appBar,
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: TmdbPosterImage(
              posterPath: movie.posterPath,
              borderRadius: 0,
              semanticLabel: '${movie.title} 포스터',
            ),
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
        onRate: () => _openRatingDialog(movie.id),
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

  final TmdbMovieDto movie;
  final double? myRating;

  @override
  Widget build(BuildContext context) {
    final myRating = this.myRating;
    final year = movie.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movie.title, style: AppTextStyles.titleLarge),
        if (year != null) ...[
          const SizedBox(height: 4),
          Text(year, style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            // TMDB 평점은 10점 만점이라 별 5개에 맞춰 절반으로 표시합니다.
            RatingBarIndicator(
              rating: movie.voteAverage / 2,
              itemCount: 5,
              itemSize: 18,
              unratedColor: AppColors.violetDisabled,
              itemBuilder: (context, index) {
                return const Icon(Icons.star, color: AppColors.violet);
              },
            ),
            const SizedBox(width: 8),
            Text(
              '${movie.voteAverage.toStringAsFixed(1)} / 10',
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
        const SizedBox(height: 24),
        const Text('시놉시스', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        if (movie.overview.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('줄거리 정보가 없어요.', style: AppTextStyles.bodyMedium),
            ),
          )
        else
          Text(movie.overview, style: AppTextStyles.bodyMedium),
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
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  ),
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
