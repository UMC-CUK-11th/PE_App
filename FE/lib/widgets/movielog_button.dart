import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 화면에 상관없이 쓰는 공용 버튼. 상태는 표시만 하고 스스로 바꾸지 않습니다.
/// - 기본: onPressed가 있고 isLoading이 false
/// - 통신 중: isLoading이 true면 눌리지 않고 가운데 인디케이터만 표시
/// - 비활성: onPressed가 null
/// width가 null이면 내용 크기, double.infinity면 부모 최대 너비, 숫자면 고정 너비입니다.
class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          disabledBackgroundColor: AppColors.gray,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // 통신 중에는 label과 인디케이터 중 하나만 그립니다.
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
