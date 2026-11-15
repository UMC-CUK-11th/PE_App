import 'rating_dto.dart';
import 'tmdb_movie_dto.dart';

/// MovieLog 평점과 TMDB 영화 정보를 한 쌍으로 묶습니다.
class RatingWithMovie {
  const RatingWithMovie({required this.rating, this.movie});

  final RatingDto rating;

  /// TMDB에서 찾지 못했거나 조회에 실패하면 null이고, 화면은 placeholder를 그립니다.
  final TmdbMovieDto? movie;
}
