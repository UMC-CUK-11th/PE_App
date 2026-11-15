import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 마지막으로 선택한 TMDB 장르 ID를 저장·복원합니다.
abstract interface class GenrePreference {
  Future<List<int>> read();

  Future<void> save(List<int> genreIds);
}

class SharedPrefsGenrePreference implements GenrePreference {
  SharedPrefsGenrePreference({SharedPreferencesAsync? preferences})
    : _injected = preferences;

  static const selectedGenreIdsKey = 'selected_genre_ids';

  final SharedPreferencesAsync? _injected;

  // 실제로 읽거나 쓸 때 생성해 테스트 환경에서 Plugin 없이도 객체를 만들 수 있게 합니다.
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();

  @override
  Future<List<int>> read() async {
    try {
      final saved = await _preferences.getStringList(selectedGenreIdsKey);
      return (saved ?? const <String>[]).map(int.tryParse).nonNulls.toList();
    } catch (error) {
      // 설정값을 못 읽어도 영화 목록은 보여야 하므로 전체 장르로 시작합니다.
      debugPrint('장르 설정 읽기 실패: $error');
      return const <int>[];
    }
  }

  @override
  Future<void> save(List<int> genreIds) async {
    await _preferences.setStringList(
      selectedGenreIdsKey,
      genreIds.map((id) => '$id').toList(),
    );
  }
}

/// 테스트와 미리보기용 메모리 저장소입니다.
class InMemoryGenrePreference implements GenrePreference {
  InMemoryGenrePreference([List<int> initial = const <int>[]])
    : _genreIds = [...initial];

  List<int> _genreIds;

  List<int> get saved => [..._genreIds];

  @override
  Future<List<int>> read() async => [..._genreIds];

  @override
  Future<void> save(List<int> genreIds) async {
    _genreIds = [...genreIds];
  }
}
