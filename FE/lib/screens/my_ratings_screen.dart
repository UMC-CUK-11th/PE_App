import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../widgets/delete_ratings_dialog.dart';
import '../widgets/rating_dialog.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  bool _selecting = false;
  final _selected = <int>{};

  void _toggleMode() => setState(() {
    _selecting = !_selecting;
    _selected.clear();
  });

  Future<void> _edit(MyRatingsViewModel vm, RatingDto rating) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialRating: rating.score.toDouble(),
        initialComment: rating.comment,
        onSubmit: (input) => vm.update(rating.ratingId, input),
      ),
    );
    if (mounted && saved == true) _notify('평점을 수정했습니다.');
  }

  Future<void> _delete(MyRatingsViewModel vm, Set<int> ids) async {
    final failures = await showDialog<Map<int, ApiFailure>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteRatingsDialog(
        count: ids.length,
        onDelete: () => vm.deleteSelected(ids),
      ),
    );
    if (!mounted || failures == null) return;
    setState(() {
      _selected.retainAll(failures.keys);
      if (_selected.isEmpty) _selecting = false;
    });
    final succeeded = ids.length - failures.length;
    _notify(switch (failures.length) {
      0 => '평점 $succeeded개를 삭제했습니다.',
      _ when ids.length == 1 => failures.values.first.message,
      _ =>
        '$succeeded개 삭제, ${failures.length}개 실패. ${failures.values.first.message}',
    });
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    final activeSelection = _selected.intersection(
      vm.ratings.map((r) => r.ratingId).toSet(),
    );
    return PopScope(
      canPop: !vm.isWriting,
      child: Scaffold(
        appBar: CommonAppBar(
          title: '내가 등록한 평점',
          centerTitle: true,
          onBack: vm.isWriting
              ? null
              : () => context.canPop() ? context.pop() : context.go('/my'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (vm.memberId != null && (vm.ratings.isNotEmpty || _selecting))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selecting ? '${activeSelection.length}개 선택' : '내 평점',
                        ),
                      ),
                      TextButton(
                        onPressed: vm.isWriting ? null : _toggleMode,
                        child: Text(_selecting ? '취소' : '편집'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: vm.memberId == null
                    ? Center(
                        child: TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('가입을 완료한 후 내 평점을 확인해 주세요.'),
                        ),
                      )
                    : switch (vm.status) {
                        MyRatingsStatus.idle => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        MyRatingsStatus.loading when vm.ratings.isEmpty =>
                          const Center(child: CircularProgressIndicator()),
                        MyRatingsStatus.empty => _Message(
                          icon: Icons.rate_review_outlined,
                          message: '등록한 평점이 없습니다.',
                          onRetry: vm.load,
                        ),
                        MyRatingsStatus.error => _Message(
                          icon: Icons.wifi_off_rounded,
                          message: vm.errorMessage!,
                          onRetry: vm.load,
                        ),
                        MyRatingsStatus.loading ||
                        MyRatingsStatus.success => RefreshIndicator(
                          onRefresh: vm.load,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: vm.ratings.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final rating = vm.ratings[index];
                              final movie = vm.moviesById[rating.movieId];
                              final date = rating.createdAt.toLocal();
                              final dateText =
                                  '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
                              return Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    color: AppColors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: SizedBox(
                                              width: 78,
                                              height: 117,
                                              child: movie == null
                                                  ? const ColoredBox(
                                                      color:
                                                          AppColors.softViolet,
                                                      child: Icon(
                                                        Icons.movie_outlined,
                                                      ),
                                                    )
                                                  : TmdbPoster(
                                                      movie: movie.toMovie(
                                                        const [],
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  movie?.title ??
                                                      '영화 #${rating.movieId}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '★ ${rating.score} / 5',
                                                  style: const TextStyle(
                                                    color: AppColors.violet,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  rating.comment
                                                              ?.trim()
                                                              .isNotEmpty ==
                                                          true
                                                      ? rating.comment!
                                                      : '작성한 후기가 없습니다.',
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  dateText,
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .onSurfaceVariant,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (movie == null)
                                                  const Text(
                                                    '영화 정보를 불러오지 못했습니다.',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.error,
                                                    ),
                                                  ),
                                                if (!_selecting)
                                                  Wrap(
                                                    children: [
                                                      TextButton(
                                                        onPressed: vm.canWrite
                                                            ? () => _edit(
                                                                vm,
                                                                rating,
                                                              )
                                                            : null,
                                                        child: const Text('수정'),
                                                      ),
                                                      TextButton(
                                                        onPressed: vm.canWrite
                                                            ? () => _delete(
                                                                vm,
                                                                {
                                                                  rating
                                                                      .ratingId,
                                                                },
                                                              )
                                                            : null,
                                                        child: const Text('삭제'),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (_selecting)
                                            Checkbox(
                                              value: activeSelection.contains(
                                                rating.ratingId,
                                              ),
                                              onChanged: !vm.canWrite
                                                  ? null
                                                  : (checked) {
                                                      setState(() {
                                                        if (checked == true) {
                                                          _selected.add(
                                                            rating.ratingId,
                                                          );
                                                        } else {
                                                          _selected.remove(
                                                            rating.ratingId,
                                                          );
                                                        }
                                                      });
                                                    },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      },
              ),
              if (_selecting)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: MovieLogButton(
                    label: '선택한 ${activeSelection.length}개 삭제',
                    width: double.infinity,
                    isLoading: vm.isWriting,
                    onPressed: vm.canWrite && activeSelection.isNotEmpty
                        ? () => _delete(vm, activeSelection)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.message,
    required this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.violet),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          MovieLogButton(label: '다시 불러오기', width: 160, onPressed: onRetry),
        ],
      ),
    ),
  );
}
