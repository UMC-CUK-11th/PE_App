class MemberRating {
  const MemberRating({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemberRating.fromJson(Map<String, dynamic> json) {
    return MemberRating(
      ratingId: (json['ratingId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final int ratingId;
  final int movieId;
  final int score;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
}
