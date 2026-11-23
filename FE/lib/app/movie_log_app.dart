import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/learning_member_session.dart';
import '../data/services/member_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/services/token_storage.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({this.router, super.key});

  final GoRouter? router;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final LearningMemberSession _session;
  late final MemberApiService _memberApi;
  late final AuthViewModel _authViewModel;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _session = LearningMemberSession();
    _memberApi = MemberApiService.fromEnvironment(session: _session);
    _authViewModel = AuthViewModel(
      _memberApi,
      _session,
      const SecureTokenStorage(),
    );
    _router =
        widget.router ??
        AppRouter.createRouter(
          initialLocation: '/splash',
          catalogService: TmdbMovieService.fromEnvironment(),
          memberApiService: _memberApi,
          memberSession: _session,
          authViewModel: _authViewModel,
        );
    if (widget.router == null) _authViewModel.restoreSession();
  }

  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    _authViewModel.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
    if (widget.router != null) return app;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authViewModel),
        ChangeNotifierProvider.value(value: _session),
      ],
      child: app,
    );
  }
}
