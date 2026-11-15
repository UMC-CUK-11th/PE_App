import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/genre_preference.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/movielog_member_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home/home_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/movies/movie_detail_screen.dart';
import '../screens/movies/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up/sign_up_screen.dart';
import '../screens/start/start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

class AppRouter {
  AppRouter._();

  static final router = createRouter();

  static GoRouter createRouter({
    String initialLocation = '/start',
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
          builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
            create: (context) =>
                SignUpViewModel(context.read<MovieLogMemberService>()),
            child: const SignUpScreen(),
          ),
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
                  // Branch는 한 번만 만들어지므로 Popular 요청도 한 번만 실행됩니다.
                  builder: (context, state) =>
                      ChangeNotifierProvider<MovieHomeViewModel>(
                        create: (context) =>
                            MovieHomeViewModel(context.read<TmdbMovieService>())
                              ..loadPopular(),
                        child: const HomeScreen(),
                      ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movies',
                  builder: (context, state) =>
                      ChangeNotifierProvider<MovieListViewModel>(
                        create: (context) => MovieListViewModel(
                          context.read<TmdbMovieService>(),
                          preference,
                        )..loadInitial(),
                        child: const MovieListScreen(),
                      ),
                  routes: [
                    GoRoute(
                      path: ':movieId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => MovieDetailScreen(
                        movieId: int.tryParse(state.pathParameters['movieId']!),
                        movie: state.extra as TmdbMovieDto?,
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
                  builder: (context, state) =>
                      ChangeNotifierProvider<MyRatingsViewModel>(
                        create: (context) => MyRatingsViewModel(
                          context.read<MovieLogMemberService>(),
                          context.read<TmdbMovieService>(),
                        )..load(),
                        child: const ProfileScreen(),
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
