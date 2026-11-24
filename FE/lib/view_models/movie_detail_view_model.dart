import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_requests.dart';
import '../data/models/favorite.dart';
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
  bool isFavorite = false;
  bool isFavoriteLoading = true;
  bool isFavoriteSaving = false;
  String? favoriteMessage;
  bool _disposed = false;
  int _favoriteRequestVersion = 0;
  Future<void>? _favoriteLoadFuture;

  Future<void> loadFavorite() {
    final future = _loadFavorite();
    _favoriteLoadFuture = future;
    return future;
  }

  Future<void> _loadFavorite() async {
    final requestVersion = ++_favoriteRequestVersion;
    if (memberId == null) {
      isFavoriteLoading = false;
      _notify();
      return;
    }
    isFavoriteLoading = true;
    favoriteMessage = null;
    _notify();
    try {
      final result = await ratingService.fetchFavoriteStatus(movie.id);
      if (requestVersion != _favoriteRequestVersion || _disposed) return;
      isFavorite = result;
    } on DioException catch (error) {
      if (requestVersion != _favoriteRequestVersion || _disposed) return;
      favoriteMessage = memberApiErrorMessage(error);
    } on Object {
      if (requestVersion != _favoriteRequestVersion || _disposed) return;
      favoriteMessage = '즐겨찾기 상태를 불러오지 못했습니다.';
    }
    if (requestVersion != _favoriteRequestVersion || _disposed) return;
    isFavoriteLoading = false;
    _notify();
  }

  Future<bool> toggleFavorite() async {
    if (memberId == null || isFavoriteLoading || isFavoriteSaving) return false;
    final previous = isFavorite;
    isFavoriteSaving = true;
    favoriteMessage = null;
    isFavorite = !previous;
    _notify();
    try {
      if (isFavorite) {
        await ratingService.createFavorite(movie.id);
      } else {
        await ratingService.deleteFavorite(movie.id);
      }
      return true;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (isFavorite && status == 409) {
        isFavorite = true;
        return true;
      }
      if (!isFavorite && status == 404) {
        isFavorite = false;
        return true;
      }
      favoriteMessage = memberApiErrorMessage(error);
      isFavorite = previous;
      return false;
    } on Object {
      favoriteMessage = '즐겨찾기 변경에 실패했습니다. 다시 시도해 주세요.';
      isFavorite = previous;
      return false;
    } finally {
      isFavoriteSaving = false;
      _notify();
    }
  }

  Future<void> createRating({
    required int score,
    String? comment,
    bool addToFavorites = false,
  }) async {
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
      if (addToFavorites && isFavoriteLoading) {
        await _favoriteLoadFuture;
      }
      final shouldAddFavorite = addToFavorites && !isFavorite;
      if (shouldAddFavorite) {
        _favoriteRequestVersion++;
        await ratingService.createMovieRecord(
          MovieRecordRequest(
            movieId: movie.id,
            score: score,
            comment: comment,
            addToFavorites: true,
          ),
        );
        isFavorite = true;
      } else {
        await ratingService.createRating(
          request: CreateRatingRequest(
            movieId: movie.id,
            score: score,
            comment: comment,
          ),
        );
      }
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
