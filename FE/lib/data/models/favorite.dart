class FavoriteRecord {
  const FavoriteRecord({
    required this.favoriteId,
    required this.movieId,
    this.createdAt,
  });

  factory FavoriteRecord.fromJson(Map<String, dynamic> json) {
    return FavoriteRecord(
      favoriteId: (json['favoriteId'] as num?)?.toInt() ?? 0,
      movieId: (json['movieId'] as num).toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  final int favoriteId;
  final int movieId;
  final DateTime? createdAt;
}

class FavoriteStatus {
  const FavoriteStatus({required this.isFavorite});

  factory FavoriteStatus.fromJson(Map<String, dynamic> json) =>
      FavoriteStatus(isFavorite: json['isFavorite'] as bool? ?? false);

  final bool isFavorite;
}

class MovieRecordRequest {
  const MovieRecordRequest({
    required this.movieId,
    required this.score,
    required this.addToFavorites,
    this.comment,
  });

  final int movieId;
  final int score;
  final String? comment;
  final bool addToFavorites;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
    'addToFavorites': addToFavorites,
  };
}
