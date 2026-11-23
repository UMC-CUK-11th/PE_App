import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../data/services/tmdb_movie_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/favorite_detail_view_model.dart';
import '../../view_models/movie_detail_view_model.dart';
import '../../view_models/sign_up_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/favorite_button.dart';
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
  int? _myRating;
  Future<TmdbMovieDto>? _movieFuture;

  @override
  void initState() {
    super.initState();
    final movieId = widget.movieId;
    if (widget.movie == null && movieId != null) {
      _movieFuture = context.read<TmdbMovieService>().fetchMovieDetail(movieId)
        ..ignore();
    }
    // build에서 조회하지 않고, 화면이 처음 만들어질 때 서버 즐겨찾기 여부를 한 번 확인합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoriteDetailViewModel?>()?.load();
    });
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

  /// Dialog가 저장까지 마치고 true를 돌려준 뒤에만 성공 Snackbar를 띄웁니다.
  /// movieId는 이 화면의 MovieDetailViewModel이 이미 갖고 있습니다.
  Future<void> _openRatingDialog() async {
    final viewModel = context.read<MovieDetailViewModel>();
    final favorite = context.read<FavoriteDetailViewModel?>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (_) => RatingDialog(
        initialScore: _myRating ?? 0,
        // 여부를 확인했고 아직 즐겨찾기하지 않은 영화일 때만 통합 저장을 제안합니다.
        showAddToFavorite:
            favorite != null &&
            favorite.hasLoadedStatus &&
            !favorite.isFavorite,
        onSubmit: (score, comment, addToFavorites) async {
          await viewModel.createRating(
            score: score,
            comment: comment,
            addToFavorites: addToFavorites,
          );
          if (viewModel.submitStatus == SubmitStatus.success) return;
          final message = viewModel.submitMessage ?? '저장에 실패했습니다.';
          if (viewModel.closeDialog) throw CloseRatingDialog(message);
          throw StateError(message);
        },
      ),
    );

    // 저장 요청과 Snackbar 표시는 다른 비동기 경계라 mounted를 다시 확인합니다.
    if (!mounted || saved != true) return;
    // 등록 result의 Rating 객체로 화면을 갱신하고, 북마크는 서버 값으로 다시 맞춥니다.
    setState(() => _myRating = viewModel.savedRating?.score);
    favorite?.load();
    _showMessage('평점을 저장했습니다.');
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
      bottomNavigationBar: DetailActionBar(onRate: _openRatingDialog),
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
  final int? myRating;

  @override
  Widget build(BuildContext context) {
    final myRating = this.myRating;
    final year = movie.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목·연도 오른쪽에 서버 즐겨찾기 상태를 보여주는 북마크를 둡니다.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: AppTextStyles.titleLarge),
                  if (year != null) ...[
                    const SizedBox(height: 4),
                    Text(year, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            if (context.read<FavoriteDetailViewModel?>() != null)
              const FavoriteButton(),
          ],
        ),
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
            '내 평점 $myRating점',
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

/// 3주차 mock 즐겨찾기 버튼은 제목 옆 FavoriteButton으로 옮기고, 평점 버튼만 전체 너비로 둡니다.
class DetailActionBar extends StatelessWidget {
  const DetailActionBar({super.key, required this.onRate});

  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRate,
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('평점 남기기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violet,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
