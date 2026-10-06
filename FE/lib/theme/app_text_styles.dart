import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const profileTitle = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.black,
  );

  static const signUpAppBarTitle = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.violet,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const bodyMedium = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.gray,
  );

  static const labelLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.violet,
  );

  static const genreLabel = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.onPrimaryContainer,
  );

  static const signUpTitle = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w500,
    color: AppColors.violet,
  );

  static const signUpSubtitle = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static const fieldLabel = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const fieldLabelCompact = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    color: AppColors.black,
  );

  static const inputText = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.inputText,
  );

  static const inputHint = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w500,
    color: AppColors.hintText,
  );

  static const inputTextCompact = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.inputText,
  );

  static const inputHintCompact = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.gray,
  );

  static const errorText = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  static const buttonLabel = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static const buttonLabelCompact = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.white,
  );
}
