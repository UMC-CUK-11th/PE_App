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
import '../screens/login/login_screen.dart';
import '../screens/my/edit_profile_screen.dart';
import '../screens/my/favorites_screen.dart';
import '../screens/movies/movie_search_screen.dart';
import '../screens/start/splash_screen.dart';
import '../data/services/member_api_service.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../data/services/favorite_api_service.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';

/// 인증 상태별 이동 규칙을 한 곳에 둡니다. 상태만 읽고 비동기 작업은 하지 않습니다.
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);
  return switch (status) {
    // 토큰 확인 중·확인 실패(재시도): 스플래시 유지. 보호 화면이 잠깐 보이지 않게 합니다.
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    // 로그아웃·로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    // 로그인됨: 스플래시·로그인·회원가입은 홈으로
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

/// 내 정보(email)가 준비된 현재 세션의 key. 닉네임 수정으로는 바뀌지 않고,
/// 같은 이메일로 다시 로그인해도 sessionVersion이 바뀌어 새 ViewModel이 됩니다.
String? _sessionKey(BuildContext context) {
  final email = context.select<AuthViewModel, String?>((a) => a.member?.email);
  final version = context.select<AuthViewModel, int>((a) => a.sessionVersion);
  return email == null ? null : '$email:$version';
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class AppRouter {
  AppRouter._();

  /// 앱이 살아있는 동안 한 번만 만듭니다. build에서 만들면 위치가 초기화됩니다.
  static GoRouter createRouter({
    required AuthViewModel auth,
    String initialLocation = '/start',
    GenrePreference? genrePreference,
  }) {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final preference = genrePreference ?? SharedPrefsGenrePreference();

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      refreshListenable: auth, // 인증 상태가 바뀌면 redirect를 다시 실행합니다.
      redirect: (context, state) => authRedirect(auth.status, state.uri.path),
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) {
            final auth = context.watch<AuthViewModel>();
            return SplashScreen(
              message: auth.message,
              onRetry: auth.status == AuthStatus.retryRequired
                  ? auth.restoreSession
                  : null,
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
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
                        )..start(),
                        child: const MovieListScreen(),
                      ),
                  routes: [
                    // 정적인 search를 동적인 :movieId보다 먼저 둬야 search가 영화 ID로 해석되지 않습니다.
                    GoRoute(
                      path: 'search',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          ChangeNotifierProvider<PagedMoviesViewModel>(
                            create: (context) => PagedMoviesViewModel(
                              tmdbApi: context.read<TmdbMovieService>(),
                            ),
                            child: const MovieSearchScreen(),
                          ),
                    ),
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
                        final session = _sessionKey(context);
                        if (session == null) return const _Loading();
                        return MultiProvider(
                          // 계정·세션이 바뀌면 이전 사용자의 ViewModel을 버리고 새로 만듭니다.
                          key: ValueKey(session),
                          providers: [
                            ChangeNotifierProvider<MovieDetailViewModel>(
                              create: (context) => MovieDetailViewModel(
                                context.read<RatingApiService>(),
                                context.read<AuthViewModel>(),
                                id,
                              ),
                            ),
                            ChangeNotifierProvider<FavoriteDetailViewModel>(
                              create: (context) => FavoriteDetailViewModel(
                                movieId: id,
                                favoriteApi: context.read<FavoriteApiService>(),
                                auth: context.read<AuthViewModel>(),
                              ),
                            ),
                          ],
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
                      builder: (context, state) =>
                          ChangeNotifierProvider<MyRatingsViewModel>(
                            create: (context) => MyRatingsViewModel(
                              context.read<RatingApiService>(),
                              context.read<TmdbMovieService>(),
                              context.read<AuthViewModel>(),
                            )..load(),
                            child: const MyRatingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'favorites', // 최종 경로: /my/favorites
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final session = _sessionKey(context);
                        if (session == null) return const _Loading();
                        return ChangeNotifierProvider<FavoritesViewModel>(
                          key: ValueKey(session),
                          create: (context) => FavoritesViewModel(
                            favoriteApi: context.read<FavoriteApiService>(),
                            tmdbApi: context.read<TmdbMovieService>(),
                            auth: context.read<AuthViewModel>(),
                          ),
                          child: const FavoritesScreen(),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'profile/edit', // 최종 경로: /my/profile/edit
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final auth = context.watch<AuthViewModel>();
                        if (auth.member == null) {
                          return Scaffold(
                            appBar: AppBar(
                              centerTitle: true,
                              title: const Text('프로필 수정'),
                            ),
                            body: Center(
                              child: auth.memberStatus == MemberLoadStatus.error
                                  ? MovieLogButton(
                                      label: '다시 시도',
                                      onPressed: () =>
                                          auth.loadMember(force: true),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        return ChangeNotifierProvider<EditProfileViewModel>(
                          create: (context) => EditProfileViewModel(
                            context.read<MemberApiService>(),
                            auth,
                          ),
                          child: const EditProfileScreen(),
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
