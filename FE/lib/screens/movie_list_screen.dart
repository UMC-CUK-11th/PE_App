import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/movie_list_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    required this.selectedGenres,
    this.movieService = const FakeMovieService(),
    this.preferences = const SharedPreferencesMovieListPreferences(),
    this.timeout = const Duration(seconds: 3),
    super.key,
  });

  final Set<String> selectedGenres;
  final MovieService movieService;
  final MovieListPreferences preferences;
  final Duration timeout;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late Future<_MovieListInitialData> _initialDataFuture;
  Set<String>? _selectedGenresOverride;
  MovieSortOption? _sortOptionOverride;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.selectedGenres, widget.selectedGenres)) {
      _selectedGenresOverride = widget.selectedGenres;
    }
  }

  Future<_MovieListInitialData> _loadInitialData() async {
    try {
      final results = await Future.wait<Object>([
        widget.movieService.fetchMovies().timeout(widget.timeout),
        widget.preferences.read(),
      ]);
      final preferences = results[1] as MovieListPreferencesData;
      return _MovieListInitialData(
        movies: results[0] as List<Movie>,
        selectedGenres: widget.selectedGenres.isEmpty
            ? preferences.genres
            : widget.selectedGenres,
        sortOption: preferences.sortOption,
      );
    } on TimeoutException {
      throw const MovieLoadException('영화 요청 시간이 초과되었습니다.');
    }
  }

  void _retry() {
    setState(() {
      _initialDataFuture = _loadInitialData();
    });
  }

  Future<void> _refresh() async {
    final nextFuture = _loadInitialData();
    setState(() {
      _initialDataFuture = nextFuture;
    });
    try {
      await nextFuture;
    } on Object {
      // FutureBuilder가 사용자용 오류 화면으로 전환합니다.
    }
  }

  Future<void> _applyGenres(Set<String> genres) async {
    setState(() {
      _selectedGenresOverride = genres;
    });

    final uri = Uri(
      path: '/movies',
      queryParameters: genres.isEmpty ? null : {'genre': genres.toList()},
    );
    context.go(uri.toString());
    await widget.preferences.saveGenres(genres);
  }

  Future<void> _openGenreFilter(Set<String> selectedGenres) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GenreFilterSheet(
        genres: movieGenres,
        selectedGenres: selectedGenres,
      ),
    );
    if (result == null || !mounted) return;
    await _applyGenres(result);
  }

  Future<void> _selectSortOption(MovieSortOption sortOption) async {
    setState(() {
      _sortOptionOverride = sortOption;
    });
    await widget.preferences.saveSortOption(sortOption);
  }

  List<Movie> _visibleMovies({
    required List<Movie> movies,
    required Set<String> selectedGenres,
    required MovieSortOption sortOption,
  }) {
    final filteredMovies = selectedGenres.isEmpty
        ? List<Movie>.of(movies)
        : movies
              .where((movie) => movie.genres.any(selectedGenres.contains))
              .toList();

    switch (sortOption) {
      case MovieSortOption.latest:
        filteredMovies.sort((a, b) {
          final yearComparison = b.year.compareTo(a.year);
          return yearComparison != 0 ? yearComparison : a.id.compareTo(b.id);
        });
      case MovieSortOption.rating:
        filteredMovies.sort((a, b) => b.rating.compareTo(a.rating));
      case MovieSortOption.title:
        filteredMovies.sort((a, b) => a.title.compareTo(b.title));
    }
    return filteredMovies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: const Text(
          '영화',
          style: TextStyle(
            color: AppColors.onPrimaryContainer,
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: '영화 검색',
              onPressed: () {},
              padding: const EdgeInsets.all(14),
              icon: SvgPicture.asset(
                'assets/icons/search.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.onSurfaceVariant,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<_MovieListInitialData>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          final selectedGenres =
              _selectedGenresOverride ??
              snapshot.data?.selectedGenres ??
              widget.selectedGenres;
          final sortOption =
              _sortOptionOverride ??
              snapshot.data?.sortOption ??
              MovieSortOption.latest;

          return Column(
            children: [
              _MovieListToolbar(
                selectedCount: selectedGenres.length,
                sortOption: sortOption,
                onSortSelected: _selectSortOption,
                onFilterPressed: () => _openGenreFilter(selectedGenres),
              ),
              Expanded(
                child: _buildMovieContent(
                  snapshot: snapshot,
                  selectedGenres: selectedGenres,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMovieContent({
    required AsyncSnapshot<_MovieListInitialData> snapshot,
    required Set<String> selectedGenres,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const MovieListLoading();
    }
    if (snapshot.hasError) {
      return MovieListError(onRetry: _retry);
    }

    final data = snapshot.data!;
    final sortOption = _sortOptionOverride ?? data.sortOption;
    final movies = _visibleMovies(
      movies: data.movies,
      selectedGenres: selectedGenres,
      sortOption: sortOption,
    );

    return RefreshIndicator(
      onRefresh: _refresh,
      child: movies.isEmpty
          ? const MovieListEmpty()
          : MovieGrid(movies: movies),
    );
  }
}

class _MovieListInitialData {
  const _MovieListInitialData({
    required this.movies,
    required this.selectedGenres,
    required this.sortOption,
  });

  final List<Movie> movies;
  final Set<String> selectedGenres;
  final MovieSortOption sortOption;
}

class _MovieListToolbar extends StatelessWidget {
  const _MovieListToolbar({
    required this.selectedCount,
    required this.sortOption,
    required this.onSortSelected,
    required this.onFilterPressed,
  });

  final int selectedCount;
  final MovieSortOption sortOption;
  final ValueChanged<MovieSortOption> onSortSelected;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('genre-filter-bar'),
      height: 48,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<MovieSortOption>(
                key: const ValueKey('movie-sort-button'),
                tooltip: '영화 정렬',
                initialValue: sortOption,
                icon: const Icon(Icons.sort, size: 22),
                onSelected: onSortSelected,
                itemBuilder: (context) => MovieSortOption.values
                    .map(
                      (option) => PopupMenuItem(
                        value: option,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
              ),
              Badge(
                isLabelVisible: selectedCount > 0,
                label: Text('$selectedCount'),
                alignment: Alignment.topRight,
                offset: const Offset(-3, 4),
                child: IconButton(
                  key: const ValueKey('genre-filter-button'),
                  tooltip: '장르 필터',
                  onPressed: onFilterPressed,
                  icon: const Icon(Icons.filter_alt_outlined, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreFilterSheet extends StatefulWidget {
  const _GenreFilterSheet({required this.genres, required this.selectedGenres});

  final List<String> genres;
  final Set<String> selectedGenres;

  @override
  State<_GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<_GenreFilterSheet> {
  static const _initialSize = 0.48;
  static const _minSize = 0.35;
  static const _maxSize = 0.9;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final Set<String> _draftGenres = {...widget.selectedGenres};

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _dragSheet(DragUpdateDetails details) {
    if (!_sheetController.isAttached) return;

    final availableHeight = MediaQuery.sizeOf(context).height;
    final nextSize =
        (_sheetController.size - (details.primaryDelta ?? 0) / availableHeight)
            .clamp(_minSize, _maxSize);
    _sheetController.jumpTo(nextSize);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _initialSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
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
              onVerticalDragUpdate: _dragSheet,
              child: const Column(
                children: [
                  SizedBox(height: 10),
                  _SheetDragHandle(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '장르 필터',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '여러 장르를 선택할 수 있어요',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.genres.length,
                itemBuilder: (context, index) {
                  final genre = widget.genres[index];
                  return CheckboxListTile(
                    key: ValueKey('genre-checkbox-$genre'),
                    value: _draftGenres.contains(genre),
                    controlAffinity: ListTileControlAffinity.leading,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: Text(genre, style: const TextStyle(fontSize: 14)),
                    onChanged: (checked) {
                      setState(() {
                        checked == true
                            ? _draftGenres.add(genre)
                            : _draftGenres.remove(genre);
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
                    onPressed: () => Navigator.pop(context, _draftGenres),
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

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.outlineVariant,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
