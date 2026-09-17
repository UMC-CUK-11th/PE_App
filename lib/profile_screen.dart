import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ProfileHeader(),
              const SizedBox(height: 32),
              const _ProfileStats(),
              const SizedBox(height: 32),
              const SizedBox(
                width: 358,
                height: 24,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('선호하는 장르', style: AppTextStyles.titleMedium),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genres
                    .map((genre) => _GenreChip(label: genre))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.profileBorder, width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile_photo.jpg',
              fit: BoxFit.cover,
              semanticLabel: '무비러버 프로필 이미지',
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 318,
          height: 28,
          child: Center(child: Text('무비러버', style: AppTextStyles.titleLarge)),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: const SizedBox(
            width: 318,
            height: 48,
            child: Text(
              '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 127,
          height: 42,
          child: TextButton(
            onPressed: () {
              debugPrint('프로필 수정 버튼을 눌렀습니다.');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.violet,
              side: const BorderSide(color: AppColors.violet),
              minimumSize: const Size(127, 42),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('프로필 수정', style: AppTextStyles.labelLarge),
          ),
        ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: StatItem(label: '본 영화', value: '342'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: StatItem(label: '평점', value: '4.2'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: StatItem(label: '즐겨찾기', value: '58'),
        ),
      ],
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.softViolet,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTextStyles.genreLabel.copyWith(
          fontWeight: label == 'SF' ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
