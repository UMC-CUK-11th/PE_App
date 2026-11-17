import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/create_member_request.dart';
import '../../view_models/sign_up_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movielog_button.dart';
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

  /// 로컬 Form 검증 뒤 v6 회원가입 POST를 보냅니다. 비밀번호는 로그에 남기지 않습니다.
  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_agreedToTerms) return;

    FocusScope.of(context).unfocus();
    final viewModel = context.read<SignUpViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    if (!mounted) return;

    if (viewModel.createdMemberId != null) {
      // v7부터 회원은 토큰으로 식별하므로 가입 뒤 로그인으로 보냅니다.
      messenger.showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해 주세요.')),
      );
      context.go('/login');
      return;
    }
    // snackbarMessage는 Form 어디에도 붙지 않아 제출 직후 한 번만 꺼내 보여줍니다.
    final message = viewModel.snackbarMessage;
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// 제출 중에는 뒤로가기·스와이프 백을 막고, 제출이 끝나면 다시 나갈 수 있습니다.
  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop || context.read<SignUpViewModel>().isSubmitting) return;
    context.canPop() ? context.pop() : context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
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

  Widget _buildForm({required bool isWide}) {
    final viewModel = context.watch<SignUpViewModel>();
    final nickname = viewModel.nickname;
    final email = viewModel.email;
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
              viewModel.onNicknameChanged(value);
              _onFieldChanged(value);
            },
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            errorText: nickname.errorText,
            helperText: nickname.status == CheckStatus.available
                ? '사용할 수 있는 닉네임입니다.'
                : null,
            // 입력창 옆 보조 버튼: width null(내용 크기)
            action: MovieLogButton(
              label: '중복 확인',
              isLoading: nickname.status == CheckStatus.checking,
              onPressed: nicknameValid && nickname.canCheck
                  ? () => viewModel.checkNickname(_nicknameController.text)
                  : null,
            ),
          ),
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
              viewModel.onEmailChanged(value);
              _onFieldChanged(value);
            },
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            errorText: email.errorText,
            helperText: email.status == CheckStatus.available
                ? '사용할 수 있는 이메일입니다.'
                : null,
            action: MovieLogButton(
              label: '중복 확인',
              isLoading: email.status == CheckStatus.checking,
              onPressed: emailValid && email.canCheck
                  ? () => viewModel.checkEmail(_emailController.text)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          MovieLogTextFormField(
            label: '비밀번호',
            hintText: '비밀번호를 입력해주세요',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            validator: SignUpValidators.password,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            // 서버가 거부한 비밀번호는 로컬 검증을 통과해도 에러로 남깁니다.
            errorText: viewModel.passwordErrorText,
            onChanged: (value) {
              viewModel.onPasswordChanged();
              _onFieldChanged(value);
            },
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
          // Form 하단 버튼: width double.infinity(부모 최대 너비)
          MovieLogButton(
            label: '가입하기',
            width: double.infinity,
            height: 52,
            isLoading: viewModel.isSubmitting, // 제출 중 중복 탭을 막습니다.
            onPressed: _canSubmit(viewModel) ? _submit : null,
          ),
          const SizedBox(height: 16),
          const LoginPrompt(),
        ],
      ),
    );
  }
}
