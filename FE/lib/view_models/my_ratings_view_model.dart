import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/rating_dto.dart';
import '../models/common_response.dart';
import '../models/rating_request.dart';
import '../models/tmdb_movie_dto.dart';
import '../services/rating_api_service.dart';
import '../services/tmdb_movie_service.dart';

enum MyRatingsStatus { idle, loading, empty, error, success }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._ratings, this._movies, {this.memberId});
  final int? memberId;
  final RatingApiService _ratings;
  final TmdbMovieService _movies;
  final CancelToken _cancelToken = CancelToken();
  MyRatingsStatus status = MyRatingsStatus.idle;
  List<RatingDto> ratings = const [];
  final Map<int, TmdbMovieDto> moviesById = {};
  final Set<int> failedMovieIds = {};
  String? errorMessage;
  bool _disposed = false;
  int _version = 0;
  bool isWriting = false;
  bool get canWrite =>
      memberId != null && !isWriting && status == MyRatingsStatus.success;

  Future<void> load() => isWriting ? Future.value() : _load();

  Future<void> _load() async {
    final memberId = this.memberId;
    if (memberId == null) return;
    if (_disposed || status == MyRatingsStatus.loading) return;
    final version = ++_version;
    status = MyRatingsStatus.loading;
    errorMessage = null;
    failedMovieIds.clear();
    notifyListeners();
    try {
      final items = await _ratings.fetchMyRatings(memberId);
      if (_disposed || version != _version) return;
      // 중복 영화는 한 번만 조회하고, 한 영화의 실패가 평점 전체를 지우지 않도록 합니다.
      final missingIds = items
          .map((r) => r.movieId)
          .toSet()
          .where((id) => !moviesById.containsKey(id))
          .toList();
      for (var start = 0; start < missingIds.length; start += 5) {
        if (_disposed || version != _version) return;
        await Future.wait(
          missingIds.skip(start).take(5).map((id) async {
            try {
              final movie = await _movies.fetchMovieDetail(
                id,
                cancelToken: _cancelToken,
              );
              if (!_disposed && version == _version) moviesById[id] = movie;
            } catch (_) {
              if (!_disposed && version == _version) failedMovieIds.add(id);
            }
          }),
        );
      }
      if (_disposed || version != _version) return;
      ratings = List.unmodifiable(items);
      status = items.isEmpty ? MyRatingsStatus.empty : MyRatingsStatus.success;
    } on DioException catch (error) {
      if (_disposed || version != _version) return;
      errorMessage = writeMyRatingsErrorMessage(error);
      status = MyRatingsStatus.error;
    } catch (_) {
      if (_disposed || version != _version) return;
      errorMessage = '평점 응답 형식을 확인하지 못했습니다. 다시 시도해 주세요.';
      status = MyRatingsStatus.error;
    }
    if (!_disposed && version == _version) notifyListeners();
  }

  Future<void> update(int ratingId, RatingInput input) async {
    final id = memberId;
    if (id == null || !canWrite) throw const ApiFailure('평점 목록을 다시 확인해 주세요.');
    isWriting = true;
    notifyListeners();
    try {
      final current = ratings.firstWhere(
        (rating) => rating.ratingId == ratingId,
      );
      final replacement = RatingInput(
        input.score,
        input.comment ?? current.comment,
      );
      await _ratings.update(id, ratingId, UpdateRatingRequest(replacement));
      await _load();
    } catch (error) {
      final failure = ApiFailure.from(error, '평점 수정에 실패했습니다.');
      if (failure.matches(403) || failure.matches(404)) await _load();
      throw failure;
    } finally {
      isWriting = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<Map<int, ApiFailure>> deleteSelected(Set<int> selected) async {
    final id = memberId;
    if (id == null || !canWrite) throw const ApiFailure('평점 목록을 다시 확인해 주세요.');
    isWriting = true;
    notifyListeners();
    final failures = <int, ApiFailure>{};
    final deleted = <int>{};
    try {
      for (final ratingId in selected) {
        if (_disposed) break;
        try {
          await _ratings.delete(id, ratingId);
          deleted.add(ratingId);
        } catch (error) {
          failures[ratingId] = ApiFailure.from(error, '평점 삭제에 실패했습니다.');
        }
      }
      ratings = List.unmodifiable(
        ratings.where((r) => !deleted.contains(r.ratingId)),
      );
      if (deleted.isNotEmpty ||
          failures.values.any(
            (error) => error.matches(403) || error.matches(404),
          )) {
        await _load();
      }
      return failures;
    } finally {
      isWriting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken.cancel();
    _version++;
    super.dispose();
  }
}
