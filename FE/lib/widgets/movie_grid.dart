import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({required this.movies, super.key});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const PageStorageKey('movie-grid'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}
