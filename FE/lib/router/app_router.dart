import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/genre_preference.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home/home_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/movies/movie_detail_screen.dart';
import '../screens/movies/movie_list_screen.dart';
import '../screens/my/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up/sign_up_screen.dart';
import '../screens/start/start_screen.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
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
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
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
                      builder: (context, state) {
                        final id = int.tryParse(
                          state.pathParameters['movieId']!,
                        );
                        final extra = state.extra;
                        final screen = MovieDetailScreen(
                          movieId: id,
                          // extra는 딥링크에서 없을 수 있고, 다른 영화일 수도 있습니다.
                          movie: extra is TmdbMovieDto && extra.id == id
                              ? extra
                              : null,
                        );
                        if (id == null || id < 1) return screen;
                        return ChangeNotifierProvider<MovieDetailViewModel>(
                          create: (context) => MovieDetailViewModel(
                            context.read<RatingApiService>(),
                            context.read<LearningMemberSession>().memberId,
                            id,
                          ),
                          child: screen,
                        );
                      },
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
                  routes: [
                    GoRoute(
                      path: 'ratings', // 최종 경로: /my/ratings
                      // root Navigator 위에 올려 하단 NavigationBar를 가립니다.
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        // 7주차부터는 고정 ID 1이 아니라 가입 결과의 memberId로 조회합니다.
                        final id = context
                            .read<LearningMemberSession>()
                            .memberId;
                        if (id == null) return const MemberRequiredScreen();
                        return ChangeNotifierProvider<MyRatingsViewModel>(
                          create: (context) => MyRatingsViewModel(
                            context.read<RatingApiService>(),
                            context.read<TmdbMovieService>(),
                            id,
                          )..load(),
                          child: const MyRatingsScreen(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
