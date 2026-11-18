import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'sign_up_view_model.dart';

/// 영화 상세 화면의 평점 등록만 담당합니다. 회원은 path가 아니라 토큰으로 식별합니다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this._auth, this.movieId);

  final RatingApiService _ratingService;
  final AuthViewModel _auth;

  /// TMDB 영화 ID(TmdbMovieDto.id)입니다.
  final int movieId;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;

  /// 등록 result의 Rating 객체입니다. 화면의 "내 평점"을 이 값으로 갱신합니다.
  RatingDto? savedRating;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      final rating = await _ratingService.createRating(
        CreateRatingRequest(movieId: movieId, score: score, comment: comment),
      );
      // 로그아웃·회원 전환 뒤 늦게 온 응답은 반영하지 않습니다.
      if (version != _auth.sessionVersion) return;
      savedRating = rating;
      _auth.addSessionRating(rating);
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (version != _auth.sessionVersion) return;
      submitStatus = SubmitStatus.error;
      if (isSessionExpiredError(error)) {
        submitMessage = '로그인이 만료됐어요. 다시 로그인해 주세요.';
        await _auth.expireSession();
      } else {
        // 409 RATING409_1 등은 안내만 하고 로그인 상태를 유지합니다.
        submitMessage = writeErrorMessage(error);
      }
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
