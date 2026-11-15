import '../models/common_response.dart';
import '../models/rating_request.dart';
import '../services/rating_api_service.dart';
import 'learning_member_session.dart';

class MovieDetailViewModel {
  MovieDetailViewModel(this.movieId, this._ratings, this._session);
  final int movieId;
  final RatingApiService _ratings;
  final LearningMemberSession _session;
  bool isSaving = false;

  Future<void> register(RatingInput input) async {
    final memberId = _session.memberId;
    if (memberId == null) throw const ApiFailure('먼저 회원가입을 완료해 주세요.');
    if (isSaving) throw const ApiFailure('이미 평점을 저장하고 있습니다.');
    isSaving = true;
    try {
      await _ratings.create(memberId, CreateRatingRequest(movieId, input));
    } catch (error) {
      throw ApiFailure.from(error, '평점 등록에 실패했습니다.');
    } finally {
      isSaving = false;
    }
  }
}
