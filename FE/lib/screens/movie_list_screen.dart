import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../widgets/movie_grid.dart';
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
    unawaited(_initialize());
  }

  List<int>? _legacyGenreIds() {
    if (widget.selectedGenres.isEmpty) return null;
    return widget.selectedGenres
        .map((name) => movieGenres.indexOf(name) + 1)
        .where((id) => id > 0)
        .toList(growable: false);
  }

  Future<void> _initialize() async {
    final savedFuture = widget.preferences.read();
    await _viewModel.loadInitial();
    final saved = await savedFuture;
    if (!mounted) return;
    setState(() => _sortOption = saved.sortOption);

    final hasRouteSelection =
        widget.selectedGenreIds != null || widget.selectedGenres.isNotEmpty;
    if (hasRouteSelection || saved.genres.isEmpty) return;
    final savedIds = _viewModel.genres
        .where((genre) => saved.genres.contains(genre.name))
        .map((genre) => genre.id)
        .toList(growable: false);
    if (savedIds.isNotEmpty) await _viewModel.applyGenres(savedIds);
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
    final namesById = {
      for (final genre in _viewModel.genres) genre.id: genre.name,
    };
    await widget.preferences.saveGenres(
      result.map((id) => namesById[id]).whereType<String>().toSet(),
    );
    if (mounted) _updateRoute(result);
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
            appBar: AppBar(
              toolbarHeight: 64,
              titleSpacing: 16,
              title: Transform.translate(
                offset: const Offset(0, 2),
                child: const Text('영화', style: AppTextStyles.signUpAppBarTitle),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    tooltip: '영화 검색',
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      'assets/icons/search.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        AppColors.violet,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                _MovieListToolbar(
                  selectedCount: viewModel.selectedGenreIds?.length ?? 0,
                  sortOption: _sortOption,
                  isEnabled: !viewModel.isGenreSelectionLocked,
                  onSortSelected: _selectSortOption,
                  onFilterPressed: _openGenreFilter,
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
      child: MovieGrid(movies: movies),
    );
  }

  Future<void> _selectSortOption(MovieSortOption option) async {
    setState(() => _sortOption = option);
    await widget.preferences.saveSortOption(option);
  }
}

class _MovieListToolbar extends StatelessWidget {
  const _MovieListToolbar({
    required this.selectedCount,
    required this.sortOption,
    required this.isEnabled,
    required this.onSortSelected,
    required this.onFilterPressed,
  });

  final int selectedCount;
  final MovieSortOption sortOption;
  final bool isEnabled;
  final ValueChanged<MovieSortOption> onSortSelected;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('genre-filter-bar'),
      height: 48,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<MovieSortOption>(
              key: const ValueKey('movie-sort-button'),
              enabled: isEnabled,
              initialValue: sortOption,
              tooltip: '영화 정렬',
              icon: const Icon(
                Icons.sort_rounded,
                size: 22,
                color: AppColors.violet,
              ),
              onSelected: onSortSelected,
              itemBuilder: (context) => MovieSortOption.values
                  .map(
                    (option) =>
                        PopupMenuItem(value: option, child: Text(option.label)),
                  )
                  .toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Badge(
                isLabelVisible: selectedCount > 0,
                label: Text('$selectedCount'),
                alignment: Alignment.topRight,
                offset: const Offset(-3, 4),
                child: IconButton(
                  key: const ValueKey('genre-filter-button'),
                  tooltip: '장르 필터',
                  onPressed: isEnabled ? onFilterPressed : null,
                  icon: const Icon(
                    Icons.filter_alt_outlined,
                    size: 22,
                    color: AppColors.violet,
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

class _TimeoutMovieCatalogService implements MovieCatalogService {
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
}
