import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty }

/// "내가 등록한 평점" 화면. v7에는 토큰 기반 내 평점 목록 GET이 없어
/// 이번 로그인 세션에서 등록한 Rating(AuthViewModel.sessionRatings)만 보여주고 수정·삭제합니다.
/// 영화 제목·포스터는 movieId(TMDB id)로 TMDB에서 찾고, 없으면 placeholder로 둡니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this._auth);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final AuthViewModel _auth;
  final Map<int, TmdbMovieDto?> _movieCache = {};

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  /// Challenge: 다중 선택 편집 모드와 선택한 ratingId 목록입니다.
  bool isEditing = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  int _requestVersion = 0;
  bool _disposed = false;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    _notify();

    var missingMovies = 0;
    for (final rating in _auth.sessionRatings.toList()) {
      // 같은 movieId는 한 번만 조회하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
      if (_movieCache.containsKey(rating.movieId)) continue;
      try {
        _movieCache[rating.movieId] = await _movieService.findMovieById(
          rating.movieId,
        );
      } on DioException {
        missingMovies++; // 일시적 실패는 캐시하지 않아 다음 로딩에서 다시 시도합니다.
      }
      if (!_isCurrent(version)) return;
    }
    _rebuild();
    if (missingMovies > 0) {
      message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
    }
    _notify();
  }

  void _rebuild() {
    ratings = [
      for (final rating in _auth.sessionRatings)
        RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
    ];
    status = ratings.isEmpty
        ? MyRatingsLoadStatus.empty
        : MyRatingsLoadStatus.success;
  }

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 401은 세션 정리, 404는 이미 없는 평점이라 목록에서 뺍니다. 403·409는 안내만 합니다.
  Future<void> _handleWriteError(DioException error, int ratingId) async {
    if (isSessionExpiredError(error)) {
      await _auth.expireSession();
    } else if (apiErrorCode(error) == 'RATING404_1') {
      _auth.removeSessionRating(ratingId);
      _rebuild();
      _notify();
    }
  }

  /// comment는 항상 보냅니다. 빼면 서버가 기존 후기를 null로 덮습니다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final version = _auth.sessionVersion;
    final RatingDto updated;
    try {
      updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      if (version == _auth.sessionVersion) {
        await _handleWriteError(error, ratingId);
      }
      rethrow; // Dialog가 실패로 처리해 서버 문구를 보여줍니다.
    }
    if (version != _auth.sessionVersion) return;
    // 수정 result의 Rating 객체로 카드를 갱신합니다.
    _auth.replaceSessionRating(updated);
    _rebuild();
    _notify();
  }

  Future<void> deleteRating(int ratingId) async {
    final version = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
    } on DioException catch (error) {
      if (version == _auth.sessionVersion) {
        await _handleWriteError(error, ratingId);
      }
      rethrow;
    }
    if (version != _auth.sessionVersion) return;
    _auth.removeSessionRating(ratingId);
    _rebuild();
    _notify();
  }

  void startEditing() {
    isEditing = true;
    selectedRatingIds.clear();
    _notify();
  }

  void cancelEditing() {
    if (isDeletingSelected) return;
    isEditing = false;
    selectedRatingIds.clear();
    _notify();
  }

  void toggleSelected(int ratingId) {
    if (isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    _notify();
  }

  /// 선택한 ratingId마다 DELETE를 보냅니다. 실패한 항목은 선택 상태로 남겨 다시 시도할 수 있게 합니다.
  Future<void> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return;
    final version = _auth.sessionVersion;
    isDeletingSelected = true;
    _notify();

    var failed = 0;
    try {
      // 원본 Set을 돌면서 remove하면 ConcurrentModificationError가 나므로 복사본을 돕니다.
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(ratingId);
          if (version != _auth.sessionVersion) return;
          _auth.removeSessionRating(ratingId);
          selectedRatingIds.remove(ratingId);
        } on DioException catch (error) {
          if (version != _auth.sessionVersion) return;
          if (isSessionExpiredError(error)) {
            await _auth.expireSession(); // 남은 요청도 같은 401이므로 멈춥니다.
            return;
          }
          if (apiErrorCode(error) == 'RATING404_1') {
            // 이미 서버에 없는 평점은 목록과 선택에서 뺍니다.
            _auth.removeSessionRating(ratingId);
            selectedRatingIds.remove(ratingId);
          } else {
            failed++;
          }
        }
        if (_disposed) return;
      }
    } finally {
      isDeletingSelected = false;
      _notify(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }

    _rebuild();
    if (failed > 0) {
      message = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
    } else {
      isEditing = false;
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
