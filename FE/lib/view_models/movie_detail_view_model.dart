import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_requests.dart';
import '../data/services/member_api_service.dart';
import '../models/movie.dart';
import 'sign_up_view_model.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel({
    required this.ratingService,
    required this.memberId,
    required this.movie,
  });

  final MemberApiService ratingService;
  final int? memberId;
  final Movie movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      _notify();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();
    try {
      await ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;
      submitMessage = memberApiErrorMessage(error);
    } on Object {
      submitStatus = SubmitStatus.error;
      submitMessage = '평점 저장에 실패했습니다. 다시 시도해 주세요.';
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
