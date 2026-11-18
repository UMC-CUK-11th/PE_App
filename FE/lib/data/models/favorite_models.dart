import 'tmdb_movie_dto.dart';

/// 즐겨찾기 응답. 제목·포스터가 없어 movieId로 TMDB 정보를 붙입니다.
class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });

  final int favoriteId;

  /// TMDB 영화 ID. 해제·여부 조회 경로에도 favoriteId가 아니라 이 값을 씁니다.
  final int movieId;
  final DateTime createdAt;

  factory FavoriteResponseDto.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('FavoriteResponseDto must be a JSON object.');
    }
    return FavoriteResponseDto(
      favoriteId: (json['favoriteId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 내 즐겨찾기 카드. movie가 null이면 TMDB 보충만 실패한 카드입니다.
class FavoriteListItem {
  const FavoriteListItem({
    required this.favorite,
    this.movie,
    this.errorMessage,
  });

  final FavoriteResponseDto favorite;
  final TmdbMovieDto? movie;
  final String? errorMessage;
}
