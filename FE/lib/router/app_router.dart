import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/fake_movie_service.dart';
import '../data/services/legacy_movie_catalog_adapter.dart';
import '../data/services/member_api_service.dart';
import '../data/services/movie_catalog_service.dart';
import '../data/services/movie_list_preferences.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../screens/week05_api_screen.dart';

abstract final class AppRouter {
  static GoRouter createRouter({
    String initialLocation = '/start',
    MovieService? movieService,
    MovieCatalogService? catalogService,
    MovieListPreferences movieListPreferences =
        const SharedPreferencesMovieListPreferences(),
  }) {
    final resolvedCatalogService =
        catalogService ??
        LegacyMovieCatalogAdapter(
          movieService ?? const FakeMovieService(delay: Duration.zero),
        );
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => const StartScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) =>
                      HomeScreen(movieService: resolvedCatalogService),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movies',
                  builder: (context, state) {
                    final genreIds = state.uri.queryParametersAll['genreId']
                        ?.map(int.tryParse)
                        .whereType<int>()
                        .toList(growable: false);
                    return MovieListScreen(
                      selectedGenreIds: genreIds,
                      catalogService: resolvedCatalogService,
                      preferences: movieListPreferences,
                    );
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/movies/:movieId',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['movieId'] ?? '');
            if (state.extra is Movie) {
              return MovieDetailScreen(movie: state.extra! as Movie);
            }
            if (id == null) {
              return const _MovieNotFoundScreen();
            }
            return _MovieDetailLoader(
              movieId: id,
              catalogService: resolvedCatalogService,
            );
          },
        ),
        GoRoute(
          path: '/week05-api',
          builder: (context, state) =>
              Week05ApiScreen(apiService: MemberApiService.fromEnvironment()),
        ),
      ],
    );
  }

  static final GoRouter router = createRouter(
    catalogService: TmdbMovieService.fromEnvironment(),
  );
}

class _MovieDetailLoader extends StatefulWidget {
  const _MovieDetailLoader({
    required this.movieId,
    required this.catalogService,
  });

  final int movieId;
  final MovieCatalogService catalogService;

  @override
  State<_MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<_MovieDetailLoader> {
  late final Future<Movie?> _movie = _loadMovie();

  Future<Movie?> _loadMovie() async {
    final genres = await widget.catalogService.fetchGenres();
    final genreNames = {for (final genre in genres) genre.id: genre.name};
    if (widget.catalogService case final TmdbMovieService service) {
      return (await service.fetchMovieById(widget.movieId)).toMovie(genreNames);
    }
    final movies = await widget.catalogService.fetchDiscover();
    for (final movie in movies) {
      if (movie.id == widget.movieId) return movie.toMovie(genreNames);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Movie?>(
      future: _movie,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final movie = snapshot.data;
        if (snapshot.hasError || movie == null) {
          return const _MovieNotFoundScreen();
        }
        return MovieDetailScreen(movie: movie);
      },
    );
  }
}

class _MovieNotFoundScreen extends StatelessWidget {
  const _MovieNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/movies')),
        title: const Text('영화 상세'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('영화 정보를 찾을 수 없습니다.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/movies'),
              child: const Text('영화 목록으로'),
            ),
          ],
        ),
      ),
    );
  }
}
