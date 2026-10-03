import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/genre_filter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movie_cards.dart';
import 'genre_filter_sheet.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key, required this.selectedGenres});

  final Set<String> selectedGenres;

  Future<void> _openFilter(BuildContext context) async {
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
              initialSelection: selectedGenres,
              scrollController: scrollController,
            );
          },
        );
      },
    );

    if (result == null || !context.mounted) return;
    context.go(moviesLocation(result));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterMoviesByGenres(selectedGenres);
    final summary = selectedGenres.isEmpty
        ? '전체 장르'
        : '장르: ${selectedGenres.join(', ')}';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(summary, style: AppTextStyles.bodySmall),
                ),
                IconButton(
                  tooltip: '장르 필터',
                  onPressed: () => _openFilter(context),
                  icon: const Icon(Icons.filter_list, color: AppColors.violet),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      '선택한 장르의 영화가 없어요',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                  ),
          ),
        ],
      ),
    );
  }
}
