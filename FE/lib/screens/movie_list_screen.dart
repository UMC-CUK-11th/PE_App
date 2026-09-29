import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({required this.selectedGenres, super.key});

  final Set<String> selectedGenres;

  static const _filterGenres = ['전체', ...movieGenres];

  List<Movie> get _filteredMovies {
    if (selectedGenres.isEmpty) return mockMovies;
    return mockMovies
        .where((movie) => movie.genres.any(selectedGenres.contains))
        .toList();
  }

  void _selectGenre(BuildContext context, String genre) {
    final uri = Uri(
      path: '/movies',
      queryParameters: genre == '전체' ? null : {'genre': genre},
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final movies = _filteredMovies;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: const Text(
          '영화',
          style: TextStyle(
            color: AppColors.onPrimaryContainer,
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox.square(
              dimension: 34,
              child: IconButton(
                tooltip: '영화 검색',
                onPressed: () {},
                padding: const EdgeInsets.all(7),
                icon: SvgPicture.asset(
                  'assets/icons/search.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              key: const ValueKey('genre-filter-bar'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filterGenres.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = _filterGenres[index];
                final selected = genre == '전체'
                    ? selectedGenres.isEmpty
                    : selectedGenres.contains(genre);
                return _GenreFilterChip(
                  label: genre,
                  selected: selected,
                  onTap: () => _selectGenre(context, genre),
                );
              },
            ),
          ),
          Expanded(
            child: movies.isEmpty
                ? const Center(child: Text('선택한 장르의 영화가 없습니다.'))
                : GridView.builder(
                    key: const PageStorageKey('movie-grid'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: movies.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.54,
                        ),
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return MovieCard(
                        movie: movie,
                        onTap: () => context.push('/movies/${movie.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GenreFilterChip extends StatelessWidget {
  const _GenreFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('genre-chip-$label'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.violet : const Color(0xFFF3EDF7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.onSurfaceVariant,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
