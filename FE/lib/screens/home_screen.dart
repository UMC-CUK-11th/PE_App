import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../services/movie_catalog_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/movie_poster.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.movieService, super.key});

  final MovieCatalogService movieService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(widget.movieService)..loadPopular();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: const Text(
          'MovieLog',
          style: TextStyle(
            color: AppColors.onPrimaryContainer,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: '영화 검색',
              onPressed: () => context.go('/movies'),
              icon: SvgPicture.asset(
                'assets/icons/search.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.violet,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
      body: switch (viewModel.state) {
        ViewLoadState.loading => const MovieListLoading(),
        ViewLoadState.empty => const MovieListEmpty(),
        ViewLoadState.error => MovieListError(onRetry: viewModel.retry),
        ViewLoadState.success => _HomeSuccess(movies: viewModel.movies),
      },
    );
  }
}

class _HomeSuccess extends StatelessWidget {
  const _HomeSuccess({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    final featuredMovie = movies.first;
    final popularMovies = movies.skip(1).take(4).toList(growable: false);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '오늘은 어떤\n영화를 볼까요?',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 28,
                  height: 36 / 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _FeaturedMovieCard(movie: featuredMovie),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '인기 영화',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/movies'),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right, size: 16),
                    label: const Text('전체보기'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (popularMovies.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('추가 인기 영화가 없습니다.'),
              )
            else
              SizedBox(
                height: 272,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popularMovies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final movie = popularMovies[index];
                    return SizedBox(
                      width: 140,
                      child: MovieCard(
                        movie: movie,
                        rank: index + 2,
                        compact: true,
                        onTap: () =>
                            context.push('/movies/${movie.id}', extra: movie),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedMovieCard extends StatelessWidget {
  const _FeaturedMovieCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MoviePoster(movie: movie),
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x70000000)),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (movie.metadata.isNotEmpty)
                    Text(
                      movie.metadata,
                      style: const TextStyle(
                        color: Color(0xFFF8F2FA),
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/movies/${movie.id}', extra: movie),
                      icon: const Icon(Icons.info, size: 18),
                      label: const Text('상세보기'),
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
