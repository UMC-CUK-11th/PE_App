import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/common_response.dart';
import '../view_models/auth_session.dart';
import '../view_models/signup_view_model.dart';
import '../widgets/movielog_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final String _original;
  late final TextEditingController _nickname;
  bool _saving = false;
  bool _confirming = false;
  String? _error;

  bool get _dirty => _nickname.text.trim() != _original;

  @override
  void initState() {
    super.initState();
    _original = context.read<AuthSession>().member?.nickname ?? '';
    _nickname = TextEditingController(text: _original);
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_saving || _confirming) return;
    if (_dirty) {
      _confirming = true;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('수정을 취소할까요?'),
          content: const Text('입력한 변경 사항이 사라집니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속 수정'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('나가기'),
            ),
          ],
        ),
      );
      _confirming = false;
      if (confirmed != true || !mounted) return;
    }
    context.go('/my');
  }

  Future<void> _save() async {
    if (_saving || !_dirty || !_form.currentState!.validate()) return;
    final session = context.read<AuthSession>();
    final generation = session.generation;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await session.updateNickname(_nickname.text);
      if (mounted && session.isCurrent(generation)) context.go('/my');
    } catch (error) {
      if (!mounted || !session.isCurrent(generation)) return;
      final failure = ApiFailure.from(error, '닉네임을 저장하지 못했습니다. 다시 시도해 주세요.');
      setState(() {
        _error = failure.code == 'MEMBER409_1'
            ? '이미 사용 중인 닉네임입니다.'
            : failure.message;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _saving ? null : _back),
          title: const Text('프로필 수정'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nickname,
                        enabled: !_saving,
                        decoration: InputDecoration(
                          labelText: '닉네임',
                          errorText: _error,
                        ),
                        validator: SignUpViewModel.validateNickname,
                        onChanged: (_) => setState(() => _error = null),
                        onFieldSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: 20),
                      MovieLogButton(
                        label: '저장',
                        height: 52,
                        isLoading: _saving,
                        onPressed: _saving || !_dirty ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
