import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/tmdb_movie_dto.dart';
import '../services/movie_list_preferences.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  MovieListViewModel? _viewModel;
  int _seenFailure = 0;
  bool _dialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<MovieListViewModel>();
    if (identical(next, _viewModel)) return;
    _viewModel?.removeListener(_onChanged);
    _viewModel = next;
    _viewModel!.addListener(_onChanged);
    _onChanged();
  }

  void _onChanged() {
    final vm = _viewModel!;
    if (vm.failureRevision <= _seenFailure || _dialogOpen) return;
    _seenFailure = vm.failureRevision;
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('영화 요청 실패'),
          content: Text(vm.errorMessage ?? '네트워크 연결을 확인해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('재시도'),
            ),
          ],
        ),
      );
      _dialogOpen = false;
      if (retry == true && mounted) await vm.load();
    });
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _openGenreFilter() async {
    final vm = context.read<MovieListViewModel>();
    if (vm.isLoading) return;
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GenreFilterSheet(
        genres: vm.genres,
        selectedGenres: vm.selectedGenreIds?.toSet() ?? {},
      ),
    );
    if (result == null || !mounted || vm.isLoading) return;
    final uri = Uri(
      path: '/movies',
      queryParameters: result.isEmpty
          ? null
          : {'genre': result.map((id) => '$id').toList()},
    );
    context.go(uri.toString());
    await vm.selectGenres(result.toList());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MovieListViewModel>();
    final movies = vm.visibleMovies;
    Widget content;
    if (vm.isLoading && movies.isEmpty) {
      content = const MovieListLoading();
    } else if (vm.status == MovieLoadStatus.error && movies.isEmpty) {
      content = MovieListError(
        onRetry: () => context.read<MovieListViewModel>().load(),
      );
    } else {
      content = movies.isEmpty
          ? const MovieListEmpty()
          : MovieGrid(movies: movies);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화'),
        titleSpacing: 16,
        toolbarHeight: 64,
      ),
      body: Column(
        children: [
          _MovieListToolbar(
            selectedCount: vm.selectedGenreIds?.length ?? 0,
            sortOption: vm.sortOption,
            onSortSelected: (option) =>
                context.read<MovieListViewModel>().setSortOption(option),
            onFilterPressed: vm.isLoading || vm.genres.isEmpty
                ? null
                : _openGenreFilter,
          ),
          if (vm.genres.isNotEmpty)
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('전체'),
                      selected:
                          vm.selectedGenreIds == null ||
                          vm.selectedGenreIds!.isEmpty,
                      onSelected: vm.isLoading
                          ? null
                          : (_) => _selectChip(null),
                    ),
                  ),
                  ...vm.genres.map(
                    (genre) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(genre.name),
                        selected:
                            vm.selectedGenreIds?.contains(genre.id) ?? false,
                        onSelected: vm.isLoading
                            ? null
                            : (selected) =>
                                  _selectChip(selected ? [genre.id] : null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (vm.isLoading && movies.isNotEmpty)
            const LinearProgressIndicator(),
          if (vm.status == MovieLoadStatus.error && movies.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('최근에 불러온 목록을 표시하고 있어요.'),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<MovieListViewModel>().load(),
              notificationPredicate: (notification) =>
                  !vm.isLoading && notification.depth == 0,
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  void _selectChip(List<int>? ids) {
    final uri = Uri(
      path: '/movies',
      queryParameters: ids == null
          ? null
          : {'genre': ids.map((id) => '$id').toList()},
    );
    context.go(uri.toString());
    context.read<MovieListViewModel>().selectGenres(ids);
  }
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
  final VoidCallback? onFilterPressed;

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

  final List<TmdbGenreDto> genres;
  final Set<int> selectedGenres;

  @override
  State<_GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<_GenreFilterSheet> {
  static const _initialSize = 0.48;
  static const _minSize = 0.35;
  static const _maxSize = 0.9;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final Set<int> _draftGenres = {...widget.selectedGenres};

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
                    key: ValueKey('genre-checkbox-${genre.id}'),
                    value: _draftGenres.contains(genre.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: Text(
                      genre.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onChanged: (checked) {
                      setState(() {
                        checked == true
                            ? _draftGenres.add(genre.id)
                            : _draftGenres.remove(genre.id);
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
