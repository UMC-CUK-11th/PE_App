import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/rating_dto.dart';
import '../../data/models/rating_with_movie.dart';
import '../../data/services/rating_api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/my_ratings_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movielog_button.dart';
import '../../widgets/rating_dialog.dart';
import '../../widgets/tmdb_poster_image.dart';

void _goBack(BuildContext context) =>
    context.canPop() ? context.pop() : context.go('/my');

/// 마이페이지 위에 열리는 자식 화면입니다. root Navigator에 올라가 하단 탭이 보이지 않습니다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        final deleting = viewModel.isDeletingSelected;
        final showSelectionBar =
            viewModel.isEditing &&
            viewModel.status == MyRatingsLoadStatus.success;

        // 다중 삭제 중에는 뒤로가기·스와이프 백을 막습니다.
        return PopScope(
          canPop: !deleting,
          child: Stack(
            children: [
              Scaffold(
                appBar: CommonAppBar(
                  title: '내가 등록한 평점',
                  centerTitle: true,
                  onBack: () => _goBack(context),
                ),
                body: switch (viewModel.status) {
                  MyRatingsLoadStatus.idle ||
                  MyRatingsLoadStatus.loading => const Center(
                    child: CircularProgressIndicator(color: AppColors.violet),
                  ),
                  MyRatingsLoadStatus.empty => const _Message(
                    icon: Icons.rate_review_outlined,
                    text: '이번 로그인에서 등록한 평점이 없어요.\n영화 상세에서 평점을 남겨 보세요.',
                  ),
                  MyRatingsLoadStatus.success => _RatingList(
                    viewModel: viewModel,
                  ),
                },
                bottomNavigationBar: showSelectionBar
                    ? SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: MovieLogButton(
                            label:
                                '선택한 ${viewModel.selectedRatingIds.length}개 삭제',
                            width: double.infinity,
                            height: 52,
                            onPressed: viewModel.selectedRatingIds.isEmpty
                                ? null
                                : () => _onDeleteSelectedPressed(context),
                          ),
                        ),
                      )
                    : null,
              ),
              if (deleting) const _LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }
}

/// 다중 삭제 중에만 목록 위에 올립니다. 흰 카드·문구 없이 어두운 배경과 인디케이터만 둡니다.
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        ModalBarrier(dismissible: false, color: Colors.black54),
        Center(child: CircularProgressIndicator(color: AppColors.white)),
      ],
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final message = viewModel.message;
    final editing = viewModel.isEditing;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                editing
                    ? '${viewModel.selectedRatingIds.length}개 선택'
                    // v7에는 토큰 기반 내 평점 목록 GET이 없어 이번 세션 등록분만 보여줍니다.
                    : '이번 로그인에서 등록한 평점 ${viewModel.ratings.length}개',
                style: AppTextStyles.bodySmall,
              ),
            ),
            TextButton(
              onPressed: editing
                  ? viewModel.cancelEditing
                  : viewModel.startEditing,
              style: TextButton.styleFrom(foregroundColor: AppColors.violet),
              child: Text(editing ? '취소' : '편집'),
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 12),
        for (final entry in viewModel.ratings)
          _RatingCard(
            entry: entry,
            editing: editing,
            selected: viewModel.selectedRatingIds.contains(
              entry.rating.ratingId,
            ),
            onToggle: () => viewModel.toggleSelected(entry.rating.ratingId),
          ),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.entry,
    required this.editing,
    required this.selected,
    required this.onToggle,
  });

  final RatingWithMovie entry;
  final bool editing;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final date = rating.createdAt.toLocal();

    // 이 화면의 목록은 모두 현재 학습용 회원이 쓴 평점이라 카드마다 수정·삭제를 둡니다.
    final trailing = editing
        ? Checkbox(
            value: selected,
            activeColor: AppColors.violet,
            onChanged: (_) => onToggle(),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '수정',
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.violet,
                onPressed: () => _onEditPressed(context, rating),
              ),
              IconButton(
                tooltip: '삭제',
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                onPressed: () => _onDeletePressed(context, rating),
              ),
            ],
          );

    return InkWell(
      onTap: editing ? onToggle : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.outline,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 64,
              height: 96,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 정보를 찾을 수 없어요',
                    style: AppTextStyles.labelLarge,
                  ),
                  Text(
                    'movieId ${rating.movieId}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= rating.score ? Icons.star : Icons.star_border,
                          size: 18,
                          color: AppColors.violet,
                        ),
                      const SizedBox(width: 6),
                      Text('${rating.score}점', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  // comment가 null이면 표시하지 않습니다.
                  if (rating.comment case final comment?) ...[
                    const SizedBox(height: 6),
                    Text(comment, style: AppTextStyles.bodyMedium),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${date.year}.${_two(date.month)}.${_two(date.day)} 등록',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// 기존 별점·코멘트를 채운 RatingDialog를 다시 엽니다.
/// Dialog 안에서는 실제 rating 객체를 건드리지 않아 취소 시 복구 로직이 필요 없습니다.
Future<void> _onEditPressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      initialComment: rating.comment, // null이면 빈 칸으로 시작합니다.
      onSubmit: (score, comment) => viewModel.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      ),
    ),
  );
}

/// 삭제 확인 후에만 DELETE를 보냅니다. 단일 삭제는 요청이 끝날 때까지 Dialog를 유지합니다.
Future<void> _onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => _DeleteRatingDialog(
      title: '평점을 삭제할까요?',
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );
}

/// 다중 삭제는 확인 Dialog를 바로 닫고, 화면의 로딩 오버레이가 이어받습니다.
Future<void> _onDeleteSelectedPressed(BuildContext context) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _DeleteRatingDialog(title: '선택한 평점을 삭제할까요?'),
  );
  if (confirmed != true || !context.mounted) return;

  await viewModel.deleteSelectedRatings();
  if (!context.mounted || viewModel.selectedRatingIds.isEmpty) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(viewModel.message ?? '일부 평점을 삭제하지 못했습니다.')),
  );
}

/// onConfirm이 있으면 Dialog 안에서 삭제까지 기다리고, 없으면 확인 여부만 돌려줍니다.
class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.title, this.onConfirm});

  final String title;
  final Future<void> Function()? onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;

  Future<void> _onConfirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is DioException
                ? writeErrorMessage(error)
                : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(widget.title),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.violet),
            child: const Text('취소'),
          ),
          MovieLogButton(
            label: '삭제',
            isLoading: _isDeleting,
            onPressed: _onConfirm,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.gray),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
