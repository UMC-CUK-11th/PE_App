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
    this.posterPath,
    this.genreIds = const [],
    this.voteCount,
  });

  final int id;
  final String title;
  final List<String> genres;
  final int year;
  final int durationMinutes;
  final String posterAsset;
  final double rating;
  final String synopsis;
  final String? posterPath;
  final List<int> genreIds;
  final int? voteCount;

  String? get posterUrl => posterPath == null || posterPath!.isEmpty
      ? null
      : 'https://image.tmdb.org/t/p/w500$posterPath';

  String get genreLabel => genres.join(' · ');
  String get metadata => '${year == 0 ? '개봉일 미정' : year} · $genreLabel';
}
