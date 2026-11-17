import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// "내가 등록한 평점" 화면. 평점은 MovieLog API, 영화 제목·포스터는 TMDB에서 가져옵니다.
/// memberId는 회원가입 결과를 보관한 LearningMemberSession에서 받습니다(인증 아님).
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  /// 쓰기는 성공했지만 뒤이은 GET이 실패했을 때만 채웁니다.
  String? refreshWarning;

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
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (!_isCurrent(version)) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;
      for (final rating in rawRatings) {
        // 같은 movieId는 한 번만 조회하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // 일시적 실패는 캐시하지 않아 다음 로딩에서 다시 시도합니다.
          }
          if (!_isCurrent(version)) return;
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }

      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }

    if (_isCurrent(version)) notifyListeners();
  }

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 저장 성공과 목록 재조회 실패를 나눕니다. GET 실패는 저장 실패로 다시 던지지 않습니다.
  Future<void> _refreshAfterWrite() async {
    await load();
    if (_disposed) return;
    refreshWarning = status == MyRatingsLoadStatus.error
        ? '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.'
        : null;
    _notify();
  }

  /// 재조회만 다시 시도합니다. 쓰기 요청은 다시 보내지 않습니다.
  Future<void> retryLoad() async {
    await load();
    if (_disposed) return;
    if (status != MyRatingsLoadStatus.error) refreshWarning = null;
    _notify();
  }

  /// comment는 항상 보냅니다. 빼면 서버가 기존 후기를 null로 덮습니다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow; // 쓰기 실패일 때만 Dialog가 실패로 처리합니다.
    }
    await _refreshAfterWrite();
  }

  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow;
    }
    await _refreshAfterWrite();
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
    isDeletingSelected = true;
    _notify();

    var failed = 0;
    try {
      // 원본 Set을 돌면서 remove하면 ConcurrentModificationError가 나므로 복사본을 돕니다.
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(memberId: memberId, ratingId: ratingId);
          selectedRatingIds.remove(ratingId);
        } on DioException {
          failed++;
        }
        if (_disposed) return;
      }
    } finally {
      isDeletingSelected = false;
      _notify(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }

    await _refreshAfterWrite();
    if (_disposed) return;
    // 실패했지만 이미 서버에서 사라진 항목(404 등)은 선택에서 뺍니다.
    selectedRatingIds.removeWhere(
      (id) => !ratings.any((entry) => entry.rating.ratingId == id),
    );
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
