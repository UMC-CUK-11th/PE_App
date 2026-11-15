class RatingInput {
  RatingInput(this.score, this.comment) {
    if (score < 1 || score > 5) throw RangeError.range(score, 1, 5);
  }
  final int score;
  final String? comment;
}

class CreateRatingRequest {
  const CreateRatingRequest(this.movieId, this.input);
  final int movieId;
  final RatingInput input;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': input.score,
    if (input.comment?.isNotEmpty == true) 'comment': input.comment,
  };
}

class UpdateRatingRequest {
  const UpdateRatingRequest(this.input);
  final RatingInput input;

  Map<String, dynamic> toJson() => {
    'score': input.score,
    // v6 PATCH replaces the whole rating. Omitting comment clears it.
    if (input.comment?.isNotEmpty == true) 'comment': input.comment,
  };
}
