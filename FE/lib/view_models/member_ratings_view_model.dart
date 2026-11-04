import 'package:flutter/foundation.dart';

import '../data/models/member_rating.dart';
import '../data/models/tmdb_movie_dto.dart';
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
      items = await Future.wait(
        ratings.map((rating) async {
          try {
            final movie = await movieService.fetchMovieById(rating.movieId);
            return MemberRatingItem(rating: rating, movie: movie);
          } on Object {
            return MemberRatingItem(rating: rating);
          }
        }),
      );
      if (_disposed) return;
      state = MemberRatingsLoadState.success;
    } on Object {
      if (_disposed) return;
      items = const [];
      state = MemberRatingsLoadState.error;
    }
    _notifyListeners();
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

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
