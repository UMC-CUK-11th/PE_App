class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final int ratingId;

  /// TMDB 영화 ID. 제목·포스터는 TMDB에서 다시 조회합니다.
  final int movieId;
  final int score;
  final String? comment;
  final DateTime? createdAt;

  factory RatingDto.fromJson(Map<String, dynamic> json) {
    return RatingDto(
      ratingId: (json['ratingId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
