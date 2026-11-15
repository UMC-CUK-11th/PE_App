import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/movie_list_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movie_cards.dart';
import 'genre_chip_bar.dart';
import 'genre_filter_sheet.dart';
import 'movie_list_states.dart';

/// 상태와 요청은 MovieListViewModel이 가지고, 화면은 그리기와 입력 전달만 합니다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _refresh() async {
    final viewModel = context.read<MovieListViewModel>();
    final succeeded = await viewModel.refresh();
    // 최근 성공 목록이 있을 때만 목록을 유지한 채 재시도 Dialog를 띄웁니다.
    if (succeeded || !mounted || viewModel.movies.isEmpty) return;

    final retry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('영화를 불러오지 못했어요'),
        content: const Text('네트워크 상태를 확인한 뒤 다시 시도해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('재시도'),
          ),
        ],
      ),
    );

    // 같은 장르 조건으로 page 1부터 다시 요청합니다.
    if (retry == true && mounted) await _refreshKey.currentState?.show();
  }

  Future<void> _openFilter(MovieListViewModel viewModel) async {
    final result = await showModalBottomSheet<List<int>>(
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
              genres: viewModel.genres,
              initialSelection: viewModel.selectedGenreIds ?? const [],
              scrollController: scrollController,
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    await viewModel.selectGenres(result);
  }

  void _openDetail(TmdbMovieDto movie) {
    // TMDB id를 경로로 넘깁니다. 이후 평점 저장의 movieId가 됩니다.
    context.push('/movies/${movie.id}', extra: movie);
  }

  Widget _buildBody(MovieListViewModel viewModel) {
    switch (viewModel.status) {
      case MovieListLoadStatus.idle:
      case MovieListLoadStatus.loading:
        return const MovieListLoading();
      case MovieListLoadStatus.error:
        return MovieListError(
          message: viewModel.message,
          onRetry: viewModel.retry,
        );
      case MovieListLoadStatus.empty:
        return viewModel.selectedGenreIds == null
            ? const MovieListEmpty(message: '불러올 영화가 없어요')
            : MovieListEmpty(
                message: '선택한 장르의 영화가 없어요',
                actionLabel: '전체 장르 보기',
                onAction: () => viewModel.selectGenres(null),
              );
      case MovieListLoadStatus.success:
        final movies = viewModel.movies;
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: movies.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.55,
          ),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return MovieGridCard(
              movie: movie,
              subtitle: [
                ?movie.year,
                viewModel.genreNamesOf(movie),
              ].where((text) => text.isNotEmpty).join(' · '),
              onTap: () => _openDetail(movie),
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          IconButton(
            tooltip: '검색',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) {
              final selected = viewModel.selectedGenreIds ?? const <int>[];
              final canChange = viewModel.canChangeGenre;
              final summary = selected.isEmpty
                  ? '전체 장르 · ${viewModel.movies.length}편'
                  : '장르: ${viewModel.genres.where((genre) => selected.contains(genre.id)).map((genre) => genre.name).join(', ')} · ${viewModel.movies.length}편';

              return Column(
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
                          onPressed: canChange && viewModel.genres.isNotEmpty
                              ? () => _openFilter(viewModel)
                              : null,
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppColors.violet,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GenreChipBar(
                    genres: viewModel.genres,
                    selectedIds: selected,
                    onChanged: canChange ? viewModel.selectGenres : null,
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) {
                return RefreshIndicator(
                  key: _refreshKey,
                  color: AppColors.violet,
                  // Loading 중에는 당겨서 새로고침이 동작하지 않습니다.
                  notificationPredicate: (notification) =>
                      !viewModel.isLoading &&
                      defaultScrollNotificationPredicate(notification),
                  onRefresh: _refresh,
                  child: _buildBody(viewModel),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
