import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/member_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/stat_item.dart';
import '../view_models/auth_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    AuthViewModel? auth;
    try {
      auth = context.watch<AuthViewModel>();
    } on ProviderNotFoundException {
      auth = null;
    }
    if (auth == null) {
      return Scaffold(
        appBar: const CommonAppBar(
          title: '내 프로필',
          titleStyle: AppTextStyles.signUpAppBarTitle,
        ),
        body: _buildProfileContent(
          context,
          MemberInfo(
            memberId: 1,
            email: 'movie@example.com',
            nickname: '무비러버',
            createdAt: DateTime(2026, 10, 10),
          ),
        ),
      );
    }
    final isMemberReady = auth.memberStatus == MemberLoadStatus.success;
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        centerTitle: !isMemberReady,
        titleStyle: isMemberReady
            ? AppTextStyles.profileTitle
            : AppTextStyles.signUpAppBarTitle.copyWith(fontSize: 20),
        actions: isMemberReady
            ? [TextButton(onPressed: auth.logout, child: const Text('로그아웃'))]
            : null,
      ),
      body: _buildBody(context, auth),
    );
  }

  Widget _buildBody(BuildContext context, AuthViewModel auth) {
    if (auth.memberStatus == MemberLoadStatus.loading ||
        (auth.member == null && auth.memberStatus == MemberLoadStatus.idle)) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.violet),
      );
    }
    if (auth.memberStatus == MemberLoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '내 정보를 불러오지 못했어요.',
              style: TextStyle(
                color: Color(0xFF655F6C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 218,
              height: 44,
              child: FilledButton(
                onPressed: () => auth.loadMember(force: true),
                child: const Text('다시 시도'),
              ),
            ),
          ],
        ),
      );
    }
    final member = auth.member;
    if (member == null) return const SizedBox.shrink();
    return _buildProfileContent(context, member);
  }

  Widget _buildProfileContent(BuildContext context, MemberInfo member) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(member: member),
            const SizedBox(height: 32),
            const _ProfileStats(),
            const SizedBox(height: 26),
            InkWell(
              key: const ValueKey('my-ratings-entry'),
              onTap: () => context.push('/my/ratings'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.softViolet),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        '내가 등록한 평점',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('선호하는 장르', style: AppTextStyles.titleMedium),
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
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.member});

  final MemberInfo member;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 126,
          height: 126,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.profileBorder, width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              fit: BoxFit.cover,
              semanticLabel: '무비러버 프로필 이미지',
            ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 358),
          child: Text(
            member.nickname,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 358),
          child: Text(
            member.email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
              height: 20 / 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${member.createdAt.year}.${member.createdAt.month.toString().padLeft(2, '0')}.${member.createdAt.day.toString().padLeft(2, '0')} 가입',
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 127,
          height: 40,
          child: TextButton(
            onPressed: () => context.push('/my/profile/edit'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.violet,
              side: const BorderSide(color: AppColors.violet),
              minimumSize: const Size(127, 40),
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
      constraints: const BoxConstraints(minHeight: 32),
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
