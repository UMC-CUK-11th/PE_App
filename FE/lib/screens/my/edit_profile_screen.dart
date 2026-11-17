import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/edit_profile_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movielog_button.dart';

/// 프로필 수정. email은 읽기 전용, nickname만 PATCH /v7/members/me로 바꿉니다.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;
  late final String _initialNickname;

  @override
  void initState() {
    super.initState();
    _initialNickname = context.read<AuthViewModel>().member?.nickname ?? '';
    _controller = TextEditingController(text: _initialNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasChanges => _controller.text.trim() != _initialNickname;

  void _close() => context.canPop() ? context.pop() : context.go('/my');

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await viewModel.save(_controller.text);
    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      _close(); // 마이페이지에는 새 닉네임이 이미 반영되어 있습니다.
    } else if (viewModel.message case final message?) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Challenge: 변경 내용이 있으면 나가기 전에 확인합니다.
  Future<void> _onBack() async {
    if (context.read<EditProfileViewModel>().isSaving) return;
    if (!_hasChanges) {
      _close();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('수정을 취소할까요?'),
        content: const Text('변경한 내용이 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.violet),
            child: const Text('계속 수정'),
          ),
          MovieLogButton(
            label: '나가기',
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (a) => a.member?.email,
    );

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.isSaving;
        return PopScope(
          canPop: false, // 저장 중 차단·변경 확인 Dialog를 직접 처리합니다.
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBack();
          },
          child: Scaffold(
            appBar: CommonAppBar(
              title: '프로필 수정',
              centerTitle: true,
              onBack: _onBack,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: email,
                      enabled: false, // email은 읽기 전용입니다.
                      decoration: const InputDecoration(labelText: '이메일'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: 12,
                      onChanged: (_) {
                        viewModel.onNicknameChanged();
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        errorText: viewModel.nicknameError,
                      ),
                    ),
                    const Spacer(),
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      height: 52,
                      isLoading: saving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
