import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_dto.dart';

abstract interface class MovieCatalogService {
  Future<List<TmdbMovieDto>> fetchPopular();

  Future<List<TmdbGenreDto>> fetchGenres();

  Future<List<TmdbMovieDto>> fetchDiscover({List<int>? genreIds});
}

abstract interface class PagedMovieCatalogService
    implements MovieCatalogService {
  Future<TmdbMoviePageDto> fetchDiscoverPage({
    required int page,
    List<int>? genreIds,
  });

  Future<TmdbMoviePageDto> searchMovies({
    required String query,
    required int page,
  });

  Future<TmdbMovieDto> fetchMovieById(int id);
}
