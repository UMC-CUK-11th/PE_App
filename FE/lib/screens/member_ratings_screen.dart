import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/member_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/member_ratings_view_model.dart';
import '../widgets/app_button.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/rating_dialog.dart';

class MemberRatingsScreen extends StatefulWidget {
  const MemberRatingsScreen({
    this.memberId,
    this.memberApiService,
    this.movieService,
    this.viewModel,
    super.key,
  }) : assert(
         viewModel != null ||
             (memberId != null &&
                 memberApiService != null &&
                 movieService != null),
       );

  final int? memberId;
  final MemberApiService? memberApiService;
  final TmdbMovieService? movieService;
  final MemberRatingsViewModel? viewModel;

  @override
  State<MemberRatingsScreen> createState() => _MemberRatingsScreenState();
}

class _MemberRatingsScreenState extends State<MemberRatingsScreen> {
  late MemberRatingsViewModel _viewModel;
  late bool _ownsViewModel;

  MemberRatingsViewModel _createViewModel() {
    return widget.viewModel ??
        MemberRatingsViewModel(
          memberId: widget.memberId!,
          memberApiService: widget.memberApiService!,
          movieService: widget.movieService!,
        );
  }

  @override
  void initState() {
    super.initState();
    _viewModel = _createViewModel();
    _ownsViewModel = widget.viewModel == null;
    _viewModel.load();
  }

  @override
  void didUpdateWidget(covariant MemberRatingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dependenciesChanged =
        oldWidget.viewModel != widget.viewModel ||
        oldWidget.memberId != widget.memberId ||
        !identical(oldWidget.memberApiService, widget.memberApiService) ||
        !identical(oldWidget.movieService, widget.movieService);
    if (!dependenciesChanged) return;
    if (_ownsViewModel) _viewModel.dispose();
    _viewModel = _createViewModel();
    _ownsViewModel = widget.viewModel == null;
    _viewModel.load();
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  Future<void> _edit(MemberRatingItem item) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        movieId: item.rating.movieId,
        initialScore: item.rating.score,
        initialComment: item.rating.comment,
        onSubmit: (score, comment) async {
          try {
            await _viewModel.updateRating(
              ratingId: item.rating.ratingId,
              score: score,
              comment: comment,
            );
          } on Object {
            throw StateError(
              _viewModel.message ?? '평점 수정에 실패했습니다. 다시 시도해 주세요.',
            );
          }
        },
      ),
    );
    if (!mounted || saved != true) return;
    _showMessage(_viewModel.refreshWarning ?? '평점을 수정했습니다.');
  }

  Future<void> _delete(MemberRatingItem item) async {
    var deleting = false;
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: !deleting,
          child: AlertDialog(
            title: const Text('평점을 삭제할까요?'),
            content: Text('「${item.title}」에 남긴 평점이 삭제됩니다.'),
            actions: [
              TextButton(
                onPressed: deleting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: deleting
                    ? null
                    : () async {
                        setDialogState(() => deleting = true);
                        try {
                          await _viewModel.deleteRating(item.rating.ratingId);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        } on Object {
                          if (dialogContext.mounted) {
                            setDialogState(() => deleting = false);
                          }
                        }
                      },
                child: deleting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('삭제'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (deleted == true) {
      _showMessage(_viewModel.refreshWarning ?? '평점을 삭제했습니다.');
    } else if (_viewModel.message != null) {
      _showMessage(_viewModel.message!);
    }
  }

  Future<void> _deleteSelected() async {
    final count = _viewModel.selectedRatingIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택한 평점을 삭제할까요?'),
        content: Text('$count개의 평점을 삭제합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failed = await _viewModel.deleteSelectedRatings();
    if (!mounted) return;
    if (failed > 0) {
      _showMessage(_viewModel.message!);
    } else {
      _showMessage(_viewModel.refreshWarning ?? '선택한 평점을 삭제했습니다.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => PopScope(
        canPop: !_viewModel.isDeletingSelected,
        child: Scaffold(
          appBar: CommonAppBar(
            title: _viewModel.isSelectionMode
                ? '${_viewModel.selectedRatingIds.length}개 선택'
                : '내가 등록한 평점',
            centerTitle: true,
            titleStyle: AppTextStyles.signUpAppBarTitle.copyWith(fontSize: 20),
            onBack: () {
              if (_viewModel.isDeletingSelected) return;
              context.canPop() ? context.pop() : context.go('/my');
            },
            actions: [
              TextButton(
                onPressed:
                    _viewModel.isDeletingSelected ||
                        (!_viewModel.isSelectionMode &&
                            _viewModel.state != MemberRatingsLoadState.success)
                    ? null
                    : _viewModel.isSelectionMode
                    ? _viewModel.cancelSelectionMode
                    : _viewModel.startSelectionMode,
                child: Text(_viewModel.isSelectionMode ? '취소' : '편집'),
              ),
            ],
          ),
          bottomNavigationBar: _viewModel.isSelectionMode
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: AppButton(
                    label: '선택한 ${_viewModel.selectedRatingIds.length}개 삭제',
                    onPressed:
                        _viewModel.selectedRatingIds.isEmpty ||
                            _viewModel.isDeletingSelected
                        ? null
                        : _deleteSelected,
                  ),
                )
              : null,
          body: Stack(
            children: [
              switch (_viewModel.state) {
                MemberRatingsLoadState.loading => const _CenteredState(
                  child: CircularProgressIndicator(color: AppColors.violet),
                ),
                MemberRatingsLoadState.empty => const _CenteredState(
                  child: Text('아직 등록한 평점이 없습니다.'),
                ),
                MemberRatingsLoadState.error => _CenteredState(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('평점 목록을 불러오지 못했습니다.'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 120,
                        child: AppButton(
                          label: '다시 시도',
                          onPressed: _viewModel.load,
                        ),
                      ),
                    ],
                  ),
                ),
                MemberRatingsLoadState.success => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                  itemCount: _viewModel.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final item = _viewModel.items[index];
                    return _RatingCard(
                      item: item,
                      isSelectionMode: _viewModel.isSelectionMode,
                      isSelected: _viewModel.selectedRatingIds.contains(
                        item.rating.ratingId,
                      ),
                      onSelected: () =>
                          _viewModel.toggleSelection(item.rating.ratingId),
                      onEdit: () => _edit(item),
                      onDelete: () => _delete(item),
                    );
                  },
                ),
              },
              if (_viewModel.isDeletingSelected) ...[
                const ModalBarrier(dismissible: false, color: Colors.black45),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
  });

  final MemberRatingItem item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final comment = item.rating.comment?.trim();
    return InkWell(
      onTap: isSelectionMode ? onSelected : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 156),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          border: Border.all(color: AppColors.softViolet),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 82,
                height: 124,
                child: item.posterUrl == null
                    ? const _PosterFallback()
                    : Image.network(
                        item.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _PosterFallback(),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 22 / 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '별점 ${item.rating.score} / 5',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.violet,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        comment == null || comment.isEmpty
                            ? '작성한 한줄평이 없습니다.'
                            : comment,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 19 / 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isSelectionMode)
              Checkbox(value: isSelected, onChanged: (_) => onSelected())
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: ValueKey('edit-rating-${item.rating.ratingId}'),
                    tooltip: '평점 수정',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    key: ValueKey('delete-rating-${item.rating.ratingId}'),
                    tooltip: '평점 삭제',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE7E4E8),
      child: Center(
        child: Icon(Icons.movie_outlined, color: AppColors.gray, size: 30),
      ),
    );
  }
}
