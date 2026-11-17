import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/member_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/stat_item.dart';

/// 마이페이지. 이메일·닉네임·가입일은 GET me 결과(AuthViewModel.member)를 구독합니다.
/// 사진·통계·장르는 기존 디자인 예시입니다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: [
          TextButton(
            // 토큰과 member를 지우면 Router가 /login으로 보냅니다.
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            style: TextButton.styleFrom(foregroundColor: AppColors.violet),
            child: const Text('로그아웃'),
          ),
        ],
      ),
      // Challenge: 내 정보 로딩 중이면 전체 인디케이터, 실패면 재시도 버튼.
      body: member == null
          ? Center(
              child: auth.memberStatus == MemberLoadStatus.error
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '내 정보를 불러오지 못했어요.',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        MovieLogButton(
                          label: '다시 시도',
                          width: 120,
                          onPressed: () => auth.loadMember(force: true),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(color: AppColors.violet),
            )
          : _ProfileBody(member: member),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.member});

  final MemberInfo member;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(member: member),
            const SizedBox(height: 16),
            const EditProfileButton(),
            const SizedBox(height: 32),
            const ProfileStats(),
            const SizedBox(height: 32),
            const FavoriteGenres(),
            const SizedBox(height: 32),
            const MyRatingsEntry(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.member});

  final MemberInfo member;

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final joined = member.createdAt.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/profile/profile_movielog.jpg',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            semanticLabel: '프로필 이미지',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(member.nickname, style: AppTextStyles.titleLarge)],
        ),
        const SizedBox(height: 4),
        Text(
          member.email,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
        ),
        const SizedBox(height: 4),
        // Challenge: 가입일을 "2026.10.10 가입" 형식으로 표시합니다.
        Text(
          '${joined.year}.${_two(joined.month)}.${_two(joined.day)} 가입',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
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

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('선호 장르', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genres
              .map(
                (genre) => Chip(
                  label: Text(
                    genre,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  backgroundColor: AppColors.violet,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
        onPressed: () => context.push('/my/profile/edit'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violet,
          side: const BorderSide(color: AppColors.violet),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text('프로필 수정'),
      ),
    );
  }
}

/// 마이페이지 → 내가 등록한 평점(자식 화면) 진입 항목입니다.
class MyRatingsEntry extends StatelessWidget {
  const MyRatingsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(
          Icons.rate_review_outlined,
          color: AppColors.violet,
        ),
        title: Text('내가 등록한 평점', style: AppTextStyles.labelLarge),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/my/ratings'),
      ),
    );
  }
}
