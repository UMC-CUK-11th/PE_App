import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_models.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'load_phase.dart';

/// 내 즐겨찾기. MovieLog 목록을 받고 movieId로 TMDB 제목·포스터를 최대 5개씩 보충합니다.
class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.auth,
    this.enrichmentConcurrency = 5,
  }) : _sessionVersion = auth.sessionVersion;

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final AuthViewModel auth;
  final int enrichmentConcurrency;
  final int _sessionVersion;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;
  int _refreshGeneration = 0;

  bool _isCurrent(int generation) =>
      !isDisposed &&
      auth.sessionVersion == _sessionVersion &&
      generation == _refreshGeneration;

  Future<void> refresh() async {
    if (isDisposed || auth.sessionVersion != _sessionVersion) return;
    final generation = ++_refreshGeneration;
    // 이미 목록이 있으면 갱신 중에도 지우지 않고, 처음일 때만 로딩 화면을 보여줍니다.
    if (items.isEmpty) phase = LoadPhase.loading;
    errorMessage = null;
    notifyIfAlive();

    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (!_isCurrent(generation)) return;
      // 한 건 실패가 전체 목록을 비우지 않도록 카드별 실패를 결과로 바꿉니다.
      final enriched = await mapBounded(favorites, enrichmentConcurrency, (
        favorite,
      ) async {
        try {
          final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
          return FavoriteListItem(favorite: favorite, movie: movie);
        } catch (_) {
          return FavoriteListItem(
            favorite: favorite,
            errorMessage: '영화 정보를 불러오지 못했습니다.',
          );
        }
      });
      if (!_isCurrent(generation)) return;
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } on DioException catch (error) {
      if (!_isCurrent(generation)) return;
      if (isSessionExpiredError(error)) {
        await auth.expireSession();
        return;
      }
      phase = LoadPhase.error;
      errorMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
    } catch (_) {
      if (!_isCurrent(generation)) return;
      phase = LoadPhase.error;
      errorMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
    }
    notifyIfAlive();
  }

  /// 영화 정보만 실패한 카드 하나를 다시 조회합니다. 다른 카드는 그대로 둡니다.
  Future<void> retryMovie(int movieId) async {
    final generation = _refreshGeneration;
    try {
      final movie = await tmdbApi.fetchMovieDetail(movieId);
      if (!_isCurrent(generation)) return;
      items = [
        for (final item in items)
          item.favorite.movieId == movieId
              ? FavoriteListItem(favorite: item.favorite, movie: movie)
              : item,
      ];
    } catch (_) {
      return; // 카드의 실패 안내를 그대로 둡니다.
    }
    notifyIfAlive();
  }
}
