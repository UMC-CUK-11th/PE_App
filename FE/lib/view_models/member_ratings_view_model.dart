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

  Future<void> load() async {
    state = MemberRatingsLoadState.loading;
    notifyListeners();
    try {
      final ratings = await memberApiService.fetchRatings(memberId);
      if (ratings.isEmpty) {
        items = const [];
        state = MemberRatingsLoadState.empty;
        notifyListeners();
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
      state = MemberRatingsLoadState.success;
    } on Object {
      items = const [];
      state = MemberRatingsLoadState.error;
    }
    notifyListeners();
  }
}
