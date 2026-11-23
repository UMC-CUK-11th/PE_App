import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';
import '../models/common_response.dart';
import '../view_models/auth_session.dart';
import '../view_models/signup_view_model.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _emailKey = 'movielog.rememberedEmail';
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _preferences = SharedPreferencesAsync();
  bool _remember = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<AuthSession>().takeExpiredNotice()) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
    });
  }

  Future<void> _restoreEmail() async {
    try {
      final saved = await _preferences.getString(_emailKey);
      if (!mounted || _email.text.isNotEmpty || saved == null) return;
      setState(() {
        _email.text = saved;
        _remember = true;
      });
    } catch (_) {
      // Email autofill is optional.
    }
  }

  Future<void> _submit(AuthSession session) async {
    if (session.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final email = _email.text.trim();
    final remember = _remember;
    try {
      await session.login(LoginRequest(email, _password.text));
      if (remember) {
        await _preferences.setString(_emailKey, email);
      } else {
        await _preferences.remove(_emailKey);
      }
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      // Preference failures should not change a successful login.
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'MovieLog',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('로그인'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        enabled: !session.busy,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: '이메일'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: SignUpViewModel.validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        enabled: !session.busy,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          suffixIcon: IconButton(
                            tooltip: _hidePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                            onPressed: session.busy
                                ? null
                                : () => setState(() {
                                    _hidePassword = !_hidePassword;
                                  }),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? '비밀번호를 입력해주세요.'
                            : null,
                        onFieldSubmitted: (_) => _submit(session),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('이메일 저장'),
                        value: _remember,
                        onChanged: session.busy
                            ? null
                            : (value) {
                                setState(() => _remember = value ?? false);
                              },
                      ),
                      if (_error case final error?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      MovieLogButton(
                        label: '로그인',
                        height: 52,
                        isLoading: session.busy,
                        onPressed: session.busy ? null : () => _submit(session),
                      ),
                      TextButton(
                        onPressed: session.busy
                            ? null
                            : () => context.go('/register'),
                        child: const Text('회원가입'),
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
