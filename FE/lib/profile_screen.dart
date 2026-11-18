import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/auth_models.dart';
import 'view_models/auth_session.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession?>();
    final status = session?.memberStatus;
    final member = session?.member;
    final body = status == MemberLoadStatus.error
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('내 정보를 불러오지 못했습니다.'),
                TextButton(
                  onPressed: session!.loadMember,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          )
        : session != null && member == null
        ? const Center(child: CircularProgressIndicator())
        : _buildProfile(context, member);
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        titleStyle: AppTextStyles.signUpAppBarTitle,
        actions: [
          if (session != null)
            IconButton(
              tooltip: '로그아웃',
              onPressed: session.busy
                  ? null
                  : () async {
                      try {
                        await session.logout();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('로그아웃하지 못했습니다. 다시 시도해 주세요.'),
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildProfile(BuildContext context, MemberInfo? member) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(member: member),
            const SizedBox(height: 32),
            if (member == null) const _ProfileStats(),
            const SizedBox(height: 24),
            Card(
              color: AppColors.white,
              child: ListTile(
                leading: const Icon(
                  Icons.star_outline_rounded,
                  color: AppColors.violet,
                ),
                title: const Text('내가 등록한 평점'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/ratings'),
              ),
            ),
            const SizedBox(height: 32),
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
  const _ProfileHeader({this.member});
  final MemberInfo? member;

  @override
  Widget build(BuildContext context) {
    final member = this.member;
    final date = member?.createdAt.toLocal();
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
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
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 318),
          child: Text(
            member?.nickname ?? '무비러버',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 318),
          child: Text(
            member?.email ??
                '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if (date != null)
          Text(
            '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} 가입',
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: 127,
          height: 42,
          child: TextButton(
            onPressed: member == null
                ? null
                : () => context.push('/my/profile/edit'),
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
