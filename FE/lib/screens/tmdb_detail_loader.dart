import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/tmdb_movie_service.dart';
import '../services/tmdb_client.dart';
import 'movie_detail_screen.dart';

class TmdbDetailLoader extends StatefulWidget {
  const TmdbDetailLoader({required this.id, required this.service, super.key});
  final int id;
  final TmdbMovieService service;

  @override
  State<TmdbDetailLoader> createState() => _TmdbDetailLoaderState();
}

class _TmdbDetailLoaderState extends State<TmdbDetailLoader> {
  final CancelToken _cancelToken = CancelToken();
  late Future<Movie> _movie = _load();

  Future<Movie> _load() async {
    final dto = await widget.service.fetchDetail(
      widget.id,
      cancelToken: _cancelToken,
    );
    final genres = await widget.service.fetchGenres(cancelToken: _cancelToken);
    return dto.toMovie(genres);
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Movie>(
    future: _movie,
    builder: (context, snapshot) {
      if (snapshot.hasData) return MovieDetailScreen(movie: snapshot.data!);
      return Scaffold(
        appBar: AppBar(title: const Text('영화 상세')),
        body: Center(
          child: snapshot.hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tmdbErrorMessage(snapshot.error!)),
                    FilledButton(
                      onPressed: () => setState(() => _movie = _load()),
                      child: const Text('다시 시도'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
