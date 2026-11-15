import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.violet,
        disabledBackgroundColor: AppColors.gray,
        foregroundColor: AppColors.white,
        disabledForegroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? Semantics(
              label: '$label 확인 중',
              child: const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
            )
          : Text(label),
    ),
  );
}
