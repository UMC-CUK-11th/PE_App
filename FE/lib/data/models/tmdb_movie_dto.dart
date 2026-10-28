import '../../models/movie.dart';

class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.genreIds,
    required this.voteAverage,
    required this.overview,
    this.posterPath,
    this.posterAsset,
    this.releaseDate,
    this.durationMinutes = 0,
  });

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? json['name'] as String? ?? '제목 없음',
      genreIds: json['genre_ids'] is List<dynamic>
          ? (json['genre_ids'] as List<dynamic>)
                .whereType<num>()
                .map((id) => id.toInt())
                .toList(growable: false)
          : (json['genres'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map((genre) => genre['id'])
                .whereType<num>()
                .map((id) => id.toInt())
                .toList(growable: false),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      releaseDate: json['release_date'] as String?,
      durationMinutes: (json['runtime'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final String title;
  final List<int> genreIds;
  final double voteAverage;
  final String overview;
  final String? posterPath;
  final String? posterAsset;
  final String? releaseDate;
  final int durationMinutes;

  Movie toMovie(Map<int, String> genreNames) {
    final parsedDate = DateTime.tryParse(releaseDate ?? '');
    final normalizedPosterPath = posterPath?.trim();
    return Movie(
      id: id,
      title: title,
      genres: genreIds
          .map((id) => genreNames[id])
          .whereType<String>()
          .toList(growable: false),
      genreIds: genreIds,
      year: parsedDate?.year ?? 0,
      durationMinutes: durationMinutes,
      posterAsset: posterAsset,
      posterUrl: normalizedPosterPath == null || normalizedPosterPath.isEmpty
          ? null
          : 'https://image.tmdb.org/t/p/w500$normalizedPosterPath',
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
