import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';
import 'auth_view_model.dart';

/// 영화 상세의 즐겨찾기 버튼 상태. 서버 성공을 확인한 뒤에만 북마크를 바꿉니다(optimistic update 없음).
class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.auth,
  }) : _sessionVersion = auth.sessionVersion;

  /// 상세 화면의 TMDB 영화 ID. 즐겨찾기 경로에는 favoriteId가 아니라 이 값을 씁니다.
  final int movieId;
  final FavoriteApiService favoriteApi;
  final AuthViewModel auth;

  /// 이 ViewModel을 만든 로그인 세션. 로그아웃·계정 전환 뒤 늦은 응답은 버립니다.
  final int _sessionVersion;

  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  bool get _alive => !isDisposed && auth.sessionVersion == _sessionVersion;

  Future<void> load() async {
    if (isLoading || isSaving || !_alive) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final favorite = await favoriteApi.checkFavorite(movieId);
      if (!_alive) return;
      isFavorite = favorite;
      hasLoadedStatus = true;
    } on DioException catch (error) {
      if (!_alive) return;
      if (await _expiredSession(error)) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } catch (_) {
      if (!_alive) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (_alive) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  /// 등록·해제 중에는 중복 탭을 막고, timeout이어도 같은 POST를 자동 재전송하지 않습니다.
  Future<void> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus || !_alive) return;
    final before = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId);
      } else {
        await favoriteApi.addFavorite(movieId);
      }
      if (!_alive) return;
      isFavorite = !before;
    } on DioException catch (error) {
      if (!_alive) return;
      if (await _expiredSession(error)) return;
      final code = apiErrorCode(error);
      // 이미 등록(409)·이미 해제(404)면 POST/DELETE를 반복하지 않고 현재 여부로 맞춥니다.
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final synced = await favoriteApi.checkFavorite(movieId);
          if (!_alive) return;
          isFavorite = synced;
        } catch (_) {
          if (!_alive) return;
          errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
        }
      } else {
        errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
      }
    } catch (_) {
      if (!_alive) return;
      errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
    } finally {
      if (_alive) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }

  /// AUTH401_2/3/4만 세션 정리. 403·네트워크 실패는 로그아웃하지 않습니다.
  Future<bool> _expiredSession(DioException error) async {
    if (!isSessionExpiredError(error)) return false;
    await auth.expireSession();
    return true;
  }
}
