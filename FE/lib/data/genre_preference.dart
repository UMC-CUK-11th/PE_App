import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'movie.dart';

/// 마지막으로 선택한 장르를 저장·복원합니다.
/// 장르처럼 단순하고 민감하지 않은 설정값만 다룹니다.
abstract interface class GenrePreference {
  Future<Set<String>> read();

  Future<void> save(Set<String> genres);
}

class SharedPrefsGenrePreference implements GenrePreference {
  SharedPrefsGenrePreference({SharedPreferencesAsync? preferences})
      : _injected = preferences;

  static const selectedGenresKey = 'selected_genres';

  final SharedPreferencesAsync? _injected;

  // 실제로 읽거나 쓸 때 생성해 테스트 환경에서 Plugin 없이도 객체를 만들 수 있게 합니다.
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();

  @override
  Future<Set<String>> read() async {
    try {
      final saved = await _preferences.getStringList(selectedGenresKey);
      return (saved ?? const <String>[]).where(allGenres.contains).toSet();
    } catch (error) {
      // 설정값을 못 읽어도 영화 목록은 보여야 하므로 전체 장르로 시작합니다.
      debugPrint('장르 설정 읽기 실패: $error');
      return <String>{};
    }
  }

  @override
  Future<void> save(Set<String> genres) async {
    final ordered = allGenres.where(genres.contains).toList();
    await _preferences.setStringList(selectedGenresKey, ordered);
  }
}

/// 테스트와 미리보기용 메모리 저장소입니다.
class InMemoryGenrePreference implements GenrePreference {
  InMemoryGenrePreference([Set<String> initial = const <String>{}])
      : _genres = {...initial};

  Set<String> _genres;

  Set<String> get saved => {..._genres};

  @override
  Future<Set<String>> read() async => {..._genres};

  @override
  Future<void> save(Set<String> genres) async {
    _genres = {...genres};
  }
}
