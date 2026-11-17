import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/app_button.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_log_text_form_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;
  late final EditProfileViewModel _viewModel;
  late final String _initialNickname;
  bool _allowPop = false;

  bool get _hasChanges =>
      _nicknameController.text.trim() != _initialNickname.trim();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthViewModel>();
    _initialNickname = auth.member?.nickname ?? '';
    _emailController = TextEditingController(text: auth.member?.email ?? '');
    _nicknameController = TextEditingController(text: _initialNickname)
      ..addListener(_onChanged);
    _viewModel = EditProfileViewModel(auth)..addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges || _viewModel.isSaving) return !_viewModel.isSaving;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('변경 내용을 버릴까요?'),
            content: const Text('저장하지 않은 닉네임 변경 내용이 사라집니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속 수정'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('나가기'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _back() async {
    if (!await _confirmDiscard() || !mounted) return;
    setState(() => _allowPop = true);
    context.pop();
  }

  Future<void> _save() async {
    final success = await _viewModel.save(_nicknameController.text);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로필을 수정했습니다.')));
      setState(() => _allowPop = true);
      context.pop();
    } else if (_viewModel.message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_viewModel.message!)));
    }
  }

  @override
  void dispose() {
    _nicknameController
      ..removeListener(_onChanged)
      ..dispose();
    _emailController.dispose();
    _viewModel
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthViewModel>();
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: CommonAppBar(title: '프로필 수정', centerTitle: true, onBack: _back),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            children: [
              MovieLogTextFormField(
                label: '이메일 (변경할 수 없습니다)',
                controller: _emailController,
                enabled: false,
              ),
              const SizedBox(height: 24),
              MovieLogTextFormField(
                label: '닉네임',
                hintText: '닉네임을 입력해주세요',
                controller: _nicknameController,
                enabled: !_viewModel.isSaving,
                maxLength: 12,
                errorText: _viewModel.fieldError,
                onChanged: (_) => _viewModel.clearError(),
              ),
              const SizedBox(height: 48),
              AppButton(
                label: '저장',
                isLoading: _viewModel.isSaving,
                onPressed: _viewModel.isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
