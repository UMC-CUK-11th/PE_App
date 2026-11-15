class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
  });

  /// TMDB 영화 ID. 평점 저장 시 MovieLog API의 movieId로 그대로 보냅니다.
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final List<int> genreIds;
  final double voteAverage;
  final double popularity;

  /// release_date가 없거나 비어 있으면 null을 돌려 연도를 표시하지 않습니다.
  String? get year {
    final date = releaseDate;
    return date == null || date.length < 4 ? null : date.substring(0, 4);
  }

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    // 목록 응답은 genre_ids, 상세 응답은 genres[{id, name}]으로 내려옵니다.
    final rawGenreIds = json['genre_ids'] as List<dynamic>? ??
        (json['genres'] as List<dynamic>? ?? const [])
            .map((genre) => (genre as Map<String, dynamic>)['id'])
            .toList();

    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: rawGenreIds.map((value) => (value as num).toInt()).toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
    );
  }
}
