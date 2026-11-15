class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  final int movieId;
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    'comment': _normalizedComment(comment),
  };
}

class UpdateRatingRequest {
  const UpdateRatingRequest({required this.score, this.comment});

  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'score': score,
    'comment': _normalizedComment(comment),
  };
}

String? _normalizedComment(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
