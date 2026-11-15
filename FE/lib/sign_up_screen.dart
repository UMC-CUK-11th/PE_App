import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'services/member_check_service.dart';
import 'services/movie_log_client.dart';
import 'view_models/signup_view_model.dart';
import 'widgets/movielog_button.dart';

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

  late final SignUpViewModel _viewModel;
  late final VoidCallback _closeClient;

  @override
  void initState() {
    super.initState();
    final provided = context.read<MemberCheckService?>();
    if (provided != null) {
      _viewModel = SignUpViewModel(provided);
      _closeClient = () {};
    } else {
      final client = createMovieLogClient();
      _viewModel = SignUpViewModel(MemberCheckService(client));
      _closeClient = () => client.close(force: true);
    }
  }

  bool _nicknameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _viewModel.dispose();
    _closeClient();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateNickname(String? value) =>
      SignUpViewModel.validateNickname(value);
  String? _validateEmail(String? value) => SignUpViewModel.validateEmail(value);

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    final hasEnglishLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    if (!hasEnglishLetter || !hasNumber) {
      return '비밀번호는 영문과 숫자를 포함해야 합니다.';
    }
    return null;
  }

  bool get _isNicknameValid =>
      _validateNickname(_nicknameController.text) == null;
  bool get _isEmailValid => _validateEmail(_emailController.text) == null;
  bool get _isPasswordValid =>
      _validatePassword(_passwordController.text) == null;

  bool get _canSubmit =>
      _isNicknameValid &&
      _isEmailValid &&
      _isPasswordValid &&
      _agreedToTerms &&
      _viewModel.bothAvailable;

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_canSubmit) return;

    FocusScope.of(context).unfocus();
    debugPrint('학습용 Form 확인 완료: 회원가입 API는 호출하지 않습니다.');
    context.go('/home');
  }

  void _handleAgreementChanged(bool? value) {
    FocusScope.of(context).unfocus();
    setState(() => _agreedToTerms = value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 700) {
            return _buildWideLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
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

  Widget _withCheckButton({
    required Widget child,
    required bool isWide,
    required bool nickname,
  }) {
    final status = nickname
        ? _viewModel.nicknameCheckStatus
        : _viewModel.emailCheckStatus;
    final enabled = nickname
        ? _viewModel.canCheckNickname
        : _viewModel.canCheckEmail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(top: isWide ? 24 : 28),
              child: MovieLogButton(
                key: ValueKey(nickname ? 'check-nickname' : 'check-email'),
                label: '중복 확인',
                width: nickname ? null : 104,
                height: 42,
                isLoading: status == CheckStatus.checking,
                onPressed: !enabled
                    ? null
                    : () {
                        if (nickname) {
                          _viewModel.checkNickname(_nicknameController.text);
                        } else {
                          _viewModel.checkEmail(_emailController.text);
                        }
                      },
              ),
            ),
          ],
        ),
        if (status == CheckStatus.available)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              '사용할 수 있는 ${nickname ? '닉네임' : '이메일'}입니다.',
              style: const TextStyle(color: AppColors.violet, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFields({required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _withCheckButton(
          isWide: isWide,
          nickname: true,
          child: MovieLogTextFormField(
            label: '닉네임',
            hintText: isWide ? '영화로운 닉네임을 입력하세요' : '닉네임을 입력해주세요',
            controller: _nicknameController,
            focusNode: _nicknameFocusNode,
            validator: _validateNickname,
            onChanged: (value) {
              _viewModel.onNicknameChanged(value);
              setState(() => _nicknameTouched = true);
            },
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            isCompact: isWide,
            isValid: _viewModel.nicknameCheckStatus == CheckStatus.available,
            externalErrorText: _viewModel.nicknameErrorText,
            showError: _nicknameTouched && !_isNicknameValid,
            inputFontWeight: _nicknameTouched && _isNicknameValid
                ? FontWeight.w500
                : FontWeight.w400,
            hintFontWeight: isWide ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
        SizedBox(height: isWide ? 4 : 16),
        _withCheckButton(
          isWide: isWide,
          nickname: false,
          child: MovieLogTextFormField(
            label: isWide ? '이메일 주소' : '이메일',
            hintText: isWide ? 'example@movielog.com' : '이메일 주소를 입력해주세요',
            controller: _emailController,
            focusNode: _emailFocusNode,
            validator: _validateEmail,
            onChanged: (value) {
              _viewModel.onEmailChanged(value);
              setState(() => _emailTouched = true);
            },
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            isCompact: isWide,
            isValid: _viewModel.emailCheckStatus == CheckStatus.available,
            externalErrorText: _viewModel.emailErrorText,
            showError: _emailTouched && !_isEmailValid,
            hintFontWeight: isWide ? FontWeight.w400 : FontWeight.w500,
          ),
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
        MovieLogButton(
          label: '가입하기',
          width: double.infinity,
          height: 56,
          onPressed: canSubmit ? onSubmit : null,
        ),
        const SizedBox(height: 8),
        const Text(
          '학습용 화면으로 실제 계정은 생성되지 않습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
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
