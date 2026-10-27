import 'movie.dart';

class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.genreIds,
    required this.voteAverage,
    required this.overview,
    this.posterPath,
    this.releaseDate,
  });

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? json['name'] as String? ?? '제목 없음',
      genreIds: (json['genre_ids'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((id) => id.toInt())
          .toList(growable: false),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      releaseDate: json['release_date'] as String?,
    );
  }

  final int id;
  final String title;
  final List<int> genreIds;
  final double voteAverage;
  final String overview;
  final String? posterPath;
  final String? releaseDate;

  Movie toMovie(Map<int, String> genreNames) {
    final parsedDate = DateTime.tryParse(releaseDate ?? '');
    return Movie(
      id: id,
      title: title,
      genres: genreIds
          .map((id) => genreNames[id])
          .whereType<String>()
          .toList(growable: false),
      genreIds: genreIds,
      year: parsedDate?.year ?? 0,
      durationMinutes: 0,
      posterUrl: posterPath == null
          ? null
          : 'https://image.tmdb.org/t/p/w500$posterPath',
      rating: voteAverage / 2,
      synopsis: overview.isEmpty ? '등록된 줄거리가 없습니다.' : overview,
    );
  }
}

class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.totalPages,
    required this.results,
  });

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    return TmdbMoviePageDto(
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      results: rawResults
          .whereType<Map<String, dynamic>>()
          .map(TmdbMovieDto.fromJson)
          .toList(growable: false),
    );
  }

  final int page;
  final int totalPages;
  final List<TmdbMovieDto> results;
}
