import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/genre_filter.dart';
import '../../data/genre_preference.dart';
import '../../data/movie.dart';
import '../../data/movie_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movie_cards.dart';
import 'genre_chip_bar.dart';
import 'genre_filter_sheet.dart';
import 'movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    required this.selectedGenres,
    required this.movieService,
    required this.genrePreference,
  });

  final Set<String> selectedGenres;
  final FakeMovieService movieService;
  final GenrePreference genrePreference;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late Future<List<Movie>> _moviesFuture;

  MovieLoadMode _mode = MovieLoadMode.success;
  bool _genresRestored = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    // build가 아니라 initState에서 한 번만 Future를 만듭니다.
    _moviesFuture = _startLoad();
  }

  // FutureBuilder가 구독하기 전에 오류로 끝나도 처리되지 않은 예외로 번지지 않게 합니다.
  // ignore()는 빈 리스너만 붙이므로 FutureBuilder는 그대로 오류를 전달받습니다.
  Future<List<Movie>> _startLoad() => _loadMovies()..ignore();

  Future<List<Movie>> _loadMovies() async {
    // 실패 모드는 한 번만 실패시키고 다음 시도는 성공하게 해 재시도 흐름을 확인합니다.
    final mode = _mode;
    if (mode == MovieLoadMode.failure) _mode = MovieLoadMode.success;

    try {
      if (_genresRestored) {
        return await widget.movieService.fetchMovies(mode: mode);
      }

      // 영화 목록과 저장된 장르는 서로 의존하지 않으므로 함께 시작합니다.
      final results = await Future.wait<Object>([
        widget.movieService.fetchMovies(mode: mode),
        widget.genrePreference.read(),
      ]);
      _genresRestored = true;

      final loaded = results[0] as List<Movie>;
      final savedGenres = results[1] as Set<String>;

      // await 사이에 화면이 사라졌다면 context를 사용하지 않습니다.
      if (!mounted) return loaded;
      if (widget.selectedGenres.isEmpty && savedGenres.isNotEmpty) {
        context.go(moviesLocation(savedGenres));
      }
      return loaded;
    } on MovieLoadException catch (error, stackTrace) {
      debugPrint('영화 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      debugPrint('영화 로드 시도 종료 (mode: ${mode.name})');
    }
  }

  // 재시도·상태 변경처럼 작업을 다시 시작할 때만 새 Future를 만듭니다.
  void _reload() {
    setState(() {
      _moviesFuture = _startLoad();
    });
  }

  void _changeMode(MovieLoadMode mode) {
    _mode = mode;
    _reload();
  }

  Future<void> _refresh() async {
    final future = _startLoad();
    setState(() {
      _refreshing = true;
      _moviesFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // 오류 화면은 FutureBuilder가 그립니다.
    }

    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  Future<void> _applyGenres(Set<String> genres) async {
    context.go(moviesLocation(genres));
    await widget.genrePreference.save(genres);
  }

  Future<void> _openFilter() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return GenreFilterSheet(
              initialSelection: widget.selectedGenres,
              scrollController: scrollController,
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    await _applyGenres(result);
  }

  Widget _buildBody(AsyncSnapshot<List<Movie>> snapshot) {
    final waiting = snapshot.connectionState == ConnectionState.waiting;
    // 당겨서 새로고침 중에는 이전 목록을 유지하고 그 외 대기 상태는 Loading을 보여 줍니다.
    if (waiting && !(_refreshing && snapshot.hasData)) {
      return const MovieListLoading();
    }

    if (snapshot.hasError && !waiting) {
      return MovieListError(onRetry: _reload);
    }

    final loaded = snapshot.data ?? const <Movie>[];
    if (loaded.isEmpty) {
      return const MovieListEmpty(message: '불러올 영화가 없어요');
    }

    final genres = widget.selectedGenres;
    final filtered = genres.isEmpty
        ? loaded
        : loaded.where((movie) => genres.contains(movie.genre)).toList();

    if (filtered.isEmpty) {
      return MovieListEmpty(
        message: '선택한 장르의 영화가 없어요',
        actionLabel: '전체 장르 보기',
        onAction: () => _applyGenres(<String>{}),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.55,
      ),
      itemBuilder: (context, index) {
        final movie = filtered[index];
        return MovieGridCard(
          movie: movie,
          onTap: () => context.push('/movies/${movie.id}'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGenres = widget.selectedGenres;
    final summary = selectedGenres.isEmpty
        ? '전체 장르'
        : '장르: ${allGenres.where(selectedGenres.contains).join(', ')}';

    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          IconButton(
            tooltip: '검색',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<MovieLoadMode>(
            tooltip: '불러오기 상태',
            icon: const Icon(Icons.tune),
            initialValue: _mode,
            onSelected: _changeMode,
            itemBuilder: (context) => const [
              PopupMenuItem(value: MovieLoadMode.success, child: Text('성공')),
              PopupMenuItem(value: MovieLoadMode.empty, child: Text('빈 목록')),
              PopupMenuItem(value: MovieLoadMode.failure, child: Text('실패')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(summary, style: AppTextStyles.bodySmall),
                ),
                IconButton(
                  tooltip: '장르 필터',
                  onPressed: _openFilter,
                  icon: const Icon(Icons.filter_list, color: AppColors.violet),
                ),
              ],
            ),
          ),
          GenreChipBar(
            selectedGenres: selectedGenres,
            onChanged: _applyGenres,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.violet,
              onRefresh: _refresh,
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) => _buildBody(snapshot),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
