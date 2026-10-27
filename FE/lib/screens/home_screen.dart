import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredMovie = mockMovies.first;
    final popularMovies = mockMovies.skip(1).take(4).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: const Text(
          'MovieLog',
          style: TextStyle(
            color: AppColors.onPrimaryContainer,
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.55,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox.square(
              dimension: 34,
              child: IconButton(
                tooltip: '영화 검색',
                onPressed: () => context.go('/movies'),
                padding: const EdgeInsets.all(7),
                icon: SvgPicture.asset(
                  'assets/icons/search.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.onPrimaryContainer,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
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
                    letterSpacing: -0.7,
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
                        height: 28 / 22,
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
                        rank: index + 1,
                        compact: true,
                        onTap: () => context.push('/movies/${movie.id}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
            Image.asset(
              movie.posterAsset,
              fit: BoxFit.cover,
              semanticLabel: '${movie.title} 추천 영화 포스터',
            ),
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xE64F378A),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      child: Text(
                        '추천 신작',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      height: 36 / 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${movie.genreLabel} · ${movie.durationMinutes}분',
                    style: const TextStyle(
                      color: Color(0xFFF8F2FA),
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/movies/${movie.id}'),
                      icon: const Icon(Icons.info, size: 18),
                      label: const Text('상세보기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.onPrimaryContainer,
                        foregroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                      ),
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
