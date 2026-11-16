import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/app_button.dart';
import '../widgets/movie_log_text_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _savedEmailKey = 'saved_login_email';
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _saveEmail = false;
  bool _obscurePassword = true;
  bool _expiredNoticeShown = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showExpiredNotice());
  }

  Future<void> _loadSavedEmail() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_savedEmailKey);
    if (!mounted || saved == null || saved.isEmpty) return;
    setState(() {
      _emailController.text = saved;
      _saveEmail = true;
    });
  }

  void _showExpiredNotice() {
    if (!mounted || _expiredNoticeShown) return;
    final auth = context.read<AuthViewModel>();
    if (!auth.sessionExpired) return;
    _expiredNoticeShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')));
    auth.consumeSessionExpired();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final success = await auth.login(
      email: email,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      final preferences = await SharedPreferences.getInstance();
      if (_saveEmail) {
        await preferences.setString(_savedEmailKey, email);
      } else {
        await preferences.remove(_savedEmailKey);
      }
      return;
    }
    _formKey.currentState?.validate();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showExpiredNotice());
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFCF9),
        title: const Text(
          '로그인',
          style: TextStyle(
            color: AppColors.violet,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '다시 만나서 반가워요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '로그인하고 나만의 영화 기록을 이어가세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF655F6C), fontSize: 14),
                ),
                const SizedBox(height: 52),
                MovieLogTextFormField(
                  label: '이메일',
                  hintText: '이메일 주소를 입력해주세요',
                  controller: _emailController,
                  enabled: !auth.isSigningIn,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return '이메일을 입력해주세요.';
                    if (!email.contains('@')) return '이메일 형식을 확인해주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                MovieLogTextFormField(
                  label: '비밀번호',
                  hintText: '비밀번호를 입력해주세요',
                  controller: _passwordController,
                  enabled: !auth.isSigningIn,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: auth.isSigningIn
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return '비밀번호를 입력해주세요.';
                    if (auth.message != null) return auth.message;
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _saveEmail,
                  onChanged: auth.isSigningIn
                      ? null
                      : (value) => setState(() => _saveEmail = value ?? false),
                  title: const Text('이메일 저장', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 34),
                AppButton(
                  label: '로그인',
                  isLoading: auth.isSigningIn,
                  onPressed: auth.isSigningIn ? null : _submit,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '아직 계정이 없나요?',
                      style: TextStyle(color: Color(0xFF655F6C)),
                    ),
                    TextButton(
                      onPressed: auth.isSigningIn
                          ? null
                          : () => context.push('/register'),
                      child: const Text('회원가입'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
