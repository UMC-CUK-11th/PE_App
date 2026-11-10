import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../data/models/member_rating.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/rating_requests.dart';
import '../data/services/member_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MemberRatingsLoadState { loading, empty, error, success }

class MemberRatingItem {
  const MemberRatingItem({required this.rating, this.movie});

  final MemberRating rating;
  final TmdbMovieDto? movie;

  String get title => movie?.title ?? '영화 #${rating.movieId}';

  String? get posterUrl {
    final path = movie?.posterPath?.trim();
    return path == null || path.isEmpty
        ? null
        : 'https://image.tmdb.org/t/p/w342$path';
  }
}

class MemberRatingsViewModel extends ChangeNotifier {
  static const int _pageSize = 100;
  static const int _movieFetchBatchSize = 8;

  MemberRatingsViewModel({
    required this.memberId,
    required this.memberApiService,
    required this.movieService,
  });

  final int memberId;
  final MemberApiService memberApiService;
  final TmdbMovieService movieService;

  MemberRatingsLoadState state = MemberRatingsLoadState.loading;
  List<MemberRatingItem> items = const [];
  final Set<int> selectedRatingIds = {};
  final Set<int> busyRatingIds = {};
  bool isSelectionMode = false;
  bool isDeletingSelected = false;
  String? message;
  String? refreshWarning;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed) return;
    state = MemberRatingsLoadState.loading;
    _notifyListeners();
    try {
      final ratings = await _fetchAllRatings();
      if (_disposed) return;
      if (ratings.isEmpty) {
        items = const [];
        state = MemberRatingsLoadState.empty;
        _notifyListeners();
        return;
      }
      items = await _fetchRatingItems(ratings);
      if (_disposed) return;
      state = MemberRatingsLoadState.success;
    } on Object {
      if (_disposed) return;
      items = const [];
      state = MemberRatingsLoadState.error;
    }
    _notifyListeners();
  }

  void startSelectionMode() {
    if (isSelectionMode) return;
    isSelectionMode = true;
    _notifyListeners();
  }

  void cancelSelectionMode() {
    isSelectionMode = false;
    selectedRatingIds.clear();
    _notifyListeners();
  }

  void toggleSelection(int ratingId) {
    if (!isSelectionMode) return;
    if (!selectedRatingIds.add(ratingId)) {
      selectedRatingIds.remove(ratingId);
    }
    _notifyListeners();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    if (busyRatingIds.contains(ratingId)) return;
    busyRatingIds.add(ratingId);
    message = null;
    _notifyListeners();
    try {
      await memberApiService.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        request: UpdateRatingRequest(score: score, comment: comment),
      );
    } on DioException catch (error) {
      message = memberApiErrorMessage(error);
      if (_shouldRefreshAfterWriteError(error)) await load();
      rethrow;
    } finally {
      busyRatingIds.remove(ratingId);
      _notifyListeners();
    }
    await _refreshAfterWrite();
  }

  Future<void> deleteRating(int ratingId) async {
    if (busyRatingIds.contains(ratingId)) return;
    busyRatingIds.add(ratingId);
    message = null;
    _notifyListeners();
    try {
      await memberApiService.deleteRating(
        memberId: memberId,
        ratingId: ratingId,
      );
    } on DioException catch (error) {
      message = memberApiErrorMessage(error);
      if (_shouldRefreshAfterWriteError(error)) await load();
      rethrow;
    } finally {
      busyRatingIds.remove(ratingId);
      _notifyListeners();
    }
    await _refreshAfterWrite();
  }

  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    isDeletingSelected = true;
    message = null;
    _notifyListeners();
    var failed = 0;
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await memberApiService.deleteRating(
            memberId: memberId,
            ratingId: ratingId,
          );
          selectedRatingIds.remove(ratingId);
          items = items
              .where((item) => item.rating.ratingId != ratingId)
              .toList(growable: false);
        } on DioException {
          failed++;
        }
      }
    } finally {
      isDeletingSelected = false;
      if (selectedRatingIds.isEmpty) isSelectionMode = false;
      _notifyListeners();
    }
    await _refreshAfterWrite();
    if (failed > 0) {
      message = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
      _notifyListeners();
    }
    return failed;
  }

  Future<void> _refreshAfterWrite() async {
    await load();
    if (state == MemberRatingsLoadState.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      _notifyListeners();
    } else {
      refreshWarning = null;
    }
  }

  bool _shouldRefreshAfterWriteError(DioException error) {
    final code = memberApiErrorCode(error);
    return code == 'COMMON403' || code == 'COMMON404';
  }

  Future<List<MemberRating>> _fetchAllRatings() async {
    final ratings = <MemberRating>[];
    var page = 0;
    while (true) {
      final currentPage = await memberApiService.fetchRatings(
        memberId,
        page: page,
        size: _pageSize,
      );
      if (_disposed) return const [];
      ratings.addAll(currentPage);
      if (currentPage.length < _pageSize) return ratings;
      page++;
    }
  }

  Future<List<MemberRatingItem>> _fetchRatingItems(
    List<MemberRating> ratings,
  ) async {
    final ratingItems = <MemberRatingItem>[];
    for (var start = 0; start < ratings.length; start += _movieFetchBatchSize) {
      if (_disposed) return const [];
      final batchEnd = start + _movieFetchBatchSize;
      final end = batchEnd < ratings.length ? batchEnd : ratings.length;
      final batch = ratings.sublist(start, end);
      ratingItems.addAll(
        await Future.wait(
          batch.map((rating) async {
            try {
              final movie = await movieService.fetchMovieById(rating.movieId);
              return MemberRatingItem(rating: rating, movie: movie);
            } on Object {
              return MemberRatingItem(rating: rating);
            }
          }),
        ),
      );
    }
    return ratingItems;
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
