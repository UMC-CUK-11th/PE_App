import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/sign_up_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movielog_text_form_field.dart';
import 'sign_up_sections.dart';
import 'sign_up_validators.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _wideBreakpoint = 700.0;
  static const _maxFormWidth = 560.0;
  static const _verticalPadding = 24.0;

  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  // 닉네임·이메일은 형식뿐 아니라 서버 중복 체크까지 통과해야 가입할 수 있습니다.
  bool _canSubmit(SignUpViewModel viewModel) =>
      SignUpValidators.nickname(_nicknameController.text) == null &&
      SignUpValidators.email(_emailController.text) == null &&
      SignUpValidators.password(_passwordController.text) == null &&
      viewModel.bothAvailable &&
      _agreedToTerms;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onFieldChanged(String _) => setState(() {});

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_agreedToTerms) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다.')));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: const CommonAppBar(title: '회원가입', centerTitle: true),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= _wideBreakpoint;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: _verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? _maxFormWidth : double.infinity,
                      minHeight: math.max(
                        0.0,
                        constraints.maxHeight - _verticalPadding * 2,
                      ),
                    ),
                    child: IntrinsicHeight(child: _buildForm(isWide: isWide)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _checkButton({
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(foregroundColor: AppColors.violet),
      child: const Text('중복 확인'),
    );
  }

  Widget _buildForm({required bool isWide}) {
    final viewModel = context.watch<SignUpViewModel>();
    final nicknameValid =
        SignUpValidators.nickname(_nicknameController.text) == null;
    final emailValid = SignUpValidators.email(_emailController.text) == null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: isWide
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          const SignUpHeader(),
          const SizedBox(height: 32),
          MovieLogTextFormField(
            label: '닉네임',
            hintText: '닉네임을 입력해주세요',
            controller: _nicknameController,
            validator: SignUpValidators.nickname,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              viewModel.nicknameChanged();
              _onFieldChanged(value);
            },
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            trailing: _checkButton(
              enabled:
                  nicknameValid &&
                  viewModel.nickname != DuplicateCheck.checking,
              onPressed: () =>
                  viewModel.checkNickname(_nicknameController.text.trim()),
            ),
          ),
          DuplicateCheckMessage(status: viewModel.nickname, label: '닉네임'),
          const SizedBox(height: 16),
          MovieLogTextFormField(
            label: '이메일',
            hintText: '이메일 주소를 입력해주세요',
            controller: _emailController,
            focusNode: _emailFocusNode,
            validator: SignUpValidators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              viewModel.emailChanged();
              _onFieldChanged(value);
            },
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            trailing: _checkButton(
              enabled: emailValid && viewModel.email != DuplicateCheck.checking,
              onPressed: () =>
                  viewModel.checkEmail(_emailController.text.trim()),
            ),
          ),
          DuplicateCheckMessage(status: viewModel.email, label: '이메일'),
          const SizedBox(height: 16),
          MovieLogTextFormField(
            label: '비밀번호',
            hintText: '비밀번호를 입력해주세요',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            validator: SignUpValidators.password,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onChanged: _onFieldChanged,
            onFieldSubmitted: (_) => _passwordFocusNode.unfocus(),
            trailing: IconButton(
              tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          if (isWide) const SizedBox(height: 24) else const Spacer(),
          const SizedBox(height: 24),
          TermsAgreement(
            value: _agreedToTerms,
            onChanged: (value) => setState(() => _agreedToTerms = value),
          ),
          const SizedBox(height: 16),
          SignUpButton(enabled: _canSubmit(viewModel), onPressed: _submit),
          const SizedBox(height: 16),
          const LoginPrompt(),
        ],
      ),
    );
  }
}

/// 중복 체크 결과 문구. 확인 전에는 자리만 차지하지 않도록 비워 둡니다.
class DuplicateCheckMessage extends StatelessWidget {
  const DuplicateCheckMessage({
    super.key,
    required this.status,
    required this.label,
  });

  final DuplicateCheck status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      DuplicateCheck.unchecked => (null, AppColors.gray),
      DuplicateCheck.checking => ('$label 확인 중이에요…', AppColors.gray),
      DuplicateCheck.available => ('사용 가능한 $label이에요', AppColors.violet),
      DuplicateCheck.taken => ('이미 사용 중인 $label이에요', AppColors.error),
      DuplicateCheck.failed => ('확인하지 못했어요. 잠시 후 다시 시도해 주세요', AppColors.error),
    };
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: color)),
    );
  }
}
