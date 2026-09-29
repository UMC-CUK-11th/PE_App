class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.year,
    required this.durationMinutes,
    required this.posterAsset,
    required this.rating,
    required this.synopsis,
  });

  final int id;
  final String title;
  final List<String> genres;
  final int year;
  final int durationMinutes;
  final String posterAsset;
  final double rating;
  final String synopsis;

  String get genreLabel => genres.join(' · ');
  String get metadata => '$year · $genreLabel';
}
