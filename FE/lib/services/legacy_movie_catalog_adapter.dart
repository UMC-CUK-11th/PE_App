import '../data/mock_movies.dart';
import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_dto.dart';
import '../models/movie.dart';
import 'fake_movie_service.dart';
import 'movie_catalog_service.dart';

class LegacyMovieCatalogAdapter implements MovieCatalogService {
  const LegacyMovieCatalogAdapter(this.service);

  final MovieService service;

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    return [
      for (var index = 0; index < movieGenres.length; index++)
        TmdbGenreDto(id: index + 1, name: movieGenres[index]),
    ];
  }

  @override
  Future<List<TmdbMovieDto>> fetchPopular() async {
    final movies = await service.fetchMovies();
    return movies.map(_toDto).toList(growable: false);
  }

  @override
  Future<List<TmdbMovieDto>> fetchDiscover({List<int>? genreIds}) async {
    final movies = await service.fetchMovies();
    if (genreIds == null || genreIds.isEmpty) {
      return movies.map(_toDto).toList(growable: false);
    }
    final selectedNames = genreIds
        .where((id) => id > 0 && id <= movieGenres.length)
        .map((id) => movieGenres[id - 1])
        .toSet();
    return movies
        .where((movie) => movie.genres.any(selectedNames.contains))
        .map(_toDto)
        .toList(growable: false);
  }

  TmdbMovieDto _toDto(Movie movie) {
    return TmdbMovieDto(
      id: movie.id,
      title: movie.title,
      genreIds: movie.genres
          .map((genre) => movieGenres.indexOf(genre) + 1)
          .where((id) => id > 0)
          .toList(growable: false),
      voteAverage: movie.rating * 2,
      overview: movie.synopsis,
      releaseDate: '${movie.year}-01-01',
    );
  }
}
