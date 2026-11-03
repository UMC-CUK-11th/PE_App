import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/rating_dto.dart';
import '../models/tmdb_movie_dto.dart';
import '../services/rating_api_service.dart';
import '../services/tmdb_movie_service.dart';

enum MyRatingsStatus { idle, loading, empty, error, success }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._ratings, this._movies);
  static const memberId = 1; // 학습용 공개 회원. 로그인한 사용자가 아닙니다.
  final RatingApiService _ratings;
  final TmdbMovieService _movies;
  MyRatingsStatus status = MyRatingsStatus.idle;
  List<RatingDto> ratings = const [];
  final Map<int, TmdbMovieDto> moviesById = {};
  final Set<int> failedMovieIds = {};
  String? errorMessage;
  bool _disposed = false;
  int _version = 0;

  Future<void> load() async {
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
      await Future.wait(
        items.map((r) => r.movieId).toSet().map((id) async {
          if (moviesById.containsKey(id)) return;
          try {
            final movie = await _movies.fetchMovieDetail(id);
            if (!_disposed && version == _version) moviesById[id] = movie;
          } catch (_) {
            if (!_disposed && version == _version) failedMovieIds.add(id);
          }
        }),
      );
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

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
