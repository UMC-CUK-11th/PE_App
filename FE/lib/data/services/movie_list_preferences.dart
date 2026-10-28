import 'package:shared_preferences/shared_preferences.dart';

enum MovieSortOption {
  latest('최신순'),
  rating('평점순'),
  title('제목순');

  const MovieSortOption(this.label);

  final String label;

  static MovieSortOption fromName(String? name) {
    return values.where((option) => option.name == name).firstOrNull ?? latest;
  }
}

class MovieListPreferencesData {
  const MovieListPreferencesData({
    required this.genres,
    required this.sortOption,
  });

  final Set<String> genres;
  final MovieSortOption sortOption;
}

abstract interface class MovieListPreferences {
  Future<MovieListPreferencesData> read();

  Future<void> saveGenres(Set<String> genres);

  Future<void> saveSortOption(MovieSortOption sortOption);
}

class SharedPreferencesMovieListPreferences implements MovieListPreferences {
  const SharedPreferencesMovieListPreferences();

  static const selectedGenresKey = 'movie_list_selected_genres';
  static const sortOptionKey = 'movie_list_sort_option';

  @override
  Future<MovieListPreferencesData> read() async {
    final preferences = SharedPreferencesAsync();
    return MovieListPreferencesData(
      genres: (await preferences.getStringList(selectedGenresKey) ?? const [])
          .toSet(),
      sortOption: MovieSortOption.fromName(
        await preferences.getString(sortOptionKey),
      ),
    );
  }

  @override
  Future<void> saveGenres(Set<String> genres) {
    return SharedPreferencesAsync().setStringList(
      selectedGenresKey,
      genres.toList(),
    );
  }

  @override
  Future<void> saveSortOption(MovieSortOption sortOption) {
    return SharedPreferencesAsync().setString(sortOptionKey, sortOption.name);
  }
}
