import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/movielog_member_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsStatus { loading, success, empty, error }

class MyRating {
  const MyRating(this.rating, this.movie);

  final RatingDto rating;

  /// TMDB 조회에 실패하면 null이고, 화면은 movieId만 보여 줍니다.
  final TmdbMovieDto? movie;
}

/// 마이 화면의 "내 평점" 영역. 평점은 MovieLog API, 영화 정보는 TMDB에서 가져옵니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._memberService,
    this._tmdbService, {
    this.memberId = 1,
  });

  // TODO(7주차 로그인): 토큰의 회원 ID로 교체합니다. 지금은 시드 데이터 1번 회원입니다.
  final int memberId;
  final MovieLogMemberService _memberService;
  final TmdbMovieService _tmdbService;

  List<MyRating> ratings = const [];
  MyRatingsStatus status = MyRatingsStatus.loading;
  bool _disposed = false;

  Future<void> load() async {
    status = MyRatingsStatus.loading;
    notifyListeners();

    try {
      final fetched = await _memberService.fetchRatings(memberId);
      final movies = await Future.wait(
        fetched.map((r) => _movieOrNull(r.movieId)),
      );
      if (_disposed) return;
      ratings = [
        for (var i = 0; i < fetched.length; i++)
          MyRating(fetched[i], movies[i]),
      ];
      status = ratings.isEmpty
          ? MyRatingsStatus.empty
          : MyRatingsStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      debugPrint('내 평점 조회 실패: ${error.response?.statusCode} ${error.message}');
      status = MyRatingsStatus.error;
    }
    notifyListeners();
  }

  Future<TmdbMovieDto?> _movieOrNull(int movieId) async {
    try {
      return await _tmdbService.fetchMovie(movieId);
    } on DioException {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
