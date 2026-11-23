import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/rating_dto.dart';
import '../models/common_response.dart';
import '../models/rating_request.dart';
import '../models/tmdb_movie_dto.dart';
import '../services/rating_api_service.dart';
import '../services/tmdb_movie_service.dart';
import 'auth_session.dart';

enum MyRatingsStatus { idle, loading, empty, error, success }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._ratings,
    this._movies, {
    this.memberId,
    AuthSession? session,
  }) : _session = session,
       _sessionGeneration = session?.generation;
  final int? memberId;
  final AuthSession? _session;
  final int? _sessionGeneration;
  bool get hasSession => _session?.signedIn ?? (memberId != null);
  bool get _current =>
      !_disposed && (_session?.isCurrent(_sessionGeneration!) ?? true);
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
      hasSession &&
      _current &&
      !(_session?.busy ?? false) &&
      !isWriting &&
      status == MyRatingsStatus.success;

  Future<void> load() => isWriting ? Future.value() : _load();

  Future<void> _load() async {
    if (!hasSession || !_current || status == MyRatingsStatus.loading) return;
    final version = ++_version;
    status = MyRatingsStatus.loading;
    errorMessage = null;
    failedMovieIds.clear();
    notifyListeners();
    try {
      final items =
          _session?.ratings ?? await _ratings.fetchMyRatings(memberId!);
      if (!_current || version != _version) return;
      // 중복 영화는 한 번만 조회하고, 한 영화의 실패가 평점 전체를 지우지 않도록 합니다.
      final missingIds = items
          .map((r) => r.movieId)
          .toSet()
          .where((id) => !moviesById.containsKey(id))
          .toList();
      for (var start = 0; start < missingIds.length; start += 5) {
        if (!_current || version != _version) return;
        await Future.wait(
          missingIds.skip(start).take(5).map((id) async {
            try {
              final movie = await _movies.fetchMovieDetail(
                id,
                cancelToken: _cancelToken,
              );
              if (_current && version == _version) moviesById[id] = movie;
            } catch (_) {
              if (_current && version == _version) failedMovieIds.add(id);
            }
          }),
        );
      }
      if (!_current || version != _version) return;
      ratings = List.unmodifiable(items);
      status = items.isEmpty ? MyRatingsStatus.empty : MyRatingsStatus.success;
    } on DioException catch (error) {
      if (!_current || version != _version) return;
      errorMessage = writeMyRatingsErrorMessage(error);
      status = MyRatingsStatus.error;
    } catch (_) {
      if (!_current || version != _version) return;
      errorMessage = '평점 응답 형식을 확인하지 못했습니다. 다시 시도해 주세요.';
      status = MyRatingsStatus.error;
    }
    if (_current && version == _version) notifyListeners();
  }

  Future<void> update(int ratingId, RatingInput input) async {
    if (!canWrite) throw const ApiFailure('평점 목록을 다시 확인해 주세요.');
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
      final request = UpdateRatingRequest(replacement);
      final session = _session;
      if (session == null) {
        await _ratings.update(memberId!, ratingId, request);
      } else {
        final rating = await _ratings.updateForSession(ratingId, request);
        session.saveRating(_sessionGeneration!, rating);
      }
      if (!_current) return;
      await _load();
    } catch (error) {
      final failure = ApiFailure.from(error, '평점 수정에 실패했습니다.');
      if (_current && failure.matches(404)) {
        _session?.removeRating(_sessionGeneration!, ratingId);
      }
      if (failure.matches(403) || failure.matches(404)) await _load();
      throw failure;
    } finally {
      isWriting = false;
      if (_current) notifyListeners();
    }
  }

  Future<Map<int, ApiFailure>> deleteSelected(Set<int> selected) async {
    if (!canWrite) throw const ApiFailure('평점 목록을 다시 확인해 주세요.');
    isWriting = true;
    notifyListeners();
    final failures = <int, ApiFailure>{};
    final deleted = <int>{};
    try {
      for (final ratingId in selected) {
        if (!_current) return failures;
        try {
          final session = _session;
          if (session == null) {
            await _ratings.delete(memberId!, ratingId);
          } else {
            await _ratings.deleteForSession(ratingId);
            session.removeRating(_sessionGeneration!, ratingId);
          }
          deleted.add(ratingId);
        } catch (error) {
          final failure = ApiFailure.from(error, '평점 삭제에 실패했습니다.');
          failures[ratingId] = failure;
          if (_current && failure.matches(404)) {
            _session?.removeRating(_sessionGeneration!, ratingId);
          }
        }
      }
      if (!_current) return failures;
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
      if (_current) notifyListeners();
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
