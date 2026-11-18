import 'package:flutter/foundation.dart';

import '../data/genre_preference.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';
import 'paged_movies_view_model.dart';

/// 영화 목록 탭. 5주차의 "최대 30개 한 번에 수집" 대신 page를 하나씩 더 불러오고,
/// 장르 Chip·저장된 장르 복원만 여기서 더합니다.
class MovieListViewModel extends PagedMoviesViewModel {
  MovieListViewModel(TmdbMovieService service, this._genrePreference)
    : super(tmdbApi: service);

  final GenrePreference _genrePreference;

  List<TmdbGenreDto> genres = const [];

  /// null이면 "전체"이며 with_genres를 보내지 않습니다.
  List<int>? selectedGenreIds;
  String? genreError;

  bool get isLoading => phase == LoadPhase.loading;

  /// 첫 page 요청 중에는 장르를 바꾸지 못하게 합니다.
  bool get canChangeGenre => !isLoading;

  String genreNamesOf(TmdbMovieDto movie) {
    final names = {for (final genre in genres) genre.id: genre.name};
    return movie.genreIds.map((id) => names[id]).nonNulls.take(2).join('/');
  }

  /// Genre API로 Chip을 구성하고 저장된 장르를 복원한 뒤 첫 page를 불러옵니다.
  Future<void> start() async {
    genreError = null;
    phase = LoadPhase.loading;
    notifyIfAlive();
    try {
      final (fetchedGenres, savedIds) = await (
        tmdbApi.fetchGenres(),
        _genrePreference.read(),
      ).wait;
      if (isDisposed) return;
      genres = fetchedGenres;
      final validIds = {for (final genre in genres) genre.id};
      final restored = savedIds.where(validIds.contains).toList();
      selectedGenreIds = restored.isEmpty ? null : restored;
    } on ParallelWaitError<dynamic, dynamic> catch (error) {
      if (isDisposed) return;
      debugPrint('장르 로드 실패: ${error.errors}');
      phase = LoadPhase.error;
      genreError = '장르를 불러오지 못했어요. 다시 시도해 주세요.';
      notifyIfAlive();
      return;
    }
    await loadInitial(genreIds: selectedGenreIds);
  }

  /// 장르를 바꾸면 이전 목록을 비우고 page 1부터 다시 조회합니다.
  Future<void> selectGenres(List<int>? genreIds) async {
    if (!canChangeGenre) return;
    // 장르 목록을 못 받은 상태라면 장르 필터가 동작하지 않으므로 처음부터 다시 불러옵니다.
    if (genres.isEmpty) return start();

    selectedGenreIds = (genreIds == null || genreIds.isEmpty)
        ? null
        : genres.map((genre) => genre.id).where(genreIds.contains).toList();
    final loading = loadInitial(genreIds: selectedGenreIds);
    try {
      await _genrePreference.save(selectedGenreIds ?? const []);
    } catch (error) {
      // 장르 저장은 편의 기능이라 실패해도 목록 조회는 계속합니다.
      debugPrint('장르 설정 저장 실패: $error');
    }
    await loading;
  }

  /// Error 화면 재시도와 당겨서 새로고침. 장르 목록이 없으면 처음부터 다시 불러옵니다.
  Future<void> refresh() {
    if (genres.isEmpty) return start();
    return loadInitial(genreIds: selectedGenreIds);
  }
}
