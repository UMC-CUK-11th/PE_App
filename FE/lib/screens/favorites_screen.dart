import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/movie_list_tile.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({required this.viewModel, super.key});

  final FavoritesViewModel viewModel;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.load());
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  Future<void> _openMovie(int movieId, Object? movie) async {
    await context.push('/movies/$movieId', extra: movie);
    if (mounted) await widget.viewModel.load();
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
            '내 즐겨찾기',
            style: TextStyle(
              color: AppColors.violet,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final viewModel = widget.viewModel;
    switch (viewModel.state) {
      case ViewLoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewLoadState.empty:
        return _MessageState(
          icon: Icons.bookmark_border,
          title: '즐겨찾기한 영화가 없어요',
          description: '영화 상세에서 마음에 드는 영화를 저장해 보세요.',
          actionLabel: '영화 둘러보기',
          onAction: () => context.go('/movies'),
        );
      case ViewLoadState.error:
        return _MessageState(
          icon: Icons.refresh,
          title: '즐겨찾기를 불러오지 못했어요',
          description: '네트워크 상태를 확인하고 다시 시도해 주세요.',
          actionLabel: '다시 시도',
          onAction: viewModel.load,
        );
      case ViewLoadState.success:
        return RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: viewModel.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = viewModel.items[index];
              final movie = item.movie;
              if (movie == null) {
                return Container(
                  height: 112,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.softViolet),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.broken_image_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text('영화 ${item.movieId} 정보를 불러오지 못했어요.'),
                      ),
                    ],
                  ),
                );
              }
              return MovieListTile(
                movie: movie,
                label: '즐겨찾기한 영화',
                onTap: () => _openMovie(item.movieId, movie),
              );
            },
          ),
        );
    }
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.violet),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
