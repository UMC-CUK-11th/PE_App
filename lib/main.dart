import 'package:flutter/material.dart';
import 'app_theme.dart'; // AppTheme 임포트 확인

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieLog Sign Up',
      debugShowCheckedModeBanner: false,
      // CodeRabbit 리뷰 반영: 인라인 테마 대신 AppTheme.lightTheme 적용
      theme: AppTheme.lightTheme,
      home: const SignUpScreen(),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller와 FocusNode는 build 바깥에서 생성하여 커서/포커스 초기화 방지
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isTermsAgreed = false;
  bool _isPasswordVisible = false;
  bool _isButtonEnabled = false;

  // CodeRabbit 리뷰 반영: 이메일 정규식 상수화 및 TLD 길이 제한 완화
  static final RegExp _emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_checkFormValidity);
    _emailController.addListener(_checkFormValidity);
    _passwordController.addListener(_checkFormValidity);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _checkFormValidity() {
    final isNicknameValid = _nicknameController.text.trim().length >= 2;
    final isEmailValid = _emailRegExp.hasMatch(_emailController.text.trim());
    
    // CodeRabbit 리뷰 반영: 비밀번호 검증 조건에 영문, 숫자 포함 여부 추가
    final passwordText = _passwordController.text;
    final hasLetter = passwordText.contains(RegExp(r'[A-Za-z]'));
    final hasDigit = passwordText.contains(RegExp(r'[0-9]'));
    final isPasswordValid = passwordText.length >= 8 && hasLetter && hasDigit;

    final isAllValid =
        isNicknameValid && isEmailValid && isPasswordValid && _isTermsAgreed;

    if (_isButtonEnabled != isAllValid) {
      setState(() {
        _isButtonEnabled = isAllValid;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _isTermsAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget formContent = Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A3E73),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'MovieLog에 오신 것을 환영합니다!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 닉네임 입력창
                  MovieLogTextFormField(
                    controller: _nicknameController,
                    label: '닉네임',
                    hint: '영화로운 닉네임을 입력하세요',
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_emailFocusNode),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '닉네임을 입력해주세요.';
                      }
                      if (value.trim().length < 2) {
                        return '닉네임은 2글자 이상이어야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 이메일 입력창
                  MovieLogTextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    label: '이메일 주소',
                    hint: 'example@movielog.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocusNode),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '이메일을 입력해주세요.';
                      }
                      if (!_emailRegExp.hasMatch(value.trim())) {
                        return '올바른 이메일 형식이 아닙니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력창
                  MovieLogTextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    label: '비밀번호',
                    hint: '영문, 숫자 포함 8자 이상',
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (_isButtonEnabled) _submitForm();
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요.';
                      }
                      if (value.length < 8) {
                        return '비밀번호는 8자 이상이어야 합니다.';
                      }
                      if (!value.contains(RegExp(r'[A-Za-z]')) ||
                          !value.contains(RegExp(r'[0-9]'))) {
                        return '영문과 숫자를 모두 포함해야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 필수 약관 동의 체크박스
                  TermsAgreementCheckbox(
                    isAgreed: _isTermsAgreed,
                    onChanged: (value) {
                      setState(() {
                        _isTermsAgreed = value ?? false;
                      });
                      _checkFormValidity();
                    },
                  ),
                  const SizedBox(height: 24),

                  // 가입하기 버튼
                  SignUpSubmitButton(
                    isEnabled: _isButtonEnabled,
                    onPressed: _submitForm,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '이미 계정이 있나요? ',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          '로그인',
                          style: TextStyle(
                            color: Color(0xFF6750A4),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            if (constraints.maxWidth >= 700) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: formContent,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: formContent,
            );
          },
        ),
      ),
    );
  }
}

// ----------------- 공통 위젯 분리 -----------------

class MovieLogTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const MovieLogTextFormField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6750A4), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class TermsAgreementCheckbox extends StatelessWidget {
  final bool isAgreed;
  final ValueChanged<bool?> onChanged;

  const TermsAgreementCheckbox({
    super.key,
    required this.isAgreed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isAgreed),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isAgreed,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '필수 약관에 동의합니다',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class SignUpSubmitButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const SignUpSubmitButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFF6750A4),
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: 0,
        ),
        child: const Text(
          '가입하기',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}