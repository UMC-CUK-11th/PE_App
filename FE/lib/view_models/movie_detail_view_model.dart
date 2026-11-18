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

  /// 실패를 Dialog 밖 Snackbar로 안내해야 하는 오류인지(이미 평점·즐겨찾기, 회원 없음).
  bool closeDialog = false;
  bool _disposed = false;

  /// addToFavorites면 POST /v8/movie-records로 평점·즐겨찾기를 한 트랜잭션에 저장합니다.
  Future<void> createRating({
    required int score,
    String? comment,
    bool addToFavorites = false,
  }) async {
    if (submitStatus == SubmitStatus.submitting) return;
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    closeDialog = false;
    _notify();

    try {
      final request = CreateRatingRequest(
        movieId: movieId,
        score: score,
        comment: comment,
      );
      final rating = addToFavorites
          ? await _ratingService.createMovieRecord(
              request: request,
              addToFavorites: true,
            )
          : await _ratingService.createRating(request);
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
        // 409·404는 Dialog를 닫고 안내, 400·네트워크는 Dialog 안에서 재시도합니다.
        submitMessage = writeErrorMessage(error);
        final code = apiErrorCode(error);
        closeDialog =
            code == 'RATING409_1' ||
            code == 'FAVORITE409_1' ||
            code == 'MEMBER404_1';
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
