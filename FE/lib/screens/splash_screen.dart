import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_session.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/logos/movielog_logo.svg', width: 64),
              const SizedBox(height: 16),
              Text(
                'MovieLog',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              if (session.status == AuthStatus.restoreError) ...[
                const Text('로그인 상태를 확인하지 못했습니다.'),
                TextButton(
                  onPressed: session.restore,
                  child: const Text('다시 시도'),
                ),
              ] else
                const CircularProgressIndicator(semanticsLabel: '로그인 상태 확인 중'),
            ],
          ),
        ),
      ),
    );
  }
}
