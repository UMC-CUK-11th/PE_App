import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/movielog_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/services/movielog_member_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 여러 Route가 공유하는 Service는 MaterialApp.router 위에 등록합니다.
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<MovieLogMemberService>(
          create: (_) => MovieLogMemberService(createMovieLogClient()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
