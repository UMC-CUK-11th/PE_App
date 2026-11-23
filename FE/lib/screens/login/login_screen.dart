import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/auth_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movielog_button.dart';

/// 로그인 화면. login()만 호출하고 이동은 Router가 status를 보고 결정합니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// Challenge: 이메일만 비민감 저장소에 둡니다. 비밀번호·토큰은 저장하지 않습니다.
  static const savedEmailKey = 'movielog.saved_email';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  // 실제로 읽거나 쓸 때 만들어 Plugin이 없는 환경에서도 화면이 뜨게 합니다.
  late final _preferences = SharedPreferencesAsync();
  late final AuthViewModel _auth;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_showSessionExpired);
    // 이미 만료된 상태로 화면이 처음 열리는 경우도 처리합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
    _restoreEmail();
  }

  Future<void> _restoreEmail() async {
    try {
      final saved = await _preferences.getString(LoginScreen.savedEmailKey);
      if (!mounted || saved == null) return;
      setState(() {
        _rememberEmail = true;
        _email.text = saved;
      });
    } catch (_) {
      // 저장된 이메일을 못 읽어도 로그인은 할 수 있어야 합니다.
    }
  }

  Future<void> _persistEmail() async {
    try {
      if (_rememberEmail) {
        await _preferences.setString(
          LoginScreen.savedEmailKey,
          _email.text.trim(),
        );
      } else {
        await _preferences.remove(LoginScreen.savedEmailKey);
      }
    } catch (_) {
      // 편의 기능이라 실패해도 로그인 흐름을 막지 않습니다.
    }
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 먼저 꺼서 같은 Snackbar가 반복되지 않게 합니다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    _persistEmail();
    _auth.login(_email.text.trim(), _password.text);
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;
    final message = auth.message;

    return Scaffold(
      appBar: const CommonAppBar(title: '로그인', centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                SvgPicture.asset(
                  'assets/logos/movielog_logo.svg',
                  width: 72,
                  height: 72,
                  semanticsLabel: 'MovieLog 로고',
                ),
                const SizedBox(height: 16),
                const Text(
                  'MovieLog에 로그인',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _email,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: '이메일'),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  enabled: enabled,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => enabled ? _submit() : null,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _rememberEmail,
                  onChanged: enabled
                      ? (value) =>
                            setState(() => _rememberEmail = value ?? false)
                      : null,
                  title: const Text('이메일 저장', style: AppTextStyles.bodyMedium),
                  activeColor: AppColors.violet,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  height: 52,
                  isLoading: loading, // 통신 중에는 비활성화합니다.
                  onPressed: enabled ? _submit : null,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: enabled ? () => context.push('/register') : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.violet,
                  ),
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
