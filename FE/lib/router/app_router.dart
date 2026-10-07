import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/genre_filter.dart';
import '../data/genre_preference.dart';
import '../data/movie_service.dart';
import '../screens/home/home_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/movies/movie_detail_screen.dart';
import '../screens/movies/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up/sign_up_screen.dart';
import '../screens/start/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = createRouter();

  static GoRouter createRouter({
    String initialLocation = '/start',
    FakeMovieService movieService = const FakeMovieService(),
    GenrePreference? genrePreference,
  }) {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final preference = genrePreference ?? SharedPrefsGenrePreference();

    return GoRouter(
      navigatorKey: rootNavigatorKey,
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
                  builder: (context, state) => MovieListScreen(
                    selectedGenres: parseGenres(
                      state.uri.queryParameters[genresQueryKey],
                    ),
                    movieService: movieService,
                    genrePreference: preference,
                  ),
                  routes: [
                    GoRoute(
                      path: ':movieId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => MovieDetailScreen(
                        movieId: state.pathParameters['movieId']!,
                      ),
                    ),
                  ],
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
      ],
    );
  }
}
