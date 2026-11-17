import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/storage/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = SecureTokenStorage(const FlutterSecureStorage());
    // 공개 Client에는 Interceptor가 없고, 보호 Client에만 Bearer를 붙입니다.
    // TMDB Client와 MovieLog Client는 Authorization이 섞이지 않도록 분리합니다.
    final publicClient = createMovieLogClient();
    final authClient = createAuthMovieLogClient(tokenStorage);

    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<AuthApiService>(create: (_) => AuthApiService(publicClient)),
        Provider<SignUpService>(create: (_) => SignUpService(publicClient)),
        Provider<MemberApiService>(create: (_) => MemberApiService(authClient)),
        Provider<FavoriteApiService>(
          create: (_) => FavoriteApiService(authClient),
        ),
        // 조회는 공개, 등록·수정·삭제는 보호 Client로 보냅니다.
        Provider<RatingApiService>(
          create: (_) => RatingApiService(publicClient, authClient),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
      ],
      child: const MovieLogRouterApp(),
    );
  }
}

/// Router를 한 번만 만들고 첫 프레임 뒤 세션 복원을 시작합니다.
class MovieLogRouterApp extends StatefulWidget {
  const MovieLogRouterApp({super.key, this.initialLocation = '/start'});

  final String initialLocation;

  @override
  State<MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(
      auth: auth,
      initialLocation: widget.initialLocation,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) auth.restoreSession();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
