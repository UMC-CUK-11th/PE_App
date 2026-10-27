import 'movie.dart';

class TmdbGenreDto {
  const TmdbGenreDto({required this.id, required this.name});
  final int id;
  final String name;

  factory TmdbGenreDto.fromJson(Map<String, dynamic> json) => TmdbGenreDto(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
  );
}

class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    this.posterPath,
    this.genreIds = const [],
    this.overview = '',
    this.releaseDate = '',
    this.voteAverage = 0,
    this.voteCount = 0,
    this.runtime = 0,
  });

  final int id;
  final String title;
  final String? posterPath;
  final List<int> genreIds;
  final String overview;
  final String releaseDate;
  final double voteAverage;
  final int voteCount;
  final int runtime;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) => TmdbMovieDto(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? json['original_title'] as String? ?? '',
    posterPath: json['poster_path'] as String?,
    genreIds:
        ((json['genre_ids'] as List?) ??
                (json['genres'] as List?)?.map((g) => g['id']).toList() ??
                const [])
            .map((id) => (id as num).toInt())
            .toList(),
    overview: json['overview'] as String? ?? '',
    releaseDate: json['release_date'] as String? ?? '',
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
    voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
    runtime: (json['runtime'] as num?)?.toInt() ?? 0,
  );

  Movie toMovie(List<TmdbGenreDto> genres) => Movie(
    id: id,
    title: title,
    genres: genreIds
        .map(
          (id) =>
              genres.where((g) => g.id == id).map((g) => g.name).firstOrNull ??
              '기타',
        )
        .toList(),
    year: DateTime.tryParse(releaseDate)?.year ?? 0,
    durationMinutes: runtime,
    posterAsset: '',
    posterPath: posterPath,
    genreIds: List.unmodifiable(genreIds),
    rating: double.parse((voteAverage / 2).toStringAsFixed(1)),
    voteCount: voteCount,
    synopsis: overview.isEmpty ? '등록된 줄거리가 없습니다.' : overview,
  );
}

class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.totalPages,
    required this.results,
  });
  final int page;
  final int totalPages;
  final List<TmdbMovieDto> results;

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) =>
      TmdbMoviePageDto(
        page: (json['page'] as num?)?.toInt() ?? 1,
        totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
        results: (json['results'] as List? ?? const [])
            .map(
              (m) => TmdbMovieDto.fromJson(Map<String, dynamic>.from(m as Map)),
            )
            .toList(),
      );
}
