import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

final List<Movie> movies = [
  const Movie(id: 1, title: '기생충'),
  const Movie(id: 2, title: '인터스텔라'),
  const Movie(id: 3, title: '인사이드 아웃'),
];

String displayName(String? nickname) {
  final trimmedNickname = nickname?.trim();

  if (trimmedNickname == null || trimmedNickname.isEmpty) {
    return '이름 없음';
  }

  return trimmedNickname;
}

void runDartPractice() {
  for (final movie in movies) {
    debugPrint(movie.title);
  }

  final nickname = displayName(null);
  debugPrint(nickname);

  final titleById = <int, String>{
    for (final movie in movies) movie.id: movie.title,
  };
  final (:id, :title) = (id: movies.first.id, title: movies.first.title);
  debugPrint(
    '${const ValueKey('movie-card')}: $id / $title / ${titleById[id]}',
  );
}

abstract interface class MovieLookup {
  Future<Movie> findById(int id);
}

mixin RequestGeneration {
  int _generation = 0;

  int beginRequest() => ++_generation;
  bool isCurrentRequest(int value) => value == _generation;
  void invalidateRequests() => _generation++;
}

Future<List<Movie?>> loadMoviesIndependently(
  MovieLookup lookup,
  List<int> ids,
) {
  return Future.wait(
    ids.map((id) async {
      try {
        return await lookup.findById(id);
      } on Object {
        return null;
      }
    }),
  );
}
