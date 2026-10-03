import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyMedium,
    );
  }
}

class TermsAgreement extends StatelessWidget {
  const TermsAgreement({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: AppColors.violet,
            onChanged: (checked) => onChanged(checked ?? false),
          ),
          const Text('필수 약관에 동의합니다', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class SignUpButton extends StatelessWidget {
  const SignUpButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.violetDisabled,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '가입하기',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}

class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '이미 계정이 있나요?',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.black),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: AppColors.violet),
          child: const Text('로그인'),
        ),
      ],
    );
  }
}
