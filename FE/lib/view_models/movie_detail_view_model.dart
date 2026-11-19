import '../models/common_response.dart';
import '../models/rating_request.dart';
import '../services/rating_api_service.dart';
import 'learning_member_session.dart';
import 'auth_session.dart';

class MovieDetailViewModel {
  MovieDetailViewModel(this.movieId, this._ratings, this._session, {this.auth});
  final int movieId;
  final RatingApiService _ratings;
  final LearningMemberSession _session;
  final AuthSession? auth;
  bool isSaving = false;

  Future<void> register(RatingInput input) async {
    final memberId = _session.memberId;
    final session = auth;
    if (session == null
        ? memberId == null
        : !session.signedIn || session.busy) {
      throw const ApiFailure('로그인 후 평점을 등록해 주세요.');
    }
    if (isSaving) throw const ApiFailure('이미 평점을 저장하고 있습니다.');
    isSaving = true;
    try {
      final request = CreateRatingRequest(movieId, input);
      if (session == null) {
        await _ratings.create(memberId!, request);
      } else {
        final generation = session.generation;
        final rating = await _ratings.createForSession(request);
        session.saveRating(generation, rating);
      }
    } catch (error) {
      throw ApiFailure.from(error, '평점 등록에 실패했습니다.');
    } finally {
      isSaving = false;
    }
  }
}
