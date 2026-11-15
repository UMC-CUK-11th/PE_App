import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/member_api_service.dart';
import '../data/models/sign_up_models.dart';
import '../data/services/learning_member_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_log_text_form_field.dart';
import '../view_models/sign_up_view_model.dart';

enum AvailabilityState { idle, loading, available, duplicate, networkError }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.apiService, this.session, super.key});

  final MemberApiService? apiService;
  final LearningMemberSession? session;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _nicknameFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _duplicateNicknames = <String>{};
  final _duplicateEmails = <String>{};

  late final MemberApiService _apiService;
  late final SignUpViewModel _viewModel;
  AvailabilityState _nicknameState = AvailabilityState.idle;
  AvailabilityState _emailState = AvailabilityState.idle;
  bool _nicknameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  int _nicknameRequestId = 0;
  int _emailRequestId = 0;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? MemberApiService.fromEnvironment();
    _viewModel = SignUpViewModel(
      service: _apiService,
      session: widget.session ?? LearningMemberSession(),
    )..addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    super.dispose();
  }

  String? _validateNicknameFormat(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해주세요.';
    if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    if (nickname.length > 12) return '닉네임은 12자 이하여야 합니다.';
    return null;
  }

  String? _validateEmailFormat(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해주세요.';
    if (email.length > 254) return '이메일은 254자 이하여야 합니다.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  String? _validateNickname(String? value) {
    final formatError = _validateNicknameFormat(value);
    if (formatError != null) return formatError;
    return switch (_nicknameState) {
      AvailabilityState.duplicate => '이미 사용 중인 닉네임입니다.',
      AvailabilityState.networkError => '닉네임 중복 확인에 실패했습니다. 다시 시도해주세요.',
      _ => null,
    };
  }

  String? _validateEmail(String? value) {
    final formatError = _validateEmailFormat(value);
    if (formatError != null) return formatError;
    return switch (_emailState) {
      AvailabilityState.duplicate => '이미 사용 중인 이메일입니다.',
      AvailabilityState.networkError => '이메일 중복 확인에 실패했습니다. 다시 시도해주세요.',
      _ => null,
    };
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    if (!RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
      return '비밀번호는 대·소문자, 숫자, 특수문자를 포함해야 합니다.';
    }
    return _viewModel.passwordErrorText;
  }

  bool get _isNicknameFormatValid =>
      _validateNicknameFormat(_nicknameController.text) == null;
  bool get _isEmailFormatValid =>
      _validateEmailFormat(_emailController.text) == null;
  bool get _isPasswordValid =>
      _validatePassword(_passwordController.text) == null;
  bool get _canSubmit =>
      _nicknameState == AvailabilityState.available &&
      _emailState == AvailabilityState.available &&
      _isPasswordValid &&
      _agreedToTerms;

  void _onNicknameChanged(String value) {
    final nickname = value.trim();
    setState(() {
      _nicknameRequestId++;
      _nicknameTouched = true;
      _nicknameState = _duplicateNicknames.contains(nickname)
          ? AvailabilityState.duplicate
          : AvailabilityState.idle;
    });
    _viewModel.clearServerErrors();
    _nicknameFieldKey.currentState?.validate();
  }

  void _onEmailChanged(String value) {
    final email = value.trim().toLowerCase();
    setState(() {
      _emailRequestId++;
      _emailTouched = true;
      _emailState = _duplicateEmails.contains(email)
          ? AvailabilityState.duplicate
          : AvailabilityState.idle;
    });
    _viewModel.clearServerErrors();
    _emailFieldKey.currentState?.validate();
  }

  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (_validateNicknameFormat(nickname) != null) {
      setState(() => _nicknameTouched = true);
      _nicknameFieldKey.currentState?.validate();
      return;
    }
    final requestId = ++_nicknameRequestId;
    setState(() => _nicknameState = AvailabilityState.loading);
    try {
      final available = await _apiService.isNicknameAvailable(nickname);
      if (!mounted ||
          requestId != _nicknameRequestId ||
          _nicknameController.text.trim() != nickname) {
        return;
      }
      setState(() {
        _nicknameState = available
            ? AvailabilityState.available
            : AvailabilityState.duplicate;
        if (!available) _duplicateNicknames.add(nickname);
      });
    } on Object {
      if (!mounted ||
          requestId != _nicknameRequestId ||
          _nicknameController.text.trim() != nickname) {
        return;
      }
      setState(() => _nicknameState = AvailabilityState.networkError);
    }
    _nicknameFieldKey.currentState?.validate();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (_validateEmailFormat(email) != null) {
      setState(() => _emailTouched = true);
      _emailFieldKey.currentState?.validate();
      return;
    }
    final requestId = ++_emailRequestId;
    setState(() => _emailState = AvailabilityState.loading);
    try {
      final available = await _apiService.isEmailAvailable(email);
      if (!mounted ||
          requestId != _emailRequestId ||
          _emailController.text.trim().toLowerCase() != email) {
        return;
      }
      setState(() {
        _emailState = available
            ? AvailabilityState.available
            : AvailabilityState.duplicate;
        if (!available) _duplicateEmails.add(email);
      });
    } on Object {
      if (!mounted ||
          requestId != _emailRequestId ||
          _emailController.text.trim().toLowerCase() != email) {
        return;
      }
      setState(() => _emailState = AvailabilityState.networkError);
    }
    _emailFieldKey.currentState?.validate();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_canSubmit) return;
    FocusScope.of(context).unfocus();
    await _viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    if (!mounted) return;
    _passwordFieldValidate();
    if (_viewModel.submitStatus == SubmitStatus.success &&
        _viewModel.createdMemberId != null) {
      context.go('/movies');
      return;
    }
    final message = _viewModel.snackbarMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _passwordFieldValidate() => _formKey.currentState?.validate();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_viewModel.isSubmitting,
      child: Scaffold(
        appBar: CommonAppBar(
          title: '회원가입',
          centerTitle: true,
          titleStyle: AppTextStyles.signUpAppBarTitle.copyWith(fontSize: 20),
          onBack: () {
            if (_viewModel.isSubmitting) return;
            context.canPop() ? context.pop() : context.go('/start');
          },
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 560,
                    minHeight: (constraints.maxHeight - 48).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '환영합니다!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '간단한 정보만 입력하고 시작해보세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 34),
                          _AvailabilityField(
                            label: '닉네임',
                            hintText: '닉네임을 입력해주세요',
                            controller: _nicknameController,
                            formFieldKey: _nicknameFieldKey,
                            focusNode: _nicknameFocusNode,
                            validator: _validateNickname,
                            onChanged: _onNicknameChanged,
                            onFieldSubmitted: (_) =>
                                _emailFocusNode.requestFocus(),
                            keyboardType: TextInputType.name,
                            touched: _nicknameTouched,
                            formatValid: _isNicknameFormatValid,
                            state: _nicknameState,
                            availableMessage: '사용 가능한 닉네임입니다.',
                            loadingMessage: '닉네임 사용 가능 여부를 확인 중입니다.',
                            onCheck: _checkNickname,
                          ),
                          const SizedBox(height: 16),
                          _AvailabilityField(
                            label: '이메일',
                            hintText: '이메일 주소를 입력해주세요',
                            controller: _emailController,
                            formFieldKey: _emailFieldKey,
                            focusNode: _emailFocusNode,
                            validator: _validateEmail,
                            onChanged: _onEmailChanged,
                            onFieldSubmitted: (_) =>
                                _passwordFocusNode.requestFocus(),
                            keyboardType: TextInputType.emailAddress,
                            touched: _emailTouched,
                            formatValid: _isEmailFormatValid,
                            state: _emailState,
                            availableMessage: '사용 가능한 이메일입니다.',
                            loadingMessage: '이메일 사용 가능 여부를 확인 중입니다.',
                            onCheck: _checkEmail,
                          ),
                          const SizedBox(height: 16),
                          MovieLogTextFormField(
                            label: '비밀번호',
                            hintText: '대·소문자, 숫자, 특수문자 포함 8자 이상',
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            validator: _validatePassword,
                            onChanged: (_) {
                              _viewModel.clearServerErrors();
                              setState(() => _passwordTouched = true);
                            },
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).unfocus(),
                            isValid: _passwordTouched && _isPasswordValid,
                            showError: _passwordTouched && !_isPasswordValid,
                            obscureText: _obscurePassword,
                            onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              SizedBox.square(
                                dimension: 26,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (value) => setState(
                                    () => _agreedToTerms = value ?? false,
                                  ),
                                  checkColor: AppColors.white,
                                  fillColor: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.selected)
                                        ? AppColors.violet
                                        : AppColors.white,
                                  ),
                                  side: const BorderSide(color: AppColors.gray),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '필수 약관에 동의합니다',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            key: const ValueKey('sign-up-button'),
                            label: '가입하기',
                            isLoading: _viewModel.isSubmitting,
                            onPressed: _canSubmit && !_viewModel.isSubmitting
                                ? _submit
                                : null,
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '이미 계정이 있나요?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.violet,
                                  padding: const EdgeInsets.only(left: 4),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('로그인'),
                              ),
                            ],
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
      ),
    );
  }
}

class _AvailabilityField extends StatelessWidget {
  const _AvailabilityField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.formFieldKey,
    required this.focusNode,
    required this.validator,
    required this.onChanged,
    required this.onFieldSubmitted,
    required this.keyboardType,
    required this.touched,
    required this.formatValid,
    required this.state,
    required this.availableMessage,
    required this.loadingMessage,
    required this.onCheck,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final Key formFieldKey;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onFieldSubmitted;
  final TextInputType keyboardType;
  final bool touched;
  final bool formatValid;
  final AvailabilityState state;
  final String availableMessage;
  final String loadingMessage;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final hasStateError =
        state == AvailabilityState.duplicate ||
        state == AvailabilityState.networkError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.fieldLabelCompact.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MovieLogTextFormField(
                label: label,
                formFieldKey: formFieldKey,
                showLabel: false,
                hintText: hintText,
                controller: controller,
                focusNode: focusNode,
                validator: validator,
                onChanged: onChanged,
                onFieldSubmitted: onFieldSubmitted,
                textInputAction: TextInputAction.next,
                keyboardType: keyboardType,
                isValid: state == AvailabilityState.available,
                showError: touched && (!formatValid || hasStateError),
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 102,
              child: AppButton(
                key: ValueKey('$label-check-button'),
                label: '중복 확인',
                isLoading: state == AvailabilityState.loading,
                onPressed: formatValid ? onCheck : null,
              ),
            ),
          ],
        ),
        if (state == AvailabilityState.available ||
            state == AvailabilityState.loading)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state == AvailabilityState.available
                  ? availableMessage
                  : loadingMessage,
              style: TextStyle(
                color: state == AvailabilityState.available
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1565C0),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
