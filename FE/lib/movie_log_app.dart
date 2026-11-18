import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/tmdb_client.dart';
import 'services/tmdb_movie_service.dart';
import 'services/movie_log_client.dart';
import 'services/member_check_service.dart';
import 'services/rating_api_service.dart';
import 'services/auth_api_service.dart';
import 'services/token_storage.dart';
import 'view_models/auth_session.dart';
import 'view_models/learning_member_session.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({
    this.router,
    this.learningSession,
    this.memberCheckService,
    this.ratingApiService,
    this.workbookClient,
    this.tokenStorage = const TokenStorage(),
    super.key,
  });
  final MemberCheckService? memberCheckService;
  final RatingApiService? ratingApiService;

  final GoRouter? router;
  final LearningMemberSession? learningSession;
  final Dio? workbookClient;
  final TokenStorage tokenStorage;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final Dio _workbook = widget.workbookClient ?? createMovieLogClient();
  late final AuthSession? _session;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    if (widget.router case final router?) {
      _session = null;
      _router = router;
    } else {
      final session = AuthSession(
        AuthApiService(_workbook),
        widget.tokenStorage,
      );
      _session = session;
      attachMovieLogAuth(_workbook, session);
      _router = AppRouter.createRouter(
        initialLocation: '/splash',
        session: session,
      );
      session.restore();
    }
  }

  @override
  void dispose() {
    if (_session != null) _router.dispose();
    _session?.dispose();
    if (widget.workbookClient == null) _workbook.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (_session case final session?)
          ChangeNotifierProvider.value(value: session),
        if (widget.learningSession case final session?)
          ChangeNotifierProvider.value(value: session)
        else
          ChangeNotifierProvider(create: (_) => LearningMemberSession()),
        Provider<MemberCheckService>(
          create: (_) =>
              widget.memberCheckService ??
              MemberCheckService(
                _workbook,
                version: _session == null ? 'v6' : 'v7',
              ),
        ),
        Provider<RatingApiService>(
          create: (_) => widget.ratingApiService ?? RatingApiService(_workbook),
        ),
        Provider<Dio>(
          create: (_) => createTmdbClient(),
          dispose: (_, dio) => dio.close(force: true),
        ),
        Provider<TmdbMovieService>(
          create: (context) => TmdbMovieService(context.read<Dio>()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
