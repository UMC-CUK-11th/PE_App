import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  bool get _canSubmit =>
      SignUpValidators.nickname(_nicknameController.text) == null &&
      SignUpValidators.email(_emailController.text) == null &&
      SignUpValidators.password(_passwordController.text) == null &&
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입이 완료되었습니다.')),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: const CommonAppBar(
          title: '회원가입',
          centerTitle: true,
        ),
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
                    child: IntrinsicHeight(
                      child: _buildForm(isWide: isWide),
                    ),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment:
            isWide ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          const SignUpHeader(),
          const SizedBox(height: 32),
          MovieLogTextFormField(
            label: '닉네임',
            hintText: '닉네임을 입력해주세요',
            controller: _nicknameController,
            validator: SignUpValidators.nickname,
            textInputAction: TextInputAction.next,
            onChanged: _onFieldChanged,
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
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
            onChanged: _onFieldChanged,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
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
          SignUpButton(enabled: _canSubmit, onPressed: _submit),
          const SizedBox(height: 16),
          const LoginPrompt(),
        ],
      ),
    );
  }
}
