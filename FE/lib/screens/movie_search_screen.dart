import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_search_view_model.dart';
import '../widgets/movie_list_tile.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({required this.viewModel, super.key});

  final MovieSearchViewModel viewModel;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadAtEnd);
  }

  void _loadAtEnd() {
    if (_scrollController.position.extentAfter < 180) {
      widget.viewModel.loadMore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.warmWhite,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            '영화 검색',
            style: TextStyle(
              color: AppColors.violet,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: TextField(
                key: const ValueKey('movie-search-field'),
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: widget.viewModel.searchAsYouType,
                onSubmitted: widget.viewModel.search,
                decoration: InputDecoration(
                  hintText: '영화 제목을 입력해 주세요',
                  suffixIcon: TextButton(
                    onPressed: () => widget.viewModel.search(_controller.text),
                    child: const Text('검색'),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final viewModel = widget.viewModel;
    if (viewModel.state == ViewLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.state == ViewLoadState.error) {
      return _SearchMessage(
        title: '검색 결과를 불러오지 못했어요',
        action: () => viewModel.search(viewModel.query),
      );
    }
    if (viewModel.state == ViewLoadState.empty) {
      return _SearchMessage(
        title: viewModel.query.isEmpty ? '찾고 싶은 영화를 검색해 보세요' : '검색 결과가 없어요',
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: viewModel.movies.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == viewModel.movies.length) {
          if (viewModel.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (viewModel.loadMoreError != null) {
            return TextButton(
              onPressed: viewModel.loadMore,
              child: const Text('검색 결과를 더 불러오지 못했어요 · 다시 시도'),
            );
          }
          if (!viewModel.hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('마지막 검색 결과입니다.')),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FilledButton(
              key: const ValueKey('search-load-more-button'),
              onPressed: viewModel.loadMore,
              child: const Text('검색 결과 더 보기'),
            ),
          );
        }
        final movie = viewModel.movies[index];
        return MovieListTile(
          movie: movie,
          onTap: () => context.push('/movies/${movie.id}', extra: movie),
        );
      },
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.title, this.action});

  final String title;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 44, color: AppColors.violet),
          const SizedBox(height: 14),
          Text(title),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: action, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}
