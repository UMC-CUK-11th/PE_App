import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../services/fake_movie_service.dart';
import '../services/movie_list_preferences.dart';
import '../sign_up_screen.dart';
import '../start_screen.dart';

abstract final class AppRouter {
  static GoRouter createRouter({
    String initialLocation = '/start',
    MovieService movieService = const FakeMovieService(),
    MovieListPreferences movieListPreferences =
        const SharedPreferencesMovieListPreferences(),
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => const StartScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const SignUpScreen(),
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
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movies',
                  builder: (context, state) {
                    final genres = state.uri.queryParametersAll['genre'];
                    return MovieListScreen(
                      selectedGenres: genres?.toSet() ?? const <String>{},
                      movieService: movieService,
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
            final movie = findMovieById(id);
            if (movie == null) {
              return const _MovieNotFoundScreen();
            }
            return MovieDetailScreen(movie: movie);
          },
        ),
      ],
    );
  }

  static final GoRouter router = createRouter();
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
