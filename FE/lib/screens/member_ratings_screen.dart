import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/member_ratings_view_model.dart';
import '../widgets/app_button.dart';
import '../widgets/common_app_bar.dart';

class MemberRatingsScreen extends StatefulWidget {
  const MemberRatingsScreen({required this.viewModel, super.key});

  final MemberRatingsViewModel viewModel;

  @override
  State<MemberRatingsScreen> createState() => _MemberRatingsScreenState();
}

class _MemberRatingsScreenState extends State<MemberRatingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        titleStyle: AppTextStyles.signUpAppBarTitle.copyWith(fontSize: 20),
        onBack: () => context.canPop() ? context.pop() : context.go('/my'),
      ),
      body: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, _) => switch (widget.viewModel.state) {
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
                    onPressed: widget.viewModel.load,
                  ),
                ),
              ],
            ),
          ),
          MemberRatingsLoadState.success => ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            itemCount: widget.viewModel.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 18),
            itemBuilder: (context, index) =>
                _RatingCard(item: widget.viewModel.items[index]),
          ),
        },
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
  const _RatingCard({required this.item});

  final MemberRatingItem item;

  @override
  Widget build(BuildContext context) {
    final comment = item.rating.comment?.trim();
    return Container(
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
        ],
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
