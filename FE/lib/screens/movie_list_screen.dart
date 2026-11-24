import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_movies.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/fake_movie_service.dart';
import '../data/services/legacy_movie_catalog_adapter.dart';
import '../data/services/movie_catalog_service.dart';
import '../data/services/movie_list_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/movie_list_tile.dart';
import '../widgets/movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    this.selectedGenres = const {},
    this.selectedGenreIds,
    this.catalogService,
    this.movieService = const FakeMovieService(),
    this.preferences = const SharedPreferencesMovieListPreferences(),
    this.timeout = const Duration(seconds: 10),
    super.key,
  });

  final Set<String> selectedGenres;
  final List<int>? selectedGenreIds;
  final MovieCatalogService? catalogService;
  final MovieService movieService;
  final MovieListPreferences preferences;
  final Duration timeout;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final MovieListViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();
  MovieSortOption _sortOption = MovieSortOption.latest;
  int _handledErrorVersion = 0;

  @override
  void initState() {
    super.initState();
    final initialIds = widget.selectedGenreIds ?? _legacyGenreIds();
    final baseService =
        widget.catalogService ?? LegacyMovieCatalogAdapter(widget.movieService);
    _viewModel = MovieListViewModel(
      _TimeoutMovieCatalogService(baseService, widget.timeout),
      initialGenreIds: initialIds,
    )..addListener(_onViewModelChanged);
    _scrollController.addListener(_loadMoreAtEnd);
    unawaited(_initialize());
  }

  void _loadMoreAtEnd() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 180) {
      unawaited(_viewModel.loadMore());
    }
  }

  List<int>? _legacyGenreIds() {
    if (widget.selectedGenres.isEmpty) return null;
    return widget.selectedGenres
        .map((name) => movieGenres.indexOf(name) + 1)
        .where((id) => id > 0)
        .toList(growable: false);
  }

  Future<void> _initialize() async {
    MovieListPreferencesData saved;
    try {
      saved = await widget.preferences.read();
    } on Object {
      saved = const MovieListPreferencesData(
        genres: {},
        sortOption: MovieSortOption.latest,
      );
    }
    if (!mounted) return;
    setState(() => _sortOption = saved.sortOption);

    final hasRouteSelection =
        widget.selectedGenreIds != null || widget.selectedGenres.isNotEmpty;
    await _viewModel.loadInitial(
      preferredGenreNames: hasRouteSelection ? const {} : saved.genres,
    );
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = _normalizedIds(oldWidget.selectedGenreIds);
    final newIds = _normalizedIds(widget.selectedGenreIds);
    if (listEquals(oldIds, newIds) ||
        listEquals(newIds, _normalizedIds(_viewModel.selectedGenreIds))) {
      return;
    }
    unawaited(_viewModel.applyGenres(newIds));
  }

  List<int> _normalizedIds(List<int>? ids) {
    return (ids ?? const <int>[]).toSet().toList(growable: false)..sort();
  }

  void _onViewModelChanged() {
    if (!mounted ||
        _viewModel.errorVersion == _handledErrorVersion ||
        !_viewModel.hasMovies) {
      return;
    }
    _handledErrorVersion = _viewModel.errorVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showRetryDialog());
  }

  Future<void> _showRetryDialog() async {
    if (!mounted) return;
    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.32),
      builder: (context) => const _DiscoverRetryDialog(),
    );
    if (shouldRetry == true && mounted) await _viewModel.retry();
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openGenreFilter() async {
    if (_viewModel.isGenreSelectionLocked) return;
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GenreFilterSheet(
        genres: _viewModel.genres,
        selectedGenreIds: _viewModel.selectedGenreIds ?? const [],
      ),
    );
    if (result == null || !mounted) return;
    final succeeded = await _viewModel.applyGenres(result);
    if (!mounted || !succeeded) return;
    final appliedIds = _normalizedIds(_viewModel.selectedGenreIds);
    if (!listEquals(_normalizedIds(result), appliedIds)) return;
    final namesById = {
      for (final genre in _viewModel.genres) genre.id: genre.name,
    };
    _updateRoute(appliedIds);
    try {
      await widget.preferences.saveGenres(
        appliedIds.map((id) => namesById[id]).whereType<String>().toSet(),
      );
    } on Object catch (error) {
      debugPrint('장르 설정을 저장하지 못했습니다: $error');
    }
  }

  void _updateRoute(List<int> genreIds) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final namesById = {
      for (final genre in _viewModel.genres) genre.id: genre.name,
    };
    final uri = Uri(
      path: '/movies',
      queryParameters: genreIds.isEmpty
          ? null
          : {
              'genreId': genreIds.map((id) => '$id').toList(),
              'genre': genreIds
                  .map((id) => namesById[id])
                  .whereType<String>()
                  .toList(),
            },
    );
    router.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: AppColors.warmWhite,
            appBar: AppBar(
              toolbarHeight: 64,
              centerTitle: true,
              title: const Text('영화', style: AppTextStyles.signUpAppBarTitle),
            ),
            body: Column(
              children: [
                _Week09Tabs(
                  selectedGenreIds: viewModel.selectedGenreIds,
                  genres: viewModel.genres,
                  enabled: !viewModel.isGenreSelectionLocked,
                  onAll: () => _applyQuickGenres(const []),
                  onGenre: (id) => _applyQuickGenres([id]),
                  onFilter: _openGenreFilter,
                  onSearch: () => context.push('/movies/search'),
                ),
                Expanded(child: _buildContent(viewModel)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(MovieListViewModel viewModel) {
    if (viewModel.state == ViewLoadState.loading && !viewModel.hasMovies) {
      return const MovieListLoading();
    }
    if (viewModel.state == ViewLoadState.error && !viewModel.hasMovies) {
      return MovieListError(onRetry: viewModel.retry);
    }
    if (viewModel.state == ViewLoadState.empty) {
      return RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: const MovieListEmpty(),
      );
    }

    final movies = List.of(viewModel.movies);
    switch (_sortOption) {
      case MovieSortOption.latest:
        movies.sort((a, b) => b.year.compareTo(a.year));
      case MovieSortOption.rating:
        movies.sort((a, b) => b.rating.compareTo(a.rating));
      case MovieSortOption.title:
        movies.sort((a, b) => a.title.compareTo(b.title));
    }
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView.separated(
        key: const PageStorageKey('movie-grid'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: movies.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index < movies.length) {
            final movie = movies[index];
            return MovieListTile(
              key: ValueKey('movie-card-${movie.id}'),
              movie: movie,
              onTap: () => context.push('/movies/${movie.id}', extra: movie),
            );
          }
          if (viewModel.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (viewModel.loadMoreError != null) {
            return TextButton(
              key: const ValueKey('load-more-retry'),
              onPressed: viewModel.loadMore,
              child: const Text('다음 페이지를 불러오지 못했어요 · 다시 시도'),
            );
          }
          if (!viewModel.hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('마지막 영화입니다.')),
            );
          }
          return SizedBox(
            height: 44,
            child: FilledButton(
              key: const ValueKey('movie-load-more-button'),
              onPressed: viewModel.loadMore,
              child: const Text('더 보기'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _applyQuickGenres(List<int> ids) async {
    final succeeded = await _viewModel.applyGenres(ids);
    if (!mounted || !succeeded) return;
    _updateRoute(_normalizedIds(_viewModel.selectedGenreIds));
  }
}

class _Week09Tabs extends StatelessWidget {
  const _Week09Tabs({
    required this.selectedGenreIds,
    required this.genres,
    required this.enabled,
    required this.onAll,
    required this.onGenre,
    required this.onFilter,
    required this.onSearch,
  });

  final List<int>? selectedGenreIds;
  final List<TmdbGenreDto> genres;
  final bool enabled;
  final VoidCallback onAll;
  final ValueChanged<int> onGenre;
  final VoidCallback onFilter;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    int? idFor(String name) {
      for (final genre in genres) {
        if (genre.name == name) return genre.id;
      }
      return null;
    }

    final selected = selectedGenreIds ?? const [];
    final drama = idFor('드라마');
    final romance = idFor('로맨스');
    return SizedBox(
      key: const ValueKey('genre-filter-bar'),
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        children: [
          _TabButton(
            label: '전체',
            selected: selected.isEmpty,
            onTap: enabled ? onAll : null,
          ),
          if (drama != null)
            _TabButton(
              label: '드라마',
              selected: selected.length == 1 && selected.contains(drama),
              onTap: enabled ? () => onGenre(drama) : null,
            ),
          if (romance != null)
            _TabButton(
              label: '로맨스',
              selected: selected.length == 1 && selected.contains(romance),
              onTap: enabled ? () => onGenre(romance) : null,
            ),
          _TabButton(
            key: const ValueKey('genre-filter-button'),
            label: '장르',
            selected: selected.length > 1,
            onTap: enabled ? onFilter : null,
          ),
          _TabButton(label: '검색', selected: false, onTap: onSearch),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? AppColors.white : AppColors.violet,
          backgroundColor: selected ? AppColors.violet : Colors.transparent,
          side: const BorderSide(color: AppColors.softViolet),
          shape: const StadiumBorder(),
        ),
        child: Text(label),
      ),
    );
  }
}

class _DiscoverRetryDialog extends StatelessWidget {
  const _DiscoverRetryDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('discover-retry-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.softViolet,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restore_rounded,
                size: 34,
                color: AppColors.violet,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '영화를 불러오지 못했어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF25232A),
                fontSize: 20,
                height: 24 / 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '네트워크 상태를 확인하고\n다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF655F6C),
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.violet,
                        backgroundColor: const Color(0xFFF7F2FA),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        foregroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreFilterSheet extends StatefulWidget {
  const _GenreFilterSheet({
    required this.genres,
    required this.selectedGenreIds,
  });

  final List<TmdbGenreDto> genres;
  final List<int> selectedGenreIds;

  @override
  State<_GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<_GenreFilterSheet> {
  static const _initialSize = 0.6;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final Set<int> _draftIds = widget.selectedGenreIds.toSet();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _initialSize,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Material(
        color: AppColors.warmWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              key: const ValueKey('genre-filter-drag-area'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                if (!_sheetController.isAttached) return;
                final height = MediaQuery.sizeOf(context).height;
                final next =
                    (_sheetController.size -
                            (details.primaryDelta ?? 0) / height)
                        .clamp(0.35, 0.9);
                _sheetController.jumpTo(next);
              },
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '장르 필터',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.genres.length,
                itemBuilder: (context, index) {
                  final genre = widget.genres[index];
                  return CheckboxListTile(
                    key: ValueKey('genre-checkbox-${genre.name}'),
                    value: _draftIds.contains(genre.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: Text(genre.name),
                    onChanged: (checked) {
                      setState(() {
                        checked == true
                            ? _draftIds.add(genre.id)
                            : _draftIds.remove(genre.id);
                      });
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const ValueKey('apply-genre-filter'),
                    onPressed: () => Navigator.pop(
                      context,
                      _draftIds.toList(growable: false)..sort(),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeoutMovieCatalogService implements PagedMovieCatalogService {
  const _TimeoutMovieCatalogService(this._delegate, this._timeout);

  final MovieCatalogService _delegate;
  final Duration _timeout;

  @override
  Future<List<TmdbGenreDto>> fetchGenres() =>
      _delegate.fetchGenres().timeout(_timeout);

  @override
  Future<List<TmdbMovieDto>> fetchPopular() =>
      _delegate.fetchPopular().timeout(_timeout);

  @override
  Future<List<TmdbMovieDto>> fetchDiscover({List<int>? genreIds}) =>
      _delegate.fetchDiscover(genreIds: genreIds).timeout(_timeout);

  PagedMovieCatalogService get _paged {
    final delegate = _delegate;
    if (delegate is PagedMovieCatalogService) return delegate;
    throw UnsupportedError('이 영화 서비스는 페이지 조회를 지원하지 않습니다.');
  }

  @override
  Future<TmdbMoviePageDto> fetchDiscoverPage({
    required int page,
    List<int>? genreIds,
  }) async {
    if (_delegate is! PagedMovieCatalogService) {
      final results = await fetchDiscover(genreIds: genreIds);
      return TmdbMoviePageDto(page: 1, totalPages: 1, results: results);
    }
    return _paged
        .fetchDiscoverPage(page: page, genreIds: genreIds)
        .timeout(_timeout);
  }

  @override
  Future<TmdbMovieDto> fetchMovieById(int id) =>
      _paged.fetchMovieById(id).timeout(_timeout);

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required String query,
    required int page,
  }) => _paged.searchMovies(query: query, page: page).timeout(_timeout);
}
