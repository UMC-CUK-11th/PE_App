import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final hasError = auth.message != null;
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCF9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 26),
                const Text(
                  'FLUTTER 8주차',
                  style: TextStyle(
                    color: Color(0xFF655F6C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 82),
                SvgPicture.asset(
                  'assets/logos/movielog_logo.svg',
                  width: 60,
                  height: 49,
                  semanticsLabel: 'MovieLog 로고',
                ),
                const SizedBox(height: 50),
                const Text(
                  '영화의 순간을\n기록하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF25232A),
                    fontSize: 26,
                    height: 34 / 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF655F6C),
                    fontSize: 14,
                    height: 24 / 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (hasError) ...[
                  const Text(
                    '세션을 확인하지 못했어요.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 218,
                    height: 44,
                    child: FilledButton(
                      onPressed: auth.restoreSession,
                      child: const Text('다시 시도'),
                    ),
                  ),
                ] else
                  const CircularProgressIndicator(color: AppColors.violet),
                const SizedBox(height: 72),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
