import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/fake_movie_service.dart';
import '../data/services/legacy_movie_catalog_adapter.dart';
import '../data/services/member_api_service.dart';
import '../data/services/learning_member_session.dart';
import '../data/services/movie_catalog_service.dart';
import '../data/services/movie_list_preferences.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/member_ratings_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../screens/week05_api_screen.dart';
import '../view_models/member_ratings_view_model.dart';
import '../view_models/movie_detail_view_model.dart';

abstract final class AppRouter {
  static GoRouter createRouter({
    String initialLocation = '/start',
    MovieService? movieService,
    MovieCatalogService? catalogService,
    MemberApiService? memberApiService,
    TmdbMovieService? tmdbMovieService,
    LearningMemberSession? memberSession,
    MovieListPreferences movieListPreferences =
        const SharedPreferencesMovieListPreferences(),
  }) {
    final resolvedCatalogService =
        catalogService ??
        LegacyMovieCatalogAdapter(
          movieService ?? const FakeMovieService(delay: Duration.zero),
        );
    final resolvedMemberApiService =
        memberApiService ?? MemberApiService.fromEnvironment();
    final resolvedTmdbMovieService =
        tmdbMovieService ??
        (resolvedCatalogService is TmdbMovieService
            ? resolvedCatalogService
            : TmdbMovieService.fromEnvironment());
    final resolvedMemberSession = memberSession ?? LearningMemberSession();
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => const StartScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterScreen(
            apiService: resolvedMemberApiService,
            session: resolvedMemberSession,
          ),
        ),
        GoRoute(
          path: '/my/ratings',
          builder: (context, state) {
            final memberId = resolvedMemberSession.memberId;
            if (memberId == null) return const _MemberRequiredScreen();
            return MemberRatingsScreen(
              viewModel: MemberRatingsViewModel(
                memberId: memberId,
                memberApiService: resolvedMemberApiService,
                movieService: resolvedTmdbMovieService,
              ),
            );
          },
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
            if (id == null) {
              return const _MovieNotFoundScreen();
            }
            return _MovieDetailLoader(
              key: ValueKey(id),
              movieId: id,
              catalogService: resolvedCatalogService,
              initialMovie: state.extra is Movie ? state.extra! as Movie : null,
              memberApiService: resolvedMemberApiService,
              memberSession: resolvedMemberSession,
            );
          },
        ),
        GoRoute(
          path: '/week05-api',
          builder: (context, state) =>
              Week05ApiScreen(apiService: resolvedMemberApiService),
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
    required this.memberApiService,
    required this.memberSession,
    this.initialMovie,
    super.key,
  });

  final int movieId;
  final MovieCatalogService catalogService;
  final MemberApiService memberApiService;
  final LearningMemberSession memberSession;
  final Movie? initialMovie;

  @override
  State<_MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<_MovieDetailLoader> {
  late Future<Movie?> _movie = widget.initialMovie == null
      ? _loadMovie()
      : Future.value(widget.initialMovie);

  Future<Movie?> _loadMovie() async {
    var genreNames = <int, String>{};
    try {
      final genres = await widget.catalogService.fetchGenres();
      genreNames = {for (final genre in genres) genre.id: genre.name};
    } on Object {
      // 장르 정보가 없어도 영화 상세 조회는 계속한다.
    }
    if (widget.catalogService case final TmdbMovieService service) {
      return (await service.fetchMovieById(widget.movieId)).toMovie(genreNames);
    }
    final movies = await widget.catalogService.fetchDiscover();
    for (final movie in movies) {
      if (movie.id == widget.movieId) return movie.toMovie(genreNames);
    }
    return null;
  }

  void _retry() {
    setState(() => _movie = _loadMovie());
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
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is TmdbApiException && error.statusCode == 404) {
            return const _MovieNotFoundScreen();
          }
          return _MovieDetailErrorScreen(onRetry: _retry);
        }
        final movie = snapshot.data;
        if (movie == null) {
          return const _MovieNotFoundScreen();
        }
        return MovieDetailScreen(
          viewModel: MovieDetailViewModel(
            ratingService: widget.memberApiService,
            memberId: widget.memberSession.memberId,
            movie: movie,
          ),
        );
      },
    );
  }
}

class _MemberRequiredScreen extends StatelessWidget {
  const _MemberRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 등록한 평점')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('먼저 회원가입을 완료해 주세요.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/register'),
              child: const Text('회원가입으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieDetailErrorScreen extends StatelessWidget {
  const _MovieDetailErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

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
            const Text('영화 정보를 불러오지 못했습니다.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
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
