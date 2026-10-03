import 'movie.dart';

const genresQueryKey = 'genres';

Set<String> parseGenres(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  return raw.split(',').where(allGenres.contains).toSet();
}

String moviesLocation(Set<String> genres) {
  if (genres.isEmpty) return '/movies';

  final ordered = allGenres.where(genres.contains).join(',');
  return Uri(
    path: '/movies',
    queryParameters: {genresQueryKey: ordered},
  ).toString();
}

List<Movie> filterMoviesByGenres(Set<String> genres) {
  if (genres.isEmpty) return movies;
  return movies.where((movie) => genres.contains(movie.genre)).toList();
}
