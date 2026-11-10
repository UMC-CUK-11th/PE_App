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
import 'view_models/learning_member_session.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    this.router,
    this.learningSession,
    this.memberCheckService,
    this.ratingApiService,
    super.key,
  });
  final MemberCheckService? memberCheckService;
  final RatingApiService? ratingApiService;

  final GoRouter? router;
  final LearningMemberSession? learningSession;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (learningSession case final session?)
          ChangeNotifierProvider.value(value: session)
        else
          ChangeNotifierProvider(create: (_) => LearningMemberSession()),
        Provider<_WorkbookClient>(
          create: (_) => _WorkbookClient(),
          dispose: (_, client) => client.dio.close(force: true),
        ),
        Provider<MemberCheckService>(
          create: (context) =>
              memberCheckService ??
              MemberCheckService(context.read<_WorkbookClient>().dio),
        ),
        Provider<RatingApiService>(
          create: (context) =>
              ratingApiService ??
              RatingApiService(context.read<_WorkbookClient>().dio),
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
        routerConfig: router ?? AppRouter.router,
      ),
    );
  }
}

class _WorkbookClient {
  final Dio dio = createMovieLogClient();
}
