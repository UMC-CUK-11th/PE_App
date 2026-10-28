import 'package:flutter/foundation.dart';

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
}
