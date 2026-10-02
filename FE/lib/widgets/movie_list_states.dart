import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('movie-list-loading'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.54,
      ),
      itemBuilder: (context, index) => const _MovieCardSkeleton(),
    );
  }
}

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      key: ValueKey('movie-list-empty'),
      physics: AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 360,
        child: Center(child: Text('조건에 맞는 영화가 없습니다.')),
      ),
    );
  }
}

class MovieListError extends StatelessWidget {
  const MovieListError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('movie-list-error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('영화를 불러오지 못했습니다.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _MovieCardSkeleton extends StatelessWidget {
  const _MovieCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '영화 정보를 불러오는 중',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.softViolet.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _SkeletonLine(widthFactor: 0.72, height: 18),
          const SizedBox(height: 8),
          const _SkeletonLine(widthFactor: 0.48, height: 14),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.softViolet.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
