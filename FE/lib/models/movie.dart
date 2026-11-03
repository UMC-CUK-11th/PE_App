class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.year,
    required this.durationMinutes,
    this.posterAsset,
    this.posterUrl,
    this.genreIds = const [],
    required this.rating,
    required this.synopsis,
  });

  final int id;
  final String title;
  final List<String> genres;
  final int year;
  final int durationMinutes;
  final String? posterAsset;
  final String? posterUrl;
  final List<int> genreIds;
  final double rating;
  final String synopsis;

  String get genreLabel => genres.join(' · ');
  String get metadata {
    final values = <String>[
      if (year > 0) '$year',
      if (genreLabel.isNotEmpty) genreLabel,
    ];
    return values.join(' · ');
  }
}
