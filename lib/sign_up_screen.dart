import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/movie_log_text_form_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nicknameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _nicknameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해주세요.';
    if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해주세요.';

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }

  bool get _isNicknameValid =>
      _validateNickname(_nicknameController.text) == null;
  bool get _isEmailValid => _validateEmail(_emailController.text) == null;
  bool get _isPasswordValid =>
      _validatePassword(_passwordController.text) == null;

  bool get _canSubmit =>
      _isNicknameValid && _isEmailValid && _isPasswordValid && _agreedToTerms;

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_agreedToTerms) return;

    FocusScope.of(context).unfocus();
    debugPrint(
      '회원가입 입력 완료: ${_nicknameController.text.trim()}, '
      '${_emailController.text.trim()}',
    );
  }

  void _handleBack() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).maybePop();
  }

  void _handleAgreementChanged(bool? value) {
    FocusScope.of(context).unfocus();
    setState(() => _agreedToTerms = value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return _buildWideLayout();
        }
        return _buildMobileLayout();
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
        onBack: _handleBack,
        titleStyle: AppTextStyles.signUpAppBarTitle,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SignUpHeader(isWide: false),
                          const SizedBox(height: 32),
                          _buildFields(isWide: false),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 32, bottom: 16),
                        child: _SignUpActions(
                          isWide: false,
                          agreedToTerms: _agreedToTerms,
                          canSubmit: _canSubmit,
                          onAgreementChanged: _handleAgreementChanged,
                          onSubmit: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: DecoratedBox(
                key: const ValueKey('wide-sign-up-container'),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SignUpHeader(isWide: true),
                        const SizedBox(height: 40),
                        _buildFields(isWide: true),
                        const SizedBox(height: 12),
                        _SignUpActions(
                          isWide: true,
                          agreedToTerms: _agreedToTerms,
                          canSubmit: _canSubmit,
                          onAgreementChanged: _handleAgreementChanged,
                          onSubmit: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFields({required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MovieLogTextFormField(
          label: '닉네임',
          hintText: isWide ? '영화로운 닉네임을 입력하세요' : '닉네임을 입력해주세요',
          controller: _nicknameController,
          focusNode: _nicknameFocusNode,
          validator: _validateNickname,
          onChanged: (_) {
            setState(() => _nicknameTouched = true);
          },
          onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          isCompact: isWide,
          isValid: _nicknameTouched && _isNicknameValid,
          showError: _nicknameTouched && !_isNicknameValid,
          inputFontWeight: _nicknameTouched && _isNicknameValid
              ? FontWeight.w500
              : FontWeight.w400,
          hintFontWeight: isWide ? FontWeight.w400 : FontWeight.w500,
        ),
        SizedBox(height: isWide ? 4 : 16),
        MovieLogTextFormField(
          label: isWide ? '이메일 주소' : '이메일',
          hintText: isWide ? 'example@movielog.com' : '이메일 주소를 입력해주세요',
          controller: _emailController,
          focusNode: _emailFocusNode,
          validator: _validateEmail,
          onChanged: (_) {
            setState(() => _emailTouched = true);
          },
          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          isCompact: isWide,
          isValid: _emailTouched && _isEmailValid,
          showError: _emailTouched && !_isEmailValid,
          hintFontWeight: isWide ? FontWeight.w400 : FontWeight.w500,
        ),
        SizedBox(height: isWide ? 4 : 16),
        MovieLogTextFormField(
          label: '비밀번호',
          hintText: isWide ? '영문, 숫자 포함 8자 이상' : '비밀번호를 입력해주세요',
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          validator: _validatePassword,
          onChanged: (_) {
            setState(() => _passwordTouched = true);
          },
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          textInputAction: TextInputAction.done,
          isCompact: isWide,
          isValid: _passwordTouched && _isPasswordValid,
          showError: _passwordTouched && !_isPasswordValid,
          obscureText: _obscurePassword,
          onToggleObscure: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ],
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return const Column(
        children: [
          Text(
            '회원가입',
            textAlign: TextAlign.center,
            style: AppTextStyles.signUpTitle,
          ),
          SizedBox(height: 8),
          Text(
            'MovieLog에 오신 것을 환영합니다!',
            textAlign: TextAlign.center,
            style: AppTextStyles.signUpSubtitle,
          ),
        ],
      );
    }

    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

class _SignUpActions extends StatelessWidget {
  const _SignUpActions({
    required this.isWide,
    required this.agreedToTerms,
    required this.canSubmit,
    required this.onAgreementChanged,
    required this.onSubmit,
  });

  final bool isWide;
  final bool agreedToTerms;
  final bool canSubmit;
  final ValueChanged<bool?> onAgreementChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final compactStyle = isWide
        ? AppTextStyles.fieldLabelCompact
        : AppTextStyles.fieldLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: isWide ? 20 : 24,
              height: isWide ? 20 : 24,
              child: Checkbox(
                value: agreedToTerms,
                onChanged: onAgreementChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                checkColor: AppColors.white,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.violet;
                  }
                  return AppColors.white;
                }),
                side: const BorderSide(color: AppColors.gray),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text('필수 약관에 동의합니다', style: compactStyle)),
          ],
        ),
        SizedBox(height: isWide ? 32 : 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: canSubmit ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violet,
              disabledBackgroundColor: AppColors.disabledButton,
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.white,
              elevation: 1,
              shadowColor: const Color(0x0D000000),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '가입하기',
              style: isWide
                  ? AppTextStyles.buttonLabelCompact
                  : AppTextStyles.buttonLabel,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '이미 계정이 있나요?',
              style: compactStyle.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => debugPrint('로그인 버튼을 눌렀습니다.'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.violet,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '로그인',
                style: compactStyle.copyWith(color: AppColors.violet),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
